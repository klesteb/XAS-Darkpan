package XAS::Darkpan::Parse::Recent;

our $VERSION = '0.01';

use YAML::XS;
use Badger::URL;
use Badger::Filesystem 'File';
use Params::Validate 'CODEREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Base',
  accessors => 'data meta',
  utils     => ':validation',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/authors/RECENT.recent') },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load {
    my $self = shift;
    
    my $content = $self->fetch($self->url);

    $self->{'data'} = Load($content);
    
}

sub parse {
    my $self = shift;
    my ($callback) = validate_params(\@_, [
        { type => CODEREF }
    ]);

    $self->{'meta'} = $self->{'data'}->{'meta'};

    foreach my $item (@{$self->{'data'}->{'recent'}}) {

        $callback->($item);

    }

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
