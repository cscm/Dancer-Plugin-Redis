use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Redis',
    AUTHOR              => q{Christophe Nowicki <cscm@csquad.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Redis.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/Redis.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 1.175,
        'Redis'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Redis-*' },
);
