use lib '../lib';
use strict;
use warnings;

use XAS::Model::Schema;
use XAS::Darkpan::Process;
use Badger::Filesystem 'Dir';

my $root    = Dir('/', 'srv', 'dpan');
my $authors = Dir('/', 'srv', 'dpan', 'authors', 'id');
my $schema  = XAS::Model::Schema->opendb('darkpan');
my $process = XAS::Darkpan::Process->new(-schema => $schema);

$process->create_dirs(-root => $root);
$process->load_database();
$process->mirror($authors);

