use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'cravatar',
    AUTHOR              => q{William Orr <worr@csh.rit.edu>},
    VERSION_FROM        => 'lib/cravatar.pm',
    ABSTRACT            => 'Simple avatar webapp for CSH',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'MIT')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'CHI::Driver::Memcached::libmemcached'      => 0,
        'Dancer'                                    => 1.3095,
        'Dancer::Plugin::Cache::CHI'                => 0,
        'Dancer::Plugin::LDAP'                      => 0,
        'HTML::Entities'                            => 0,
        'Memcached::libmemcached'                   => 0,
        'Net::LDAP'                                 => 0,
        'Template'                                  => 0,
        'Test::More'                                => 0,
        'Try::Tiny'                                 => 0,
        'YAML'                                      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'cravatar-*' },
);
