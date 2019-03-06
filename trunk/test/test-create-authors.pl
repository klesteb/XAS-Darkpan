
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use Badger::URL 'URL';
use Badger::Filesystem 'Dir';

use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use XAS::Darkpan::Process::Authors;

my $lockmgr = XAS::Lib::Lockmgr->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $authors = XAS::Darkpan::Process::Authors->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
    -path    => Dir('/var/lib/xas/darkpan/modules'),
    -mirror  => URL('http://localhost')
);

$authors->create();

