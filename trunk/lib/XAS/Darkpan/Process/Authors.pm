package XAS::Darkpan::Process::Authors;

our $VERSION = '0.01';

use IO::Zlib;
use Badger::URL 'URL';
use XAS::Darkpan::DB::Authors;
use XAS::Darkpan::Parse::Authors;
use Badger::Filesystem 'Dir File';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::Process::Base',
  utils   => 'dotid :validation',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my $p = validate_params(\@_, {
       -mirror => { optional => 1, isa => 'Badger::URL', default => $self->mirror }
    });

    $self->log->debug('entering create()');

    my $fh;
    my $file = File($self->path, '01mailrc.txt.gz');

    my $authors = $self->database->data(
        -criteria => { mirror => $p->{'mirror'}->server },
        -options  => { order_by => 'pauseid' },
    );

    if ($self->lockmgr->lock($self->path)) {

        unless ($fh = IO::Zlib->new($file->path, 'wb')) {

            $self->throw_msg(
                dotid($self->class) . '.create.nocreate',
                'nocreate',
                $file->path
            );

        }

        foreach my $author (@$authors) {

            $fh->print(sprintf("%s\n", $author->to_string));

        }

        $fh->close();

        $self->lockmgr->unlock($self->path);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.create.nolock',
            'lock_dir_error',
            $self->file->path
        );

    }

    $self->log->debug('leaving create()');

}

sub load {
    my $self = shift;

    my @datum;
    my $dt = DateTime->now(time_zone => 'local');
    my $authors = XAS::Darkpan::Parse::Authors->new(
        -cache_path   => $self->cache_path,
        -cache_expiry => $self->cache_expiry,
        -url          => $self->master,
    );

    $authors->load();
    $authors->parse(sub {
        my $data = shift;
        $data->{'datetime'} = dt2db($dt);
        return unless (defined($data->{'pauseid'}));
        push(@datum, $data);
    });

    $self->database->populate(\@datum);

    @datum = ();

}

sub inject {
    my $self = shift;
    my $p = validate_params(\@_, {
       -pause_id => 1,
       -name     => 1,
       -email    => 1,
       -mirror   => { optional => 1, isa => 'Badger::URL', default => $self->mirror }
    });

    my $name    = $p->{'name'};
    my $email   = $p->{'email'};
    my $pauseid = uc($p->{'pause_id'});
    my $mirror  = $p->{'mirror'}->server;

    $self->database->add(
        -name    => $name,
        -email   => $email,
        -pauseid => $pauseid,
        -mirror  => $mirror,
    );

}

sub remove {
    my $self = shift;
    my ($id) = validate_params(\@_, [1]);
    
    return $self->database->remove($id);
    
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->master->path('/authors/01mailrc.txt.gz');

    $self->{'database'} = XAS::Darkpan::DB::Authors->new(
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
