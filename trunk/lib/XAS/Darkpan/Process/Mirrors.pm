package XAS::Darkpan::Process::Mirrors;

our $VERSION = '0.01';

use IO::Zlib;
use Badger::URL;
use XAS::Darkpan::DB::Mirrors;
use Badger::Filesystem 'Dir File';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Process::Base',
  utils     => 'dotid :validation',
  codec     => 'JSON',
  vars => {
    PARAMS => {
      -path => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/modules/07mirror.json') },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;

    $self->log->debug('entering create()');

    my $fh;
    my $file = File($self->path, '07mirror.json');
    my $mirrors = $self->database->data();

    if ($self->lockmgr->lock($self->path)) {

        unless ($fh = IO::Zlib->new($file->path, 'wb')) {

            $self->throw_msg(
                dotid($self->class) . '.create.nocreate',
                'nocreate',
                $file->path
             );

        }

        $fh->print($mirrors);
        $fh->close();

        $self->lockmgr->unlock($self->path);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.create.nolock',
            'lock_dir_error',
            $self->path->path
        );

    }

    $self->log->debug('leaving create()');

}

sub inject {
    my $self = shift;
    my $p = validate_params(\@_, {
        -url  => { isa => 'Badger::URL' },
        -type => { optional => default => 'mirror', regex => qr/master|mirror/ },
    });

    $self->database->add(
        -mirror => $p->{'url'}->service,
        -type   => $p->{'type'},
    );

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $mirrors = $self->mirror->copy();

    $mirrors->path('/modules/07mirror.json');

    $self->{'database'} = XAS::Darkpan::DB::Mirrors->new(
        -schema => $self->schema,
        -url    => $mirrors,
    );

    $self->lockmgr->add(-key => $self->path);
    
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

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
