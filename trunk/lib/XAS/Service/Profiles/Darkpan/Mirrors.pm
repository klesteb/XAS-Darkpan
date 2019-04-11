package XAS::Service::Profiles::Darkpan::Mirrors;

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
        required => ['mirror', 'type', 'action'],
        optional => ['id'],
        defaults => {
            mirror => 'http://www.cpan.org',
            type   => 'master'
        },
        field_filters => {
            type   => ['lc'],
            mirror => ['lc'],
        },
        dependencies => {
            action => {
                post => ['mirror', 'type'],
                put  => ['mirror', 'type'],
            }
        },
        constraint_methods => {
            id      => qr/\d+/,
            type    => qr/master|mirror/,
            mirror  => valid_url,
            action  => FV_set(1, qw( post put )),
        },
        msgs => {
            format => '%s',
            constraints => {
                id      => 'should be numeric characters',
                type    => "should be either \"master\" or \"mirror\"",
                mirror  => 'should be a valid url',
                action  => 'must be one of these: post',
            }
        }
    };

    my $profiles = {
        mirrors => $profile,
    };

    return $profiles;

}

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

1;

=head1 NAME

XAS::Service::Profiles::Darkpan::Mirrors - A class for creating standard validation profiles.

=head1 SYNOPSIS

 my $profile  = XAS::Service::Profiles::Darkpan::Mirrors->build();
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
