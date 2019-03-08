package XAS::Darkpan::Process::Mirrors;

our $VERSION = '0.01';

use IO::Zlib;
use Badger::URL;
use XAS::Darkpan::DB::Mirrors;
use Badger::Filesystem 'Dir File';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::Process::Base',
  utils   => 'dotid :validation',
  codec   => 'JSON',
;

# ----------------------------------------------------------------------
# Compiled regex's
# ----------------------------------------------------------------------

my $TYPES = qr/master|mirror/;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;

    $self->log->debug('entering create()');

    my $mirrors = $self->database->data();
    my $file = File($self->path, '07mirror.json');

    if ($self->lockmgr->lock($self->path)) {

        my $fh = $file->open('w');

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
        -type => { optional => 1, default => 'mirror', regex => $TYPES },
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

    $self->mirror->path('/modules/07mirror.json');

    $self->{'database'} = XAS::Darkpan::DB::Mirrors->new(
        -schema => $self->schema,
        -url    => $self->mirror,
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
