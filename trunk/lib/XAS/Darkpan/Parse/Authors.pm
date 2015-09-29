package XAS::Darkpan::Parse::Authors;

our $VERSION = '0.01';

use Badger::URL;
use Badger::Filesystem 'File';
use Params::Validate 'CODEREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Parse::Base',
  accessors => 'data',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/authors/01mailrc.txt.gz') },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse {
    my $self = shift;
    my ($callback) = $self->validate_params(\@_, [
        { type => CODEREF }
    ]);

    foreach my $line (split("\n", $self->{data})) {

        my ($pauseid, $name, $email) = ( $line =~ m{^alias\s+(.*?)\s+"(.*?)\s*<(.*?)>"} );

        $callback->({
            pauseid => $pauseid,
            name    => $name,
            email   => $email,
        });

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $content = $self->fetch($self->url);

    $self->{data} = $self->_gzip_unpack($content);

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
