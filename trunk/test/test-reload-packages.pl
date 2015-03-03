
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::DB::Packages;

my $schema = XAS::Model::Schema->opendb('darkpan');
my $packages = XAS::Darkpan::DB::Packages->new(
    -schema => $schema
);

$packages->reload();

