
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';
use lib '/home/kevin/dev/XAS-Model/trunk/lib';

use strict;
use warnings;

use Badger::URL 'URL';
use XAS::Model::Schema;
use XAS::Darkpan::Process;
use Badger::Filesystem 'Dir';

my $distribution = 'DDC-0.01.tar.gz';
my $root = Dir('/var/lib/xas/darkpan');
my $schema  = XAS::Model::Schema->opendb('darkpan');
my $process = XAS::Darkpan::Process->new(
    -root   => $root,
    -schema => $schema, 
    -mirror => URL('http://www.cpan.org')
);


#$process->log->level('debug', 1);

$process->create_authors();

$process->mirrors->inject(
    -url  => URL('http://www.cpan.org'),
    -type => 'master'
);

$process->mirrors->inject(
    -url  => URL('http://localhost:8080'),
    -type => 'mirror'
);

$process->authors->inject(
    -pause_id => 'KESTEB',
    -name     => 'Kevin L. Esteb',
    -email    => 'kevin@kesteb.us',
    -mirror   => URL('http://localhost:8080')
);

my $rec = $process->packages->inject(
    -pause_id => 'KESTEB',
    -package  => $distribution,
    -mirror   => URL('http://localhost:8080'),
    -source   => Dir($root, 'authors', 'id'),
);

$process->packages->process(
    -pause_id    => 'KESTEB',
    -package_id  => $rec->id,
    -destination => Dir($root, 'authors', 'id'),
    -url         => URL('file:///home/kevin/dev/released/DDC/DDC-0.01.tar.gz'),
);

my $providers = $process->packages->data(
    -criteria => { pauseid => 'KESTEB', dist => 'DDC' },
    -options  => { order_by => 'package' }
);

foreach my $provider (@$providers) {
    
    $process->permissions->inject(
        -pause_id => 'KESTEB',
        -module  => $provider->name,
        -perms   => 'f',
        -mirror  => URL('http://localhost:8080')
    );

}

$process->authors->create();
$process->packages->create();
$process->mirrors->create();
$process->modlist->create();

