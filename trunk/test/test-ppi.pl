use strict;
use warnings;

use PPI;
use Data::Dumper;

my $dom = PPI::Document->new('DH.pm');

foreach my $element ($dom->elements) {
    
    printf("element: %s, content: %s\n", ref($element), $element->content);
    
}


