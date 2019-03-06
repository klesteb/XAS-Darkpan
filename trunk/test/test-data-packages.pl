
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use XAS::Darkpan::Process::Packages;

my $lockmgr = XAS::Lib::Lockmgr->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $packages = XAS::Darkpan::Process::Packages->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
);

my @packages = $packages->data();

foreach my $package (@packages) {

    printf("%s\n", $package->to_string);

}

