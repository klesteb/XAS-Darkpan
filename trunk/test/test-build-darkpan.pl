
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use strict;
use warnings;

use Badger::URL 'URL';
use Badger::Filesystem 'Dir';

use XAS::Model::Schema;
use XAS::Darkpan::Process;

my $root = Dir('/var/lib/xas/darkpan');
my $schema  = XAS::Model::Schema->opendb('darkpan');
my $process = XAS::Darkpan::Process->new(
    -schema => $schema, 
    -root   => $root,
    -mirror => URL('http://www.cpan.oeg')
);

#$process->log->level('debug', 1);

$process->create_authors();
$process->load_database();
$process->sync();

