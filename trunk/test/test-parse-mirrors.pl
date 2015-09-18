use lib '../lib';

use strict;
use warnings;

use Data::Dumper;
use XAS::Darkpan::Parse::Mirrors;

my $mirrors = XAS::Darkpan::Parse::Mirrors->new();

$mirrors->parse(sub {
    my $data = shift;

    printf("mirror: %s\n", $data->{'mirror'});
    printf("type  : %s\n", $data->{'type'});

});

