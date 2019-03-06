use strict;
use warnings;

use PPI;
use Data::Dumper;

#my $dom = PPI::Document->new('ANN.pm', readonly => 1);
#my $dom = PPI::Document->new('DH.pm', readonly => 1);
#my $dom = PPI::Document->new('../lib/XAS/Darkpan/Process.pm', readonly => 1);
#my $dom = PPI::Document->new('Release.pm', readonly => 1);
#my $dom = PPI::Document->new('SocketTest.pm', readonly => 1);
my $dom = PPI::Document->new('Set.pm', readonly => 1);


my @tokens = $dom->tokens;

foreach my $token (@tokens) {
    
    printf("%s, %s\n", ref($token), $token->content);
    
}

