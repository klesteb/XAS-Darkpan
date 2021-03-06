
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use Badger::URL 'URL';
use Badger::Filesystem 'Dir';

use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use XAS::Darkpan::Process::Packages;

my $lockmgr = XAS::Lib::Lockmgr->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $packages = XAS::Darkpan::Process::Packages->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
    -mirror  => URL('http://localhost:8080'),
    -path    => Dir('/var/lib/xas/darkpan/modules')
);

$packages->create();

