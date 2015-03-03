
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::DB::Mirrors;

my $schema = XAS::Model::Schema->opendb('darkpan');
my $mirrors = XAS::Darkpan::DB::Mirrors->new(
    -schema => $schema
);

$mirrors->load();

