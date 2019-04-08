package XAS::Darkpan::Process::Mirrors;

our $VERSION = '0.01';

use IO::Zlib;
use Badger::URL 'URL';
use XAS::Darkpan::DB::Mirrors;
use XAS::Darkpan::Parse::Mirrors;
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

sub load {
    my $self = shift;

    my @datum;
    my $dt = DateTime->now(time_zone => 'local');
    my $mirrors = XAS::Darkpan::Parse::Mirrors->new(
        -cache_path   => $self->cache_path,
        -cache_expiry => $self->cache_expiry,
        -url          => $self->master,
    );

    $mirrors->load();
    $mirrors->parse(sub {
        my $data = shift;
        $data->{'datetime'} = dt2db($dt);
        push(@datum, $data);
    });

    $self->database->populate(\@datum);

    @datum = ();

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

sub remove {
    my $self = shift;
    my ($id) = validate_params(\@_, [1]);
    
    $self->database->remove($id);
    
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->master->path('/modules/07mirror.json');

    $self->{'database'} = XAS::Darkpan::DB::Mirrors->new(
        -schema => $self->schema,
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
