package XAS::Service::Resource::Darkpan::Authors;

use strict;
use warnings;

use POE;
use DateTime;
use Try::Tiny;
use Data::Dumper;
use XAS::Utils 'dt2db';
use XAS::Service::Search;
use Badger::Filesystem 'File';
use XAS::Darkpan::Process::Authors;
use parent 'XAS::Service::Resource';
use XAS::Service::Validate::Darkpan::Authors;
use Web::Machine::Util qw( bind_path create_header );

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->SUPER::init($args);

    $self->{'authors'} = args->{'processor');
    
    my @fields = $self->authors->database->fields();

    $self->{'validate'} = XAS::Service::Validate::Darkpan::Authors->new();
    $self->{'search'}   = XAS::Service::Search->new(-columns => \@fields);

}

sub allowed_methods { [qw[ OPTIONS GET POST PUT DELETE ]] }

sub create_path {
    my $self = shift;

}

sub malformed_request {
    my $self = shift;

    my $stat   = 0;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias:  malformed_request - $path");

    if (my $id = bind_path('/:id', $path)) {

        if ($method eq 'GET') {

            unless (($id eq '_search') or ($id eq 'list')) {


            }

        } elsif ($method eq 'DELETE') {


        } elsif ($method eq 'POST') {


        } elsif ($method eq 'PUT') {


        }

    }

    return $stat;

}

sub resource_exists {
    my $self = shift;

    my $stat   = 0;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug(sprintf("%s: resource_exists: %s - %s\n", $alias, $path, $method));

    if (my $id = bind_path('/:id', $path)) {

        if ($method eq 'DELETE') {


        } elsif ($method eq 'POST') {


        } elsif ($method eq 'PUT') {


        } elsif ($method eq 'GET') {


        }

    }

    return $stat;

}

sub delete_resource {
    my $self = shift;

    my $stat  = 0;
    my $alias = $self->alias;
    my $controller = $self->controller;
    my $path  = $self->request->path_info;

    $self->log->debug("$alias: authors delete_resource - $path");

    if (my $id = bind_path('/:id', $path)) {


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
        link => '/api/authors',
        text => 'Authors'
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
            title => 'Authors',
            href  => '/api/authors',
        },
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

    my $build_data = sub {
        my $criteria = shift;
        my $options  = shift;

        my $data = $self->authors->search(-criteria => $criteria, -options => $option);

        foreach my $datum (@$data) {
            
            my $rec = $self->build_response($datum);
            push(@{$data->{'_embedded'}->{'authors'}}, $rec);
            
        }
        
        $data->{'_links'}->{'children'} = [{
            title => 'Create',
            href  => '/api/authors/create',
        },{
            title => 'List',
            href  => '/api/authors',
        }];
    };

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    if ($id = bind_path('/:id', $path)) {

        if ($id eq '_search') {

            my $params = $self->request->parameters;
            my ($criteria, $options) = $self->search->build($params);

            $build_data->($criteria, $options);
            
        } else {

            my $options = {};
            my $criteria = { id => $id };
            
            $build_data->($criteria, $options);

        }

    } else {

        my $criteria = {};
        my $options  = {};

        $build_data->($criteria, $options);

    }

    return $data;

}

sub process_params {
    my $self   = shift;
    my $params = shift;

    # create resource here

    my $data;
    my $body;
    my $stat   = 0;
    my $alias  = $self->alias;
    my $uri    = $self->request->uri;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;
    my $id     = bind_path('/:id', $path);

    $self->log->debug("$alias: process_params - $path");

    if (my $valids = $self->validate->check($params)) {

        my $action = $valids->{'action'};

        if ($action eq 'post') {

            if (defined($valids->{'cancel'})) {

                # from the html interface, if the cancel button was pressed,
                # redirect back to /api/authors

                $stat = \301;
                $self->response->header('Location' => sprintf('%s', $uri->path));

            } else {

                # this will produce a 201 response code. we need
                # to manually create the response body.

                $stat = 1;
                $id   = $self->post_data($valids);
                $data = $self->build_20X($id);
                $body = $self->format_body($data);

                $self->response->body($body);
                $self->response->header('Location' => sprintf('%s/%s', $uri->path, $id));

            }

        } else {

            if ($stat = $self->handle_action($id, $action, $valids)) {

                # this will produce a 202 response code. we need
                # to manually create the response body.

                $stat = \202;
                $data = $self->build_20X($id);
                $body = $self->format_body($data);

                $self->response->body($body);
                $self->response->header('Location' => sprintf('%s/%s', $uri->path, $id));

            } else {

                $stat = \404;

            }

        }

    } else {

        $stat = \404;

    }

    return $stat;

}

sub handle_action {
    my $self   = shift;
    my $id     = shift;
    my $action = shift;
    my $params = shift;

    my $stat = 0;
    my $alias = $self->alias;

    $self->log->debug(sprintf("%s: handle_action: %s", $alias, $action));

    if ($action eq 'start') {

    } elsif ($action eq 'resume') {

    } elsif ($action eq 'pause') {

    } elsif ($action eq 'stop') {

    } elsif ($action eq 'kill') {

    }

    return $stat;

}

sub build_20X {
    my $self  = shift;
    my $id    = shift;

    my $data;

    # build a 20X reponse body

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    if (my $author = $self->get_author($id)) {

        my $info = $self->build_response($author);
        $data->{'_embedded'}->{'author'} = $info;

    }

    return $data;

}

