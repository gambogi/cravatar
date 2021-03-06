package cravatar;

use Dancer ':syntax';
use Dancer::Plugin::LDAP;
use Dancer::Plugin::Cache::CHI;
use MIME::Type;
use Net::LDAP::Util qw/escape_filter_value/;
use Try::Tiny;

our $VERSION = '0.5';

get '/' => sub {
    redirect '/upload';
};

get '/:UUID.jpg' => sub {
    my $uuid = param 'UUID';
    my $ret = cache_get $uuid;
    if (defined $ret) {
        return send_file \$ret, content_type => 'image/jpeg';
    }

    try {
        $ret = ldap->search(
            base => "ou=Users,dc=csh,dc=rit,dc=edu",
            filter => "entryUUID=".escape_filter_value($uuid),
            attrs => [ 'jpegPhoto' ],
            scope => 'one',
        )->shift_entry->get('jpegPhoto');
    } or status 404;

    # we get an array of jpegPhotos, so let's grab the first one
    my $photo = $ret->[0];
    cache_set $uuid, $photo;
    send_file(\$photo, content_type => 'image/jpeg');
};

get '/upload' => sub {
    my $user = request->header('X-WEBAUTH-USER');
    unless ($user) {
        return template 'error.tt', {
            message => 'Must log in with webauth',
        };
    }
    try {
        $entryUUID = ldap->search(
            base => "ou=Users,dc=csh,dc=rit,dc=edu",
            filter => "uid=".escap_filter_value($user),
            attrs => ['entryUUID'],
            scope => 'one',
        )->shift_entry->get('entryUUID');
    } or $entryUUID='error'

    return template 'upload.tt', {
        user => $user,
        entryUUID => $entryUUID
    };
};

post '/upload' => sub {
    my $ldap = ldap;
    my $user = request->header('X-WEBAUTH-USER') or
        return template 'error', {
            message => 'Must log in with webauth',
        };

    # Grab the photo from the request
    my $file = request->upload('photo') or
        return template 'error', {
            message => 'Must provide a photo'
        };

    # Check if the file is a jpeg
    if ($file->type ne "image/jpeg") {
        return template 'error', {
            message => 'Must provide a jpeg image'
        };
    }

    # Remove previous picture from cache
    my $uuid = ldap->search(
        base => "ou=Users,dc=csh,dc=rit,dc=edu",
        filter => "uid=$user",
        attrs => [ 'entryUUID' ],
        scope => 'one',
    )->shift_entry->get('entryUUID')->[0];
    cache_remove $uuid;

    # Make the change to LDAP
    my $ret = $ldap->modify("uid=$user,ou=Users,dc=csh,dc=rit,dc=edu",
        changes => [
            replace => [
                jpegPhoto => $file->content,
            ],
        ],
    );

    if ($ret->code) {
        warning $ret->error;
        return template 'error', {
            message => $ret->error,
        };
    }

    return template 'success', {
        message => 'Success!',
    };
};

true;
