package XAS::Service::Profiles::Darkpan::Constraints;

our $VERSION = '0.01';

use Email::Valid;
use Badger::URL 'URL';

use Badger::Class
  debug   => 0,
  version => $VERSION,
  base    => 'Badger::Exporter',
  exports => {
    all => 'valid_url valid_email',
    tags => {
       constraints => 'valid_url valid_email'
    }
  }
;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub valid_email {

    return sub {
        my $dfv = shift;
        
        $dfv->name_this('email');

        my $val = $dfv->get_current_constraint_value();
        my $rc = Email::Valid->address(
            '-address' => $val,
            '-mxcheck' => 1
        );
        
        return defined $rc;
        
    }

}    

sub valid_url {

    return sub {
        my $dfv = shift;
        
        $dfv->name_this('url');
        
        my $val = $dfv->get_current_constraint_value();
        my $url = URL($val);
        
        return ($url->server ne '');
    
    }
    
}

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

1;

=head1 NAME

XAS::Service::Profiles::Darkpan::Constraints - A class for creating Data::FormValidator constraints.

=head1 SYNOPSIS

 use XAS::Service::Profiles::Darkpan::Constraints ':all';

=head1 DESCRIPTION

This module provides constraints the are usable with 
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator>
parameter validation.

=head1 METHODS

=head2 valid_email

This constriant checks to see if an email address is conformant with
RFC 822 and wither a MX record exists for the domain.

=head2 valid_url

This constraint checks for a valid URL. It doesn't verify that the URL is
workable.

=head1 SEE ALSO

=over 4

=item L<XAS::Darkpan|XAS::Darkpan>

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2019 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
