package XAS::Service::Validate::Darkpan::Authors;

our $VERSION = '0.01';

use XAS::Service::Profiles;
use XAS::Service::Profiles::Darkpan::Authors;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Service::CheckParameters',
  accessors => 'profile',
  utils     => ':validation',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub check {
    my $self = shift;
    my ($multi) = validate_params(\@_, [
        { isa => 'Hash::MultiValue' },
    ]);

    my $params = $multi->as_hashref;

    return $self->check_parameters($params, 'jobs');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $profile = XAS::Service::Profiles::Darkpan::Authors->build();

    $self->{'profile'} = XAS::Service::Profiles->new($profile);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Service::Validate::Darkpan::Authors - A class to verify the Authors profile.

=head1 SYNOPSIS

 use XAS::Service::Validate::Darkpan::Authors;

 my $profile = XAS::Service::Validate::Darkpan::Authors->new();

 if (my $valids = $profile->check($params)) {

 }

=head1 DESCRIPTION

This modules provides the validation routines for validating parameters.

=head1 METHODS

=head2 new

This method initializes the module.

=head2 check($params)

This method will verify that the parameters is consitent with the Jobs profile.

=over 4

=item B<$params>

The parameters to verify against the profile.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Darkpan|XAS::Darkpan>

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2019 by Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
