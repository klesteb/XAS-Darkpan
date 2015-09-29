
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Lib::Modules::Locking;
use XAS::Darkpan::Process::Authors;

my $lockmgr = XAS::Lib::Modules::Locking->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $authors = XAS::Darkpan::Process::Authors->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
);

$authors->create();

