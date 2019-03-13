package XAS::Service::Profiles::Darkpan::Constraints;

our $VERSION = '0.01';

use Email::Valid;
use Badger::URL 'URL';

use Badger::Class
  debug   => 0,
  version => $VERSION,
  exports => {
      all => 'filter_email valid_url valid_email',
      filters => 'filter_email',
      constraints => 'valid_url valid_email'
  }
;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub filter_email {
    
    return sub {
        my $email = shift;

        return lc($email);
        
    }

}

sub valid_email {

    return sub {
        my $dfv = shift;
        
        $dfv->name_this('valid_email');

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
        
        $dfv->name_this('valid_url');
        
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

XAS::Service::Profiles::Darkpan::Authors - A class for creating standard validation profiles.

=head1 SYNOPSIS

 my $profile  = XAS::Service::Profiles::Darkpan::Authors->build();
 my $validate = XAS::Service::Profiles->new($profile);

=head1 DESCRIPTION

This module creates a standardized
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator> validation
profile for searches.

=head1 METHODS

=head2 new($fields)

Initializes the vaildation profile.

=over 4

=item B<$field>

An array ref of field names that may appear in search requests.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS::Darkpan|XAS::Darkpan>

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
