package XAS::Darkpan::Process::Authors;

our $VERSION = '0.01';

use XAS::Darkpan::DB::Authors;
use XAS::Lib::Darkpan::Authors;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  vars => {
    PARAMS => {
      -schema => 1,
      -path   => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors') },
      -mirror => { optional => 1, isa => 'Badger::URL', default => Badger::Url->new('http://www.cpan.org') },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my ($location) = $self->validate_params(\@_, [
        { optional => 1, default => 'local', regex => qr/remote|local|all/ },
    ]);

    $self->log->debug('entering create()');

    my $fh;
    my $file = File($self->path, '01mailrc.txt.gz');
    my $authors = $self->authors->data(
        -criteria => { location => $location },
        -options  => { order_by => 'pauseid' },
    );

    unless ($fh = IO::Zlib->new($file->path, 'wb')) {

        $self->throw_msg(
            dotid($self->class) . '.create_authors.nocreate',
            'nocreate',
            $file->path
        );

    }

    foreach my $author (@$authors) {

        $fh->printf("%s\n", $author->to_string);

    }

    $fh->close();

    $self->log->debug('leaving create()');

}

sub inject {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -pauseid  => 1,
       -name     => 1,
       -email    => 1,
       -location => { optional => 1, default => 'local', regex => $LOCATION },
    });

    $self->log->debug('entering inject_author()');

    my $name     = $p->{'name'};
    my $email    = $p->{'email'};
    my $location = $p->{'location'};
    my $pauseid  = $p->{'pauseid'};

    $self->authors->add(
        -name     => $name,
        -email    => $email,
        -pauseid  => $pauseid,
        -location => $location,
    );

    $self->log->debug('leaving inject_author()');

}

sub load {
  my $self = shift;

    $self->authors->load();
    $self->log->info('loaded authors');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $authors = $self->mirror->copy();

    $authors->path('/authors/01mailrc.txt.gz');

    $self->{authors} = XAS::Darkpan::DB::Authors->new(
        -schema => $self->schema,
        -url    => $authors,
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

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
