package XAS::Service::Resource::Darkpan::Create;

use strict;
use warnings;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use Data::Dumper;
use XAS::Darkpan::Process;
use parent 'XAS::Service::Resource';
use Web::Machine::Util qw( bind_path create_header );

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->SUPER::init($args);

    $self->{'processor'} = $args->{'processor'};
    
}

sub allowed_methods { [qw[ OPTIONS GET POST ]] }

sub create_path {
    my $self = shift;

}

sub content_types_accepted {
    
    return [
        { '*/*' => 'from_any' },
    ];
    
}

sub malformed_request {
    my $self = shift;

    my $stat   = 1;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug(sprintf("%s: malformed_request: %s - %s\n", $alias, $path, $method));

    if ($method eq 'GET') {

        $stat = 0;
        
        if (my $action = bind_path('/:action', $path)) {

            $action = lc($action);
            
            if ($action eq 'mailrc') {
                
                $stat = 1;

            } elsif ($action eq 'packages') {
                
                $stat = 1;

            } elsif ($action eq 'modlist') {
                
                $stat = 1;

            } elsif ($action eq 'mirror') {
                
                $stat = 1;

            } elsif ($action eq 'perms') {
                
                $stat = 1;

            }

        }

    } elsif ($method eq 'POST') {

        if (my $action = bind_path('/:action', $path)) {

            $action = lc($action);
            
            if ($action eq 'mailrc') {
                
                $stat = 0;

            } elsif ($action eq 'packages') {
                
                $stat = 0;

            } elsif ($action eq 'modlist') {
                
                $stat = 0;

            } elsif ($action eq 'mirror') {
                
                $stat = 0;

            } elsif ($action eq 'perms') {
                
                $stat = 0;

            }

        }

    }

    return $stat;

}

sub resource_exists {
    my $self = shift;

    # for form processing

    my $stat   = 0;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug(sprintf("%s: resource_exists: %s - %s\n", $alias, $path, $method));

    if ($method eq 'POST') {

        if (my $action = bind_path('/:action', $path)) {

            $action = lc($action);
            
            if ($action eq 'mailrc') {
                
                $stat = 1;

            } elsif ($action eq 'packages') {
                
                $stat = 1;

            } elsif ($action eq 'modlist') {
                
                $stat = 1;

            } elsif ($action eq 'mirror') {
                
                $stat = 1;

            } elsif ($action eq 'perms') {
                
                $stat = 1;

            }

        }

    } elsif ($method eq 'GET') {

        $stat = 1;

        if (my $action = bind_path('/:action', $path)) {

            $action = lc($action);
            
            if ($action eq 'mailrc') {
                
                $stat = 0;

            } elsif ($action eq 'packages') {
                
                $stat = 0;

            } elsif ($action eq 'modlist') {
                
                $stat = 0;

            } elsif ($action eq 'mirror') {
                
                $stat = 0;

            } elsif ($action eq 'perms') {
                
                $stat = 0;

            }

        }

    }

    return $stat;

}

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

sub get_navigation {
    my $self = shift;

    return [{
        link => '/api',
        text => 'Root',
    },{
        link => '/api/create/mailrc',
        text => 'Create 01mailrc.txt.gz'
    },{
        link => '/api/create/packages',
        text => 'Create 02packages.details.txt.gz'
    },{
        link => '/api/create/modlist',
        text => 'Create 03modlist.data.gz'
    },{
        link => '/api/create/perms',
        text => 'Create 06perms.txt.gz'
    },{
        link => '/api/create/mirror',
        text => 'Create 07mirror.json'
    }];

}

sub get_links {
    my $self = shift;

    return {
        parent => {
            title => 'Root',
            href  => '/api',
        },
        self => {
            title => 'Create',
            href  => '/api/create',
        },
        children => [{
            link => '/api/create/mailrc',
            text => 'mailrc'
        },{
            link => '/api/create/packages',
            text => 'packages'
        },{
            link => '/api/create/modlist',
            text => 'modlist'
        },{
            link => '/api/create/perms',
            text => 'permsissions'
        },{
           link => '/api/create/mirror',
           text => 'mirror'
        }]
    };

}

sub get_response {
    my $self = shift;

    my $id;
    my $data;
    my $form;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: get_response - $path");

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    $self->log->debug(sprintf("%s: get_response: %s", $alias, Dumper($data)));

    return $data;

}

sub from_any {
    my $self = shift;
    
    # get the post parameters
    
    my $params  = $self->request->parameters;
    
    return $self->process_params($params);

}

