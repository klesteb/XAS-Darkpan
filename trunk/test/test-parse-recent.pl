use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use Data::Dumper;
use XAS::Darkpan::Parse::Recent;

sub store {
    my $data = shift;

    printf("epoch: %s\n", $data->{'epoch'});
    printf("path : %s\n", $data->{'path'});
    printf("type : %s\n", $data->{'type'});

}

my $recent = XAS::Darkpan::Parse::Recent->new();

$recent->load();
$recent->parse(\&store);

