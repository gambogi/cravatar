package cravatar;

use Dancer ':syntax';
use Dancer::Plugin::LDAP;
use Dancer::Plugin::Cache::CHI;
use MIME::Type;
use Net::LDAP::Util qw/escape_filter_value/;
use Try::Tiny;

our $VERSION = '0.5';

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
    cache_page send_file(\$photo, content_type => 'image/jpeg');
};

get '/upload' => sub {
    my $user = request->header('X-WEBAUTH-USER');
    return template 'upload.tt', {
        user => $user // "worr",
    };
};

post '/upload' => sub {
    my $ldap = ldap;
    my $user = request->header('X-WEBAUTH-USER') or
        return template 'error', {
            message => 'Must log in with webauth',
        };

    my $file = request->upload('photo') or
        return template 'error', {
            message => 'Must provide a photo'
        };

    if ($file->type ne "image/jpeg") {
        return template 'error', {
            message => 'Must provide a jpeg image'
        };
    }

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

    redirect '/upload/success';
};

get '/upload/success' => sub {
    return template 'success', {
        message => 'Success!',
    };
};

true;
