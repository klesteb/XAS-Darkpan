package XAS::Service::Profiles::Darkpan::Authors;

our $VERSION = '0.01';

use XAS::Service::Profiles::Darkpan::Constraints ':all';

#use Data::Dumper;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub build {
    my $class = shift;

    my $profile = {
        filters  => ['trim'],
        required => ['pause_id', 'name', 'email'],
        optional => ['mirror'],
        defaults => {
            mirror => 'http://www.cpan.org',
        },
        field_filters => {
            email => ['filter_email']
        },
        constraint_methods => {
            pause_id => qr/^\w+$/,
            name     => qr/^\w+$/,
            email    => valid_email,
            mirror   => valid_url,
        },
        msgs => {
            format => '%s',
            constraints => {
                pause_id => 'should be alphanumeric characters',
                name     => 'should be alphanumeric characters',,
                email    => 'should be a valid email address',
                mirror   => 'should be a valid url',
            }
        }
    };

    my $profiles = {
        authors => $profile,
    };

    return $profiles;

}

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

1;

=head1 NAME

XAS::Service::Profiles::Darkpan::Constraints - A class for creating standard validation profiles.

=head1 SYNOPSIS

 my $authors  = XAS::Service::Profiles::Darkpan::Authors->build();
 my $validate = XAS::Service::Profiles->new($authors);

=head1 DESCRIPTION

This module creates a standardized
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator> validation
profile for searches.

=head1 METHODS

=head2 build()

Initializes the vaildation profile.

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
