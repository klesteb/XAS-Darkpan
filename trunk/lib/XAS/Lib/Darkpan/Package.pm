package XAS::Lib::Darkpan::Package;

our $VERSION = '0.01';

use CPAN::DistnameInfo;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  as_text => 'to_string',
  vars => {
    PARAMS => {
      -name    => 1,
      -version => 1,
      -path    => 1
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub info {
    my $self = shift;

    return CPAN::DistnameInfo->new($self->path);

}

sub to_string {
    my $self = shift;

    return sprintf("%-30s\t%5s\t%s", $self->name, $self->version, $self->path);

}

sub properties { 
    my $self = shift;

    return {
        name    => $self->name,
        version => $self->version,
        path    => $self->path,
    };

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

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
