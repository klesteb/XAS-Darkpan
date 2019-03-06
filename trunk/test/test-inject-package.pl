
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';
use lib '/home/kevin/dev/XAS-Model/trunk/lib';

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
);

my $distribution = 'DDC-0.01.tar.gz';
my $authors = '/var/lib/xas/darkpan/authors/id';

$packages->log->level('debug', 1);

my $rec = $packages->inject(
    -pause_id => 'KESTEB',
    -source   => Dir($authors),
    -package  => $distribution,
    -mirror   => URL('http://localhost')
);

$packages->process(
    -pause_id    => 'KESTEB',
    -package_id  => $rec->id,
    -destination => Dir($authors),
    -url         => URL('file:///home/kevin/dev/released/DDC/DDC-0.01.tar.gz'),
);