sub post_data {
    my $self   = shift;
    my $params = shift;

    my $id;
    my $alias  = $self->alias;
    my $schema = $self->schema;
    my $uri    = $self->request->uri;
    my $now    = DateTime->now(time_zone => 'UTC');
    my $dt     = dt2db($now);

    $self->log->debug("$alias: post_data");

    my $data = {
        pauseid  => $params->{'pause_id'},
        name     => $params->{'name'},
        email    => $params->{'email'},
        mirror   => $params->{'mirror'},
        datetime => $dt,
    };
        
    my $results = Authors->create_record($schema, $data);

    return $results->id;

}

sub build_response {
    my $self = shift;
    my $rec  = shift;

    my $id = $rec->id;
    my $data = {
        _links => {
            self   => { href => "/api/authors/$id", title => 'Self' },
            delete => { href => "/api/authors/$id", title => 'Delete' },
            edit   => { href => "/api/authors/$id", title => 'Edit' },
        }
    };

    while (my ($key, $value) = each(%$rec)) {

        $data->{$key} = $value;

    }

    $data->{'id'} = $id;

    delete $data->{'id'};
    delete $data->{'revision'};

    return $data;

}

sub create_form {
    my $self = shift;

    # pause_id: the authors PAUSE name
    # name:     name of user that submitted the command
    # email:    command line to execute
    # mirror:   prioritiy to run process under

    my $form = {
        name    => 'create',
        method  => 'POST',
        enctype => 'application/x-www-form-urlencoded',
        url     => '/api/authors',
        items => [{
            type  => 'hidden',
            name  => 'action',
            value => 'POST',
        },{
            type => 'fieldset',
            legend => 'Create a new Author',
            fields => [{
                id       => 'username',
                label    => 'Username',
                type     => 'textfield',
                name     => 'username',
                tabindex => 2,
                required => 1,
            },{
                id       => 'name',
                label    => 'name',
                type     => 'textfield',
                name     => 'name',
                tabindex => 3,
                required => 1,
            },{
                id       => 'email',
                label    => 'email',
                type     => 'textfield',
                name     => 'email',
                tabindex => 5,
                required => 1,
            },{
                id       => 'mirror',
                label    => 'mirror',
                type     => 'textfield',
                name     => 'mirror',
                value    => 'http://www.cpan.org',
                tabindex => 6,
                required => 0,
            }]
        },{
            type => 'standard_buttons',
            tabindex => 7,
        }]
    };

    return $form;

}

# -------------------------------------------------------------------------
# accessors - the old fashioned way
# -------------------------------------------------------------------------

sub search {
    my $self = shift;

    return $self->{'search'};

}

sub validate {
    my $self = shift;

    return $self->{'validate'};

}

sub authors {
    my $self = shift;
    
    return $self->{'authors'};
    
}

1;

__END__

=head1 NAME

XAS::Service::Resource::Darkpan::Authors - Perl extension for the XAS environment

=head1 SYNOPSIS

    my $builder = Plack::Builder->new();

    $builder->mount('/api/authors' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Darkpan::Authors',
        resource_args => [
            alias           => 'authors',
            json            => $json,
            template        => $template,
            schema          => $schema,
            app_name        => $name,
            app_description => $description
        ] )->to_app
    );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/rexec/jobs" and the services it provides.

A job defines a task to be executed on the local system. These jobs are first
inserted into a database and the job controller starts them. The jobs can be
started, stopped, paused, resumed or deleted from the database. If any
output occurs from the job. It is recorded into a log file. This log file is
removed when the job is deleted.

=head1 METHODS - Web::Machine

Web::Machine provides callbacks for processing the request. These have been
overridden.

=head2 init

This method interfaces the passed resource_args to accessors.

=head2 allowed_methods

This returns the allowed methods for the handler. The defaults are
OPTIONS GET POST DELETE HEAD.

=head2 create_path

This method does nothing and just overrides the default callback.

=head2 malformed_request

This method checks the request url for proper format.

=head2 resource_exists

This method checks to see if the job exists within the database.

=head2 delete_resource

This method will delete the job from the database and the associated log file.

=head1 METHODS - Ours

These methods are used to make writting services easier.

=head2 from_json

This method will take action depending on the posted data. It will take the
posted data and normalize it. The action may be to queue the job into the
database or to start, stop, pause or resume a current job.

=head2 from_html

This method will take action depending on the posted data. This may be to
queue the job into the database or to start, stop, pause or resume a current
job.

=head2 handle_action

This method is for starting, stopping, pausing or resuming a job. This is done
by passing a message to the job controller. The controller updates the database
as to the current status of the job. This method will call build_20X() to
format the correct response to the action.

=head2 build_20X

This method will build the data structure needed for a 20X response. Some
of the actions will not create the correct data structure when performed.

=head2 post_data

This method will write the posted parameters into the internal database.

=head2 build_job

This method creates the data structure for a job. This will later be translated
into html or json.

=head2 create_form

This method creates the data structure needed for a form. This form can be
used for data input of a job.

=head1 ACCESSORS

These accessors are used to interface the arguments passed into the Service
Machine Resource.

=head2 schema

Returns the handle to the database.

=head2 controller

Returns the name of the job controller

=head1 SEE ALSO

=over 4

=item L<XAS::Service::Resource|XAS::Service::Resource>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
