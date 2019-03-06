
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use XAS::Darkpan::Process::Mirrors;

my $lockmgr = XAS::Lib::Lockmgr->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $mirrors = XAS::Darkpan::Process::Mirrors->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
);

$mirrors->clear();

