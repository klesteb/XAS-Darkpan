package XAS::Service::Profiles::Darkpan::Authors;

our $VERSION = '0.01';

use XAS::Service::Profiles::Darkpan::Constraints ':all';
use Data::FormValidator::Constraints::MethodsFactory ':set';

#use Data::Dumper;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub build {
    my $class = shift;

    my $profile = {
        filters  => ['trim'],
        required => ['pauseid', 'name', 'email', 'action'],
        optional => ['mirror', 'id'],
        defaults => {
            mirror => 'http://www.cpan.org',
        },
        field_filters => {
            email   => ['lc'],
            action  => ['lc'],
            pauseid => ['uc']
        },
        dependencies => {
            action => {
                post => ['pauseid', 'name', 'email', 'mirror'],
                put  => ['pauseid', 'name', 'email', 'mirror'],
            }
        },
        constraint_methods => {
            id      => qr/\d+/,
            pauseid => qr/^\w+$/,
            name    => qr/\w+/,
            email   => valid_email,
            mirror  => valid_url,
            action  => FV_set(1, qw( post put )),
        },
        msgs => {
            format => '%s',
            constraints => {
                id      => 'should be numeric characters',
                pauseid => 'should be alphanumeric characters',
                name    => 'should be alphanumeric characters',
                email   => 'should be a valid email address',
                mirror  => 'should be a valid url',
                action  => 'must be one of these: post',
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

XAS::Service::Profiles::Darkpan::Authors - A class for creating standard validation profiles.

=head1 SYNOPSIS

 my $profile  = XAS::Service::Profiles::Darkpan::Authors->build();
 my $validate = XAS::Service::Profiles->new($profile);

=head1 DESCRIPTION

This module creates a standardized
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator> validation
profile for searches.

=head1 METHODS

=head2 build()

Initializes the vaildation profile.

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
