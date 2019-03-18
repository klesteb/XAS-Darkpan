package XAS::Service::Resource::Darkpan::Root;

use strict;
use warnings;

our $VERSION = '0.01';

use parent 'XAS::Service::Resource';

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

sub get_navigation {
    my $self = shift;

    return [{
        link => '/api',
        text => 'Root',
    },{
        link => '/api/authors',
        text => 'Authors'
    },{
        link => '/api/packages',
        text => 'Packages'
    },{
        link => '/api/mirrors',
        text => 'Mirrors'
    },{
        link => '/api/permissions',
        text => 'Permissions'
    }];

}

sub get_links {
    my $self = shift;

    return {
        self => {
            title => 'Root',
            href  => '/api',
        },
        children => [{
            title => 'Authors',
            href  => '/api/authors',
        },{
            title => 'Packages',
            href  => '/api/packages',
        },{
            title => 'Mirrors',
            href  => '/api/mirrors',
        },{
            title => 'Permissions',
            href  => '/api/permissions',
        }],
    };

}

sub get_response {
    my $self = shift;

    return {
        '_links'     => $self->get_links(),
        'navigation' => $self->get_navigation()
    };

}

1;

__END__

=head1 NAME

XAS::Service::Resource::Darkpan::Root - Perl extension for the XAS environment

=head1 SYNOPSIS

 my $builder = Plack::Builder->new();

 $builder->mount('/api' => Service::Machine->new(
     resource => 'XAS::Service::Resource::Darkpan::Root',
     resource_args => [
         alias           => 'root',
         template        => $template,
         json            => $json,
         app_name        => $name,
         app_description => $description
     ] )->to_app
 );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/api" and the services it provides.

=head1 METHODS - Web::Machine::Resources

No overrides needed.

=head1 METHODS - Ours

Overrides default methods from L<XAS::Service::Resource|XAS::Service::Resource>.

=head1 SEE ALSO

=over 4

=item L<XAS::Service::Resource|XAS::Service::Resource>

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