sub process_params {
    my $self   = shift;
    my $params = shift;

    # create resource here

    my $data;
    my $stat   = 0;
    my $alias  = $self->alias;
    my $uri    = $self->request->uri;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: process_params - $path");
    $self->log->debug(sprintf("$alias: %s", Dumper($params)));

    try {

        if (my $action = bind_path('/:action', $path)) {

            $action = lc($action);
        
            if ($action eq 'mailrc') {
                
                $self->processor->authors->create();
                $self->response->header('Location' => sprintf('%s', $uri->path));
                $stat = \201;
                
            } elsif ($action eq 'packages') {
                
                $self->processor->packages->create();
                $self->response->header('Location' => sprintf('%s', $uri->path));
                $stat = \201;

            } elsif ($action eq 'modlist') {
                
                $self->processor->modlist->create();
                $self->response->header('Location' => sprintf('%s', $uri->path));
                $stat = \201;

            } elsif ($action eq 'mirror') {
                
                $self->processor->mirrors->create();
                $self->response->header('Location' => sprintf('%s', $uri->path));
                $stat = \201;

            } elsif ($action eq 'perms') {
                
                $self->processor->permissions->create();
                $self->response->header('Location' => sprintf('%s', $uri->path));
                $stat = \201;

            }

        }

    } catch {

        my $ex = $_;
        $self->log->fatal($ex);

        $stat = \409;

    };

    return $stat;

}

sub create_form {
    my $self = shift;

    # pauseid: the authors PAUSE name
    # name:    full name
    # email:   email address for pauseid
    # mirror:  mirror the pauseid is associated with

    my $form = {
        name    => 'create',
        method  => 'POST',
        enctype => 'application/x-www-form-urlencoded',
        url     => '/api/create',
        items => [{
            type  => 'hidden',
            name  => 'action',
            value => 'POST',
        },{
            type => 'fieldset',
            legend => 'Create a new Author',
            fields => [{
                id       => 'pauseid',
                label    => 'Pause Id',
                type     => 'textfield',
                name     => 'pauseid',
                tabindex => 1,
                required => 1,
            },{
                id       => 'name',
                label    => 'Name',
                type     => 'textfield',
                name     => 'name',
                tabindex => 2,
                required => 1,
            },{
                id       => 'email',
                label    => 'Email',
                type     => 'textfield',
                name     => 'email',
                tabindex => 3,
                required => 1,
            },{
                id       => 'mirror',
                label    => 'Mirror',
                type     => 'textfield',
                name     => 'mirror',
                value    => 'http://www.cpan.org',
                tabindex => 4,
                required => 0,
            }]
        },{
            type     => 'standard_buttons',
            tabindex => 5,
        }]
    };

    return $form;

}

# -------------------------------------------------------------------------
# accessors - the old fashioned way
# -------------------------------------------------------------------------

sub processor {
    my $self = shift;

    return $self->{'processor'};

}

1;

__END__

=head1 NAME

XAS::Service::Resource::Darkpan::Create - Perl extension for the XAS environment

=head1 SYNOPSIS

 my $builder = Plack::Builder->new();

 $builder->mount('/api/create' => Web::Machine->new(
     resource => 'XAS::Service::Resource::Darkpan::Create',
     resource_args => [
         alias           => 'authors',
         template        => $template,
         json            => $json,
         app_name        => $name,
         app_description => $description,
         authenticator   => $authen,
         processor => XAS::Darkpan::Process->new(
             -schema  => $schema,
             -path    => Dir($dpath),
             -mirror  => $mirror->copy()
        )
     ])
 );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/api/create" and the services it provides.

=head1 METHODS - Web::Machine::Resource

Web::Machine::Resource provides callbacks for processing the request. These 
have been overridden.

=head2 init

This method interfaces the passed resource_args to accessors. The following
are additional arguments.

=over 4

=item B<processor>

The processor used to manage the authors table.

=back

=head2 allowed_methods

This returns the allowed methods for the handler. The defaults are
OPTIONS GET POST.

=head2 create_path

This method does nothing and just overrides the default callback.

=head2 malformed_request

This method checks the request url for proper format.

=head2 resource_exists

This method checks the request url for proper format.

=head2 content_types_accepted

This method overrides the base method and allows any content type.

=head1 METHODS - Ours

These methods are used to make writting services easier.

=head2 from_any

This method will process any content type..

=head2 create_form

This method creates the data structure needed for a form.

=head1 ACCESSORS

These accessors are used to interface the arguments passed into the Service
Machine Resource.

=head2 processor

This returns the handle to access the processor.

=head1 SEE ALSO

=over 4

=item L<XAS::Service::Resource|XAS::Service::Resource>

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
