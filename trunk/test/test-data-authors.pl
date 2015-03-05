
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::DB::Authors;

my $schema = XAS::Model::Schema->opendb('darkpan');
my $authors = XAS::Darkpan::DB::Authors->new(
    -schema => $schema
);

my @authors = $authors->data();

foreach my $author (@authors) {
    
    printf("%s\n", $author);
    
}
