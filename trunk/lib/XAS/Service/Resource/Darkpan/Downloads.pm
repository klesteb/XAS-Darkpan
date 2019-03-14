package XAS::Service::Resource::Darkpan::Downloads;

use strict;
use warnings;

use POE;
use DateTime;
use XAS::Utils 'trim';
use parent 'Web::Machine::Resource';
use Web::Machine::Util qw( bind_path );

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->{'alias'} = exists $args->{'alias'}
      ? $args->{'alias'}
      : 'downloader';

    $self->{'processor'} = exists $args->{'processor'}
      ? $args->{'processor'}
      : undef;

    $self->{'root'} = exists $args->{'root'}
      ? $args->{'root'}
      : undef;

    $self->{'log'} = XAS::Factory->module('logger');
    $self->{'env'} = XAS::Factory->module('environment');

}

sub resource_exists {
    my $self = shift;

    my $stat   = 0;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: resource_exists");

    if ($method eq 'GET') {

        if (my $package = bind_path('/:package', $path)) {

            $stat = File($self->root, $package)->exists;

        }

    }

    return $stat;

}

sub finish_request {
    my $self     = shift;
    my $metadata = shift;

    my $alias  = $self->alias;
    my $user   = $self->request->user || 'unknown';
    my $uri    = $self->request->uri->path;
    my $method = $self->request->method;
    my $code   = $self->response->code;
    my $path   = $self->request->path_info;

    $self->log->info(
        sprintf('%s: %s requested a %s for %s with a status of %s',
            $alias, $user, $method, $uri, $code)
    );

}

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# accessors - the old fashion way
# -------------------------------------------------------------------------

sub root {
    my $self = shift;

    return $self->{'root'};

}

sub processor {
    my $self = shift;

    return $self->{'processor'};

}

sub alias {
    my $self = shift;

    return $self->{'alias'};

}

sub log {
    my $self = shift;

    return $self->{'log'};

}

sub env {
    my $self = shift;

    return $self->{'env'};

}

1;

__END__

=head1 NAME

XAS::Service::Resource::Darkpan::Downloads - Perl extension for the XAS environment

=head1 SYNOPSIS

    my $builder = Plack::Builder->new();
    my $lockmgr = XAS::Lib::Lockmgr->new();
    my $schema  = XAS::Model::Database->opendb('darkpan;);
    my $mirror = Badger::URL->new('http://localhost:8080');

    $builder->mount('/authors' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Darkpan::Downloads',
        resource_args => [
            alias => 'downloader',
            root  => Dir($path),
            processor => XAS::Darkpan::Process::Authors->new(
                -schema  => $schema,
                -lockmgr => $lockmgr,
                -root    => Dir($path),
                -mirror  => $mirror->copy()
            )
        ] )->to_app
    );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/rexec/logs" and the services it provides.

Logs are associated with jobs. Not all jobs will create a log. Logs are
deleted when jobs are deleted.

=head1 METHODS - Web::Machine

Web::Machine provides callbacks for processing the request. These have been
overridden.

=head2 resource_exists

This method checks to see if the job exists within the database.

=head2 finish_reqest

This method writes out a log entry..

=head1 METHODS - Ours

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
