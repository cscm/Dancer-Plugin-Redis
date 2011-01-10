#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Redis' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Redis $Dancer::Plugin::Redis::VERSION, Perl $], $^X" );
