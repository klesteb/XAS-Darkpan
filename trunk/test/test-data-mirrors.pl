
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Lib::Modules::Locking;
use XAS::Darkpan::Process::Mirrors;

my $lockmgr = XAS::Lib::Modules::Locking->new();
my $schema = XAS::Model::Schema->opendb('darkpan');
my $mirrors = XAS::Darkpan::Process::Mirrors->new(
    -schema  => $schema,
    -lockmgr => $lockmgr,
);

printf("%s\n", $mirrors->data());

