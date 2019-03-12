package XAS::Darkpan::Process;

our $VERSION = '0.01';

use Badger::URL 'URL';
use Badger::Filesystem 'Dir';

use XAS::Lib::Lockmgr;
use XAS::Darkpan::Process::Authors;
use XAS::Darkpan::Process::Mirrors;
use XAS::Darkpan::Process::Modlist;
use XAS::Darkpan::Process::Packages;
use XAS::Darkpan::Process::Permissions;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'packages authors mirrors lockmgr permissions modlist',
  utils     => 'dotid',
  vars => {
    PARAMS => {
      -schema => 1,
      -root   => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/var/lib/xas/darkpan') },
      -mirror => { optional => 1, isa => 'Badger::URL', default => URL('http://www.cpan.org') },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create_authors {
    my $self = shift;

    $self->log->debug('entering create_authors()');

    my $root       = $self->root;
    my $authors    = Dir($root, 'authors');
    my $modules    = Dir($root, 'modules');
    my $authors_id = Dir($root, 'authors/id');

    my @dirs = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    unless ($root->exists) {
        
        $root->create;
        $root->chmod(02775);

    }
    
    unless ($authors->exists) {
        
        $authors->create;
        $authors->chmod(02775);
        
    }
    
    unless ($modules->exists) {
        
        $modules->create;
        $modules->chmod(02775);
        
    }

    unless ($authors_id->exists) {
        
        $authors_id->create;
        $authors_id->chmod(02775);
        
    }

    foreach my $dir (@dirs) {

        my $d = Dir($authors_id,  $dir);
        unless ($d->exists) {
            
            $d->create ;
            $d->chmod(02775);
            
        }

    }

    $self->log->debug('leaving create_authors()');

}

sub sync {
    my $self = shift;

    my $root = $self->root->path;
    my $auth_id = 'authors/id';
    my $destination = Dir($root, $auth_id);

    my $criteria = {
        mirror => $self->mirror->service
    };

    my $options = {
        order_by => 'package',
    };

    $self->log->debug('entering mirror()');

    if (my $rs = $self->packages->search(-criteria => $criteria, -options => $options)) {

        while (my $rec = $rs->next) {

            my $path = sprintf("%s/%s/%s", $rec->mirror, $auth_id, $rec->pathname);
            my $url  = Badger::URL->new($path);

            $self->packages->process(
                -url         => $url,
                -pauseid     => $rec->pauseid,
                -package_id  => $rec->id,
                -destination => $destination,
            );

        }

    }

    $self->log->debug('leaving mirror()');

}

sub load_database {
    my $self = shift;

    $self->log->debug('entering load_database()');

    $self->mirrors->load();
    $self->log->info('loaded mirrors');

    $self->authors->load();
    $self->log->info('loaded authors');

    $self->packages->load();
    $self->log->info('loaded packages');

    $self->log->debug('leaving load_database()');

}

sub load_authors {
    my $self = shift;
    
    $self->log->debug('entering load_authors()');

    $self->authors->load();
    $self->log->info('loaded authors');

    $self->log->debug('leaving load_authors()');

}

sub load_mirrors {
    my $self = shift;
    
    $self->log->debug('entering load_mirrors()');

    $self->mirrors->load();
    $self->log->info('loaded mirrors');

    $self->log->debug('leaving load_mirrors()');
    
}

sub load_packages {
    my $self = shift;
    
    $self->log->debug('entering load_packages()');

    $self->packages->load();
    $self->log->info('loaded packages');

    $self->log->debug('leaving load_packages()');
    
}

sub load_permissions {
    my $self = shift;
    
    $self->log->debug('entering load_permissions()');

    $self->permissions->load();
    $self->log->info('loaded perms');

    $self->log->debug('leaving load_permissions()');

}

sub clear_database {
    my $self = shift;

    $self->log->debug('entering clear_database()');

    $self->mirrors->clear();
    $self->log->info('cleared mirrors');

    $self->authors->clear();
    $self->log->info('cleared authors');

    $self->packages->clear();
    $self->log->info('cleared packages');

    $self->permissions->clear();
    $self->log->info('cleared permissions');

    $self->log->debug('leaving clear_database()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $root = $self->root->path;

    $self->{'lockmgr'} = XAS::Lib::Lockmgr->new();

    $self->{'authors'} = XAS::Darkpan::Process::Authors->new(
        -schema  => $self->schema,
        -lockmgr => $self->lockmgr,
        -path    => Dir($root, 'authors', 'id'),
        -mirror  => $self->mirror->copy()
    );

    $self->{'mirrors'} = XAS::Darkpan::Process::Mirrors->new(
        -schema  => $self->schema,
        -lockmgr => $self->lockmgr,
        -path    => Dir($root, 'modules'),
        -mirror  => $self->mirror->copy()
    );

    $self->{'modlist'} = XAS::Darkpan::Process::Modlist->new(
        -schema  => $self->schema,
        -lockmgr => $self->lockmgr,
        -path    => Dir($root, 'modules'),
        -mirror  => $self->mirror->copy()
    );

    $self->{'packages'} = XAS::Darkpan::Process::Packages->new(
        -schema  => $self->schema,
        -lockmgr => $self->lockmgr,
        -path    => Dir($root, 'authors', 'id'),
        -mirror  => $self->mirror->copy()
    );

    $self->{'permissions'} = XAS::Darkpan::Process::Permissions->new(
        -schema  => $self->schema,
        -lockmgr => $self->lockmgr,
        -path    => Dir($root, 'modules'),
        -mirror  => $self->mirror->copy()
    );

    return $self;

}

1;

__END__

=head1 NAME

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
