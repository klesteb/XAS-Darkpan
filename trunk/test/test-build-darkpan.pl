
use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::Process;

my $schema  = XAS::Model::Schema->opendb('darkpan');
my $process = XAS::Darkpan::Process->new(-schema => $schema);

$process->log->level('debug', 1);

$process->create();
$process->load_database();
$process->mirror();

