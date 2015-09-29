
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Lib::Modules::Locking;
use XAS::Darkpan::Process::Packages;

my $lockmgr = XAS::Lib::Modules::Locking->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $packages = XAS::Darkpan::Process::Packages->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
);

$packages->clear();

