use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;
use Data::Dumper;

use XAS::Darkpan::Parse::Perms;

sub dump {
    my $data = shift;

    printf("Author    : %s\n", $data->{'pauseid'});
    printf("Permission: %s\n", $data->{'perm'});
    printf("Module    : %s\n", $data->{'module'});
    printf("\n");
    
}

my $perms = XAS::Darkpan::Parse::Perms->new();

$perms->load();
$perms->parse(\&dump);

