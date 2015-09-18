use lib '../lib';
use strict;
use warnings;

use Badger::URL;
use XAS::Model::Schema;
use XAS::Darkpan::Process;
use Badger::Filesystem 'Dir';

my $schema = XAS::Model::Schema->opendb('darkpan');
my $process = XAS::Darkpan::Process->new(
    -schema => $schema,
    -xdebug => 1,
);

$process->create_dirs();
$process->load_database():
$process->mirror( Dir('/srv/dpan/authors/id') );

