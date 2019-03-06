use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use XAS::Darkpan::Parse::Packages;

my $packages = XAS::Darkpan::Parse::Packages->new();

$packages->load();
$packages->parse(sub {
    my $package = shift;

    printf("name:    %s\n", $package->{'name'});
    printf("version: %s\n", $package->{'version'});
    printf("path:    %s\n", $package->{'path'});

});

