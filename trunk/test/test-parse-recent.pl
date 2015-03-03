use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use XAS::Darkpan::Parse::Recent;

sub store {
    my $data = shift;
    
    warn Dumper($data);
    
}

my $recent = XAS::Darkpan::Parse::Recent->new();

$recent->parse(\&store);

