package XAS::Darkpan::Parse::Permissions;

our $VERSION = '0.01';

use Badger::URL;
use XAS::Lib::XML;
use Badger::Filesystem 'File';
use Params::Validate 'CODEREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Base',
  accessors => 'data',
  utils     => ':validation',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/modules/06perms.txt.gz') },
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

    $self->{'data'} = $self->_gzip_unpack($content);

}

sub parse {
    my $self = shift;
    my ($callback) = validate_params(\@_, [
        { type => CODEREF }
    ]);

    my $in_header = 1;
    
    foreach my $line (split("\n", $self->{'data'})) {

        if ($in_header) {
            
            $in_header = 0 if ($line eq "");
            next;
            
        }
        
        my ($module, $author, $perm) = split(',', $line);
        
        $callback->({
            module  => $module,
            pauseid => $author,
            perm    => $perm,
        });

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
