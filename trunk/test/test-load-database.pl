use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::DB::Authors;
use XAS::Darkpan::DB::Mirrors;
use XAS::Darkpan::DB::Packages;

my $schema = XAS::Model::Schema->opendb('darkpan');

printf("loading authors\n");
my $authors = XAS::Darkpan::DB::Authors->new(-schema => $schema);
$authors->load();

printf("loading mirrors\n");
my $mirrors = XAS::Darkpan::DB::Mirrors->new(-schema => $schema);
$mirrors->load();

printf("loading packages\n");
my $packages = XAS::Darkpan::DB::Packages->new(-schema => $schema);
$packages->load();

