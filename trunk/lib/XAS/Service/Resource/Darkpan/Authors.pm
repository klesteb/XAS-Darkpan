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
use parent 'XAS::Service::Resource';
use XAS::Service::Validate::Darkpan::Authors;
use Web::Machine::Util qw( bind_path create_header );

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  tables => ':all'
;

XAS::Rexec::Common->mixin(__PACKAGE__); # load the mixins

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->SUPER::init($args);

    $self->{'schema'} = exists $args->{'schema'}
      ? $args->{'schema'}
      : undef;

    $self->{'controller'} = exists $args->{'controller'}
      ? $args->{'controller'}
      : 'controller';

    my @fields = [Authors->columns()];

    $self->{'authors'} = XAS::Service::Validate::Darkpan::Authors->new();
    $self->{'search'}  = XAS::Service::Search->new(-columns => \@fields);

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

            unless (($id eq '_search') or ($id eq '_create')) {

                $stat = $self->check_id($id);

            }

        } elsif ($method eq 'DELETE') {

            $stat = $self->check_id($id);

        } elsif ($method eq 'POST') {

            $stat = $self->check_id($id);

        } elsif ($method eq 'PUT') {

            $stat = $self->check_id($id);

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

    if ($method eq 'DELETE') {

        # the item must exist

        if (my $id = bind_path('/:id', $path)) {

            my $state = $self->stat_job($id);
            $stat = (($state eq 'C') or ($state eq 'A'));

        }

    } elsif ($method eq 'POST') {

        $stat = 1;

        # if there is an id, then this is an action on a current job.

        if (my $id = bind_path('/:id', $path)) {

            my $state = $self->stat_job($id);
            $stat = $self->check_stat($state);

        }

    } elsif ($method eq 'PUT') {

        # if there is an id, then this is an action on a current job.

        if (my $id = bind_path('/:id', $path)) {

            my $state = $self->stat_job($id);
            $stat = ($state eq 'Q');

        }

    } elsif ($method eq 'GET') {

        $stat = 1;

        # this can return multiple items. but if an id
        # is specified, then it must exist.

        if (my $id = bind_path('/:id', $path)) {

            unless (($id eq '_search') or ($id eq '_create')) {

                my $state = $self->stat_job($id);
                $stat = ($state ne 'U');

            }

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

        my $state = $self->stat_job($id);
        my $log   = $self->build_log($id);

        if (($state eq 'C') or ($state eq 'A')) {

            $self->del_job($id);
            $log->delete if ($log->exists);

            $stat = 1;

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

        if (my $jobs = $self->get_jobs($criteria, $options)) {

            foreach my $job (@$jobs) {

                my $jobid = $self->build_id($job->{'id'});
                my $rec   = $self->build_job($jobid, $job);

                push(@{$data->{'_embedded'}->{'jobs'}}, $rec);

            }

        }

        $data->{'_links'}->{'children'} = [{
            title => 'Create',
            href  => '/rexec/jobs/_create',
        }];

    };

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    if ($id = bind_path('/:id', $path)) {

        if ($id eq '_create') {

            $data->{'_embedded'}->{'form'} = $self->create_form();

        } elsif ($id eq '_search') {

            my $params = $self->request->parameters;
            my ($criteria, $options) = $self->search->build($params);

            $build_data->($criteria, $options);

        } else {

            if (my $job = $self->get_job($id)) {

                my $rec = $self->build_job($id, $job);

                $data->{'_embedded'}->{'job'} = $rec;

            }

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

    if (my $valids = $self->jobs->check($params)) {

        my $action = $valids->{'action'};

        if ($action eq 'post') {

            if (defined($valids->{'cancel'})) {

                # from the html interface, if the cancel button was pressed,
                # redirect back to /rexec/jobs

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
    my $controller = $self->controller;

    $self->log->debug(sprintf("%s: handle_action: %s", $alias, $action));

    if ($action eq 'start') {

        my $state = $self->stat_job($id);

        if (($state eq 'Q') or ($state eq 'A')) {

            $poe_kernel->post($controller, 'start_job', $id);
            $stat = 1;

        }

    } elsif ($action eq 'resume') {

        my $state = $self->stat_job($id);

        if ($state eq 'P') {

            $poe_kernel->post($controller, 'resume_job', $id);
            $stat = 1;

        }

    } elsif ($action eq 'pause') {

        my $state = $self->stat_job($id);

        if ($state eq 'R') {

            $poe_kernel->post($controller, 'pause_job', $id);
            $stat = 1;

        }

    } elsif ($action eq 'stop') {

        my $state = $self->stat_job($id);

        if ($state eq 'R') {

            $poe_kernel->post($controller, 'stop_job', $id);
            $stat = 1;

        }

    } elsif ($action eq 'kill') {

        my $state = $self->stat_job($id);

        if ($state eq 'R') {

            $poe_kernel->post($controller, 'kill_job', $id);
            $stat = 1;

        }

    }

    return $stat;

}

sub build_20X {
    my $self  = shift;
    my $jobid = shift;

    my $data;

    # build a 20X reponse body

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    if (my $job = $self->get_job($jobid)) {

        my $info = $self->build_job($jobid, $job);
        $data->{'_embedded'}->{'job'} = $info;

    }

    return $data;

}

sub post_data {
    my $self   = shift;
    my $params = shift;

    my $jobid;
    my $alias  = $self->alias;
    my $schema = $self->schema;
    my $uri    = $self->request->uri;
    my $now    = DateTime->now(time_zone => 'UTC');
    my $dt     = dt2db($now);

    $self->log->debug("$alias: post_data");

    $schema->txn_do(sub {

        my $data = {
            status      => 'Q',
            queued_time => $dt,
            username    => $params->{'username'},
            command     => $params->{'command'},
            priority    => $params->{'priority'},
            umask       => $params->{'umask'},
            xgroup      => $params->{'group'},
            user        => $params->{'user'},
            directory   => $params->{'directory'},
            environment => 'XAS_REXECD=1;;' . ($params->{'environment'} || ''),
        };

        my $job = Jobs->create($schema, $data);
        $jobid = $self->build_id($job->id);

    });

    return $jobid;

}

sub build_job {
    my $self = shift;
    my $id   = shift;
    my $rec  = shift;

    my $log   = $self->build_log($id);
    my $state = $self->stat_job($id);

    my $data = {
        _links => {
            self => { href => "/rexec/jobs/$id", title => 'View' }
        }
    };

    if ($log->exists) {

        $data->{'_links'}->{'log'} = { href => "/rexec/logs/$id", title => 'Log' };

    }

    if ($state eq 'A') {

        $data->{'_links'}->{'delete'} = { href => "/rexec/jobs/$id", title => 'Delete' };
        $data->{'_links'}->{'start'}  = { href => "/rexec/jobs/$id", title => 'Start' };

    }

    if ($state eq 'C') {

        $data->{'_links'}->{'delete'} = { href => "/rexec/jobs/$id", title => 'Delete' };

    }

    if ($state eq 'P') {

        $data->{'_links'}->{'resume'} = { href => "/rexec/jobs/$id", title => 'Resume' };

    }

    if ($state eq 'Q') {

        $data->{'_links'}->{'start'}  = { href => "/rexec/jobs/$id", title => 'Start' };
        $data->{'_links'}->{'delete'} = { href => "/rexec/jobs/$id", title => 'Delete' };

    };

    if ($state eq 'R') {

        $data->{'_links'}->{'pause'}  = { href => "/rexec/jobs/$id", title => 'Pause' };
        $data->{'_links'}->{'resume'} = { href => "/rexec/jobs/$id", title => 'Resume' };
        $data->{'_links'}->{'stop'}   = { href => "/rexec/jobs/$id", title => 'Stop' };
        $data->{'_links'}->{'kill'}   = { href => "/rexec/jobs/$id", title => 'Kill' };

    }

    while (my ($key, $value) = each(%$rec)) {

        $data->{$key} = $value;

    }

    $data->{'jobid'} = $id;

    delete $data->{'id'};
    delete $data->{'revision'};

    return $data;

}

sub create_form {
    my $self = shift;

    # jobname:     the name of the job
    # username:    name of user that submitted the command
    # command:     command line to execute
    # priority:    prioritiy to run process under
    # umask:       process protection mask
    # group:       local group to run under
    # user:        local user to run under
    # directory:   default directory
    # environment: optional environment variables
    # after:       optional start time <yyyy-mm-ddThh:mm:ss>
    # email:       optional email address to notify

    my $form = {
        name    => 'create',
        method  => 'POST',
        enctype => 'application/x-www-form-urlencoded',
        url     => '/rexec/jobs',
        items => [{
            type  => 'hidden',
            name  => 'action',
            value => 'POST',
        },{
            type => 'fieldset',
            legend => 'Create a new Job',
            fields => [{
                id       => 'username',
                label    => 'Username',
                type     => 'textfield',
                name     => 'username',
                tabindex => 2,
                required => 1,
            },{
                id       => 'command',
                label    => 'Command',
                type     => 'textfield',
                name     => 'command',
                tabindex => 3,
                required => 1,
            },{
                id       => 'priority',
                label    => 'Priority',
                type     => 'number',
                name     => 'priority',
                min      => -1023,
                max      => 1024,
                value    => 0,
                tabindex => 5,
                required => 0,
            },{
                id       => 'umask',
                label    => 'Umask',
                type     => 'textfield',
                name     => 'umask',
                value    => '0022',
                tabindex => 6,
                required => 0,
            },{
                id       => 'group',
                label    => 'Group',
                type     => 'textfield',
                name     => 'group',
                value    => 'wise',
                tabindex => 7,
                required => 0,
            },{
                id       => 'user',
                label    => 'User',
                type     => 'textfield',
                name     => 'user',
                value    => 'wise',
                tabindex => 8,
                required => 0,
            },{
                id       => 'directory',
                label    => 'Directory',
                type     => 'textfield',
                name     => 'directory',
                value    => '/',
                tabindex => 9,
                required => 0,
            },{
                id       => 'environment',
                label    => 'Environment',
                type     => 'textfield',
                name     => 'environment',
                tabindex => 10,
                required => 0,
            }]
        },{
            type => 'standard_buttons',
            tabindex => 12,
        }]
    };

    return $form;

}

# -------------------------------------------------------------------------
# accessors - the old fashioned way
# -------------------------------------------------------------------------

sub schema {
    my $self = shift;

    return $self->{'schema'};

}

sub controller {
    my $self = shift;

    return $self->{'controller'};

}

sub search {
    my $self = shift;

    return $self->{'search'};

}

sub jobs {
    my $self = shift;

    return $self->{'jobs'};

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
            controler       -> $controller,
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
