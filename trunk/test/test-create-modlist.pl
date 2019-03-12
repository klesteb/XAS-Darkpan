
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use Badger::URL 'URL';
use Badger::Filesystem 'Dir';

use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use XAS::Darkpan::Process::Modlist;

my $lockmgr = XAS::Lib::Lockmgr->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $modlist = XAS::Darkpan::Process::Modlist->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
    -path    => Dir('/var/lib/xas/darkpan/modules'),
    -mirror  => URL('http://localhost')
);

$modlist->create();

