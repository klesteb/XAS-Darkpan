package XAS::Service::Resource::Darkpan::Authors;

use strict;
use warnings;

our $VERSION = '0.01';

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

    $self->{'authors'} = $args->{'processor'};
    
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

    my $stat   = 1;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug(sprintf("%s: malformed_request: %s - %s\n", $alias, $path, $method));

    if ($method eq 'GET') {

        $stat = 0;

        if (my $id = bind_path('/:id', $path)) {

            unless ($id eq '_search') {

                if ($self->authors->database->find(-criteria => { id => $id })) {

                    $stat = 0;

                }

            }

        }

    } elsif ($method eq 'DELETE') {

        if (my $id = bind_path('/:id', $path)) {

            if ($self->authors->database->find(-criteria => { id => $id })) {

                $stat = 0;

            }

        }

    } elsif ($method eq 'POST') {

        $stat = 0;

        if (my $id = bind_path('/:id', $path)) {

            $stat = 1;

        }

    } elsif ($method eq 'PUT') {

        if (my $id = bind_path('/:id', $path)) {

            if ($self->authors->database->find(-criteria => { id => $id })) {

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

    if ($method eq 'DELETE') {

        if (my $id = bind_path('/:id', $path)) {

            if ($self->authors->database->find(-criteria => { id => $id })) {

                $stat = 1;

            }

        }

    } elsif ($method eq 'POST') {

        $stat = 1;

    } elsif ($method eq 'PUT') {

        if (my $id = bind_path('/:id', $path)) {

            if ($self->authors->database->find(-criteria => { id => $id })) {

                $stat = 1;

            }

        }

    } elsif ($method eq 'GET') {

        if (my $id = bind_path('/:id', $path)) {

            if ($self->authors->database->find(-criteria => { id => $id })) {

                $stat = 1;

            }

        } else {

            $stat = 1;

        }

    }

    return $stat;

}

sub delete_resource {
    my $self = shift;

    my $stat  = 0;
    my $alias = $self->alias;
    my $path  = $self->request->path_info;
    my $id    = bind_path('/:id', $path);
    
    $self->log->debug("$alias: delete_resource - $path");

    if ($self->authors->database->remove($id)) {

        $stat = 1;

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

        my $recs = $self->authors->search(-criteria => $criteria, -options => $options);

        while (my $datum = $recs->next) {

            my $rec = $self->build_response($datum);
            push(@{$data->{'_embedded'}->{'authors'}}, $rec);

        }

        $data->{'_links'}->{'children'} = [{
            title => 'Create',
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

    $self->log->debug(sprintf("%s: get_response: %s", $alias, Dumper($data)));

    return $data;

}

sub process_params {
    my $self   = shift;
    my $params = shift;

    # create resource here

    my $data;
    my $body;
    my $stat   = 0;
    my $results = undef;
    my $alias  = $self->alias;
    my $uri    = $self->request->uri;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: process_params - $path");
    $self->log->debug(sprintf("$alias: %s", Dumper($params)));

    try {

        if (my $valids = $self->validate->check($params)) {

            $self->log->debug(sprintf("$alias: %s", Dumper($valids)));

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

                    $stat    = 1;
                    $results = $self->post_data($valids);
                    $data    = $self->build_20X($results);
                    $body    = $self->format_body($data);

                    $self->response->body($body);
                    $self->response->header('Location' => sprintf('%s/%s', $uri->path, $results->{'id'}));

                }

            } elsif ($action eq 'put') {
                
                $valids->{'id'} = bind_path('/:id', $path);
                
                # this will produce a 205 response code. we need
                # to manually create the response body.

                $stat    = 1;
                $results = $self->put_data($valids);
                $data    = $self->build_20X($results);
                $body    = $self->format_body($data);

                $self->response->body($body);
                $self->response->header('Location' => $uri->path);

                $stat = \205;
                
            } else {

                $stat = \404;

            }

        } else {

            $stat = \404;

        }

    } catch {

        my $ex = $_;
        $self->log->fatal($ex);

        $stat = \409;

    };

    return $stat;

}

sub build_20X {
    my $self    = shift;
    my $status  = shift;
    my $results = shift;

    my $data;
    my $criteria = {
        id => $results->{'id'}
    };
    
    # build a 20X reponse body

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    if (my $rec = $self->authors->database->find(-criteria => $criteria)) {
        
        my $info = $self->build_response($rec);
        $data->{'_embedded'}->{'authors'} = $info;
        
    }

    return $data;

}

sub post_data {
    my $self   = shift;
    my $params = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: post_data");

    my $results = $self->authors->database->add(
        -pauseid => $params->{'pauseid'},
        -name    => $params->{'name'},
        -email   => $params->{'email'},
        -mirror  => $params->{'mirror'},
    );

    return $results;

}

sub put_data {
    my $self   = shift;
    my $params = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: put_data");

    my $results = $self->authors->database->update(
        -id      => $params->{'id'},
        -pauseid => $params->{'pauseid'},
        -name    => $params->{'name'},
        -email   => $params->{'email'},
        -mirror  => $params->{'mirror'},
    );

    return $results;

}

sub build_response {
    my $self = shift;
    my $rec  = shift;

    my $id = $rec->id;
    my $data = {
        _links => {
            self   => { href => "/api/authors/$id", title => 'Self' },
            delete => { href => "/api/authors/$id", title => 'Delete' },
            update => { href => "/api/authors/$id", title => 'Update' },
        }
    };

    $data->{'id'}       = $rec->id;
    $data->{'pauseid'}  = $rec->pauseid;
    $data->{'name'}     = $rec->name;
    $data->{'email'}    = $rec->email;
    $data->{'mirror'}   = $rec->mirror;
    $data->{'datetime'} = dt2db($rec->datetime);

    return $data;

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
        url     => '/api/authors',
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
         template        => $template,
         json            => $json,
         app_name        => $name,
         app_description => $description,
         authenticator   => $authen,
         processor => XAS::Darkpan::Process::Authors->new(
             -schema  => $schema,
             -lockmgr => $lockmgr,
             -path    => Dir($dpath, 'authors', 'id'),
             -mirror  => $mirror->copy()
        )
     ])
 );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/api/authors" and the services it provides.

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
OPTIONS GET POST DELETE HEAD.

=head2 create_path

This method does nothing and just overrides the default callback.

=head2 malformed_request

This method checks the request url for proper format.

=head2 resource_exists

This method checks to see if the record exists within the database.

=head2 delete_resource

This method will delete the record from the database.

=head1 METHODS - Ours

These methods are used to make writting services easier.

=head2 build_20X

This method will build the data structure needed for a 20X response. Some
of the actions will not create the correct data structure when performed.

=head2 post_data

This method will write the posted parameters into the internal database.

=head2 put_data

This method will update the record  in the internal database.

=head2 create_form

This method creates the data structure needed for a form.

=head1 ACCESSORS

These accessors are used to interface the arguments passed into the Service
Machine Resource.

=head2 search

This returns the handle for searches.

=head2 validate

This returns the handle for data validation.

=head2 authors

This returns the handle to access the authors functionality.

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
