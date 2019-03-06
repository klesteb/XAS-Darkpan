
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
);

$authors->log->level('debug', 1);

my $rec = $authors->inject(
    -pause_id => 'kesteb',
    -name     => 'Kevin L. Esteb',
    -email    => 'kevin@kesteb.us',
    -mirror   => URL('http://localhost')
);

