package cravatar;

use Dancer ':syntax';
use Dancer::Plugin::LDAP;
use Dancer::Plugin::Cache::CHI;
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

true;
