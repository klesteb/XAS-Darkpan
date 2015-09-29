package XAS::Darkpan::Process::Base;

our $VERSION = '0.01';

use Badger::URL;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'database',
  vars => {
    PARAMS => {
      -schema  => 1,
      -lockmgr => 1,
      -mirror  => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org') },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load {
  my $self = shift;

    $self->database->load(@_);

}

sub clear {
    my $self = shift;

    $self->database->clear(@_);

}

sub reload {
    my $self = shift;

    $self->database->clear(@_);
    $self->database->load(@_);

}

sub data {
    my $self = shift;

    return $self->database->data(@_);

}

sub search {
    my $self = shift;

    return $self->database->search(@_);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

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