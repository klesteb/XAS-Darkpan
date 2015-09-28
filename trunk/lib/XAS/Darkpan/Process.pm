package XAS::Darkpan::Process;

our $VERSION = '0.01';

use XAS::Darkpan::DB::Mirrors;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Base',
  accessors => 'packages authors mirrors lockmgr',
  utils     => 'dotid left mid',
  vars => {
    PARAMS => {
      -schema          => 1,
      -root_path       => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan') },
      -modules_path    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/modules') },
      -authors_id_path => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors/id') },
      -mirror_url      => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org') },
    }
  }
;

use PPI::Dumper;
use Data::Dumper;


# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create_dirs {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -root    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->root_path },
        -authors => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->authors_path },
        -modules => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->modules_path },
        -auth_id => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->authors_id_path },
    });

    $self->log->debug('entering create_dirs()');

    my $root       = $p->{'root'};
    my $authors    = $p->{'authors'};
    my $modules    = $p->{'modules'};
    my $authors_id = $p->{'auth_id'};

    my @dirs = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    $root->create       unless ($root->exists);
    $authors->create    unless ($authors->exists);
    $modules->create    unless ($modules->exists);
    $authors_id->create unless ($authors_id->exists);

    foreach my $dir (@dirs) {

        my $d = Dir($authors_id,  $dir);
        $d->create unless ($d->exists);

    }

    $self->log->debug('leaving create_dirs()');

}

sub create_modlist {
    my $self = shift;

    my $fh;
    my $dt = DateTime->now(time_zone => 'GMT');
    my $date = $dt->strftime('%a %b %d %H:%M:%S %Y %Z');
    my $file = File($self->modules_path, '03modlist..gz');

    $self->log->debug('entering create_modlist()');

    unless ($fh = $file->open('w')) {

        $self->throw_msg(
            dotid($self->class) . '.create_packages.nocreate',
            'nocreate',
            $file->path
        );

    }

    $fh->print (<<__MODLIST);
File:        03modlist.data
Description: This was once the "registered module list" but has been retired.
        No replacement is planned.
Modcount:    0
Written-By:  XAS Darkpan $XAS::Darkpan::VERSION
Date:        $date

package CPAN::Modulelist;
sub data {
return {};
}
1;
__MODLIST

    $fh->close();

    $self->log->debug('leaving create_modlist()');

}

sub mirror {
    my $self = shift;
    my ($destination) = $self->validate_params(\@_, [
       { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $auth_id = 'authors/id';
    my $options = {
        order_by => 'package',
    };

    $self->log->debug('entering mirror()');

    if (my $rs = $self->packages->search(-options => $options)) {

        while (my $rec = $rs->next) {

            my $path = sprintf("%s/%s/%s", $rec->mirror, $auth_id, $rec->pathname);
            my $url  = Badger::URL->new($path);

            $self->inject(
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

    $self->authors->load();
    $self->log->info('loaded authors');

    $self->mirrors->load();
    $self->log->info('loaded mirrors');

    $self->packages->load();
    $self->log->info('loaded packages');

    $self->log->debug('leaving load_database()');

}

sub clear_database {
    my $self = shift;

    $self->log->debug('entering clear_database()');

    $self->authors->clear();
    $self->log->info('cleared authors');

    $self->mirrors->clear();
    $self->log->info('cleared mirrors');

    $self->packages->clear();
    $self->log->info('cleared packages');

    $self->log->debug('leaving clear_database()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------


sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $mirrors  = $self->mirror_url->copy();


    $mirrors->path('/modules/07mirror.json');

    $self->{mirrors} = XAS::Darkpan::DB::Mirrors->new(
        -schema => $self->schema,
        -url    => $mirrors,
    );

    $self->{lockmgr} = XAS::Lib::Modules::Locking->new();

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
