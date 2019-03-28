package XAS::Darkpan::Process::Base;

our $VERSION = '0.01';

use Badger::URL;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Base',
  accessors => 'database',
  vars => {
    PARAMS => {
      -schema  => 1,
      -lockmgr => 1,
      -mirror  => { isa => 'Badger::URL' },
      -path    => { isa => 'Badger::Filesystem::Directory' },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub add {
    my $self = shift;
    
    return $self->database->add(@_);

}

sub clear {
    my $self = shift;

    $self->database->clear(@_);

}

sub count {
    my $self = shift;
    
    return $self->database->count(@_);
    
}

sub data {
    my $self = shift;

    return $self->database->data(@_);

}

sub find {
    my $self = shift;
    
    return $self->database->find(@_);
    
}

sub populate {
    my $self = shift;
    
    return $self->database->populate(@_);
    
}

sub reload {
    my $self = shift;

    $self->database->clear(@_);
    $self->load(@_);

}

sub remove {
    my $self = shift;
    
    $self->database->remove(@_);
    
}

sub search {
    my $self = shift;

    return $self->database->search(@_);

}

sub update {
    my $self = shift;
    
    return $self->database->update(@_);
    
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
