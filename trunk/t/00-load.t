#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XAS::Spooler' ) || print "Bail out!\n";
}

diag( "Testing XAS::Spooler $XAS::Spooler::VERSION, Perl $], $^X" );
