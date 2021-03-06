use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use XAS::Darkpan::Parse::Authors;

my $authors = XAS::Darkpan::Parse::Authors->new();

$authors->load();
$authors->parse(sub {
    my $author = shift;

    printf("name:   %s\n", $author->{'name'});
    printf("cpanid: %s\n", $author->{'pauseid'});
    printf("email:  %s\n", $author->{'email'});

});

