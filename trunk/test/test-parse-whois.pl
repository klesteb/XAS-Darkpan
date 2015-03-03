use lib '../lib';
use strict;
use warnings;
use Data::Dumper;

use XAS::Darkpan::Parse::Whois;

sub whois {
    my $data = shift;

    warn Dumper($data);

}

my $whois = XAS::Darkpan::Parse::Whois->new();

$whois->parse(\&whois);

