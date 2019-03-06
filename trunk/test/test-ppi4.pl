use strict;
use warnings;

use PPI;
use PPI::Dumper;

my $dom = PPI::Document->new('Set.pm', readonly => 1);
my $dumper = PPI::Dumper->new($dom);

$dumper->print;



