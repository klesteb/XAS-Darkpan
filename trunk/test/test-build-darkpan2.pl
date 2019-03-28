
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::Process;
use Badger::Filesystem 'Dir';

my $root = Dir('/var/lib/xas/darkpan');
my $schema  = XAS::Model::Schema->opendb('darkpan');
my $process = XAS::Darkpan::Process->new(-schema => $schema, -root => $root);

#$process->log->level('debug', 1);

$process->create_directories();
$process->load_database();

