
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use Badger::URL 'URL';
use Badger::Filesystem 'Dir';

use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use XAS::Darkpan::Process::Mirrors;

my $lockmgr = XAS::Lib::Lockmgr->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $mirrors = XAS::Darkpan::Process::Mirrors->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
);

$mirrors->log->level('debug', 1);

$mirrors->inject(
    -url  => URL('http://www.cpan.org'),
    -type => 'master'
);

$mirrors->inject(
    -url  => URL('http://localhost'),
    -type => 'mirror'
);

