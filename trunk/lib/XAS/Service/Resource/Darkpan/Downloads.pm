package XAS::Service::Resource::Darkpan::Downloads;

use strict;
use warnings;

use POE;
use DateTime;
use Try::Tiny;
use XAS::Utils 'trim';
use Badger::URL 'URL';
use CPAN::DistnameInfo;
use MIME::Types 'by_suffix';
use Badger::Filesystem 'File Dir';
use parent 'Web::Machine::Resource';

use Data::Dumper;

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->{'log'} = XAS::Factory->module('logger');
    $self->{'env'} = XAS::Factory->module('environment');

    $self->{'alias'} = exists $args->{'alias'}
      ? $args->{'alias'}
      : 'downloader';

    $self->{'root'} = exists $args->{'root'}
      ? $args->{'root'}
      : $self->env->lib;

    $self->{'database'} = exists $args->{'database'}
      ? $args->{'database'}
      : undef;

    $self->{'mirror'} = exists $args->{'mirror'}
      ? $args->{'mirror'}
      : URL('http://www.cpan.org');

}

sub malformed_request {
    my $self = shift;

    my $stat   = 1;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->uri->path;
    my $info   = CPAN::DistnameInfo->new($path);

    $self->log->debug("$alias: malformed_request");

    if ($method eq 'GET') {

        try {

            my $criteria = {
                pauseid  => $info->cpanid,
                filename => $info->filename,
                mirror   => $self->mirror->server
            };

            if ($self->database->find(-criteria => $criteria)) {

                $stat = 0;

            } else {

                if (File($self->root, $info->pathname)->exists) {

                    $stat = 0;

                }

            }

        } catch {

            my $ex = $_;
            $self->log->fatal($ex);

        };

    }

    return $stat;

}

sub content_types_provided {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: content_types_provided");

    return [
        { '*/*' => 'loader' }
    ];

}

sub finish_request {
    my $self     = shift;
    my $metadata = shift;

    my $alias  = $self->alias;
    my $user   = $self->request->user || 'unknown';
    my $method = $self->request->method;
    my $code   = $self->response->code;
    my $path   = $self->request->uri->path;
    my $info   = CPAN::DistnameInfo->new($path);

    $self->log->debug("$alias: finish_request");

    $self->log->info(
        sprintf('%s: "%s" requested a %s for %s with a status of %s',
            $alias, $user, $method, $path, $code)
    );

    unless (defined($metadata->{'exception'})) {

        my $criteria = {
            pauseid  => $info->cpanid,
            filename => $info->filename,
            mirror   => $self->mirror->server
        };

        if (my $rec = $self->database->find(-criteria => $criteria)) {

            my $downloads = $rec->downloads + 1;

            $self->database->update(-id => $rec->id, -downloads => $downloads);

        }

    }

}

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

sub loader {
    my $self = shift;

    my $file;
    my $buffer;
    my $filename;
    my $encoding;
    my $extension;
    my $mediatype;
    my $alias = $self->alias;
    my $path  = $self->request->uri->path;
    my $info  = CPAN::DistnameInfo->new($path);

    $self->log->debug("$alias: entering loader");

    my $criteria = {
        pauseid  => $info->cpanid,
        filename => $info->filename,
        mirror   => $self->mirror->server
    };

    if (my $rec = $self->database->find(-criteria => $criteria)) {

        $file = File($rec->pathname);

    } else {

        $file = File($self->root, $info->pathname);

    }

    $extension = lc($file->extension);
    ($mediatype, $encoding) = by_suffix($extension);

    $buffer = $file->read;
    $self->response->content_type(($mediatype || 'text/plain'));

    $self->log->debug("$alias: leaving loader");

    return $buffer;

}

# -------------------------------------------------------------------------
# accessors - the old fashion way
# -------------------------------------------------------------------------

sub mirror {
    my $self = shift;

    return $self->{'mirror'};

}

sub root {
    my $self = shift;

    return $self->{'root'};

}

sub database {
    my $self = shift;

    return $self->{'database'};

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
    my $schema  = XAS::Model::Database->opendb('darkpan;);
    my $mirror = Badger::URL->new('http://localhost:8080');

    $builder->mount('/authors' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Darkpan::Downloads',
        resource_args => [
            alias    => 'downloader',
            root     => Dir($path),
            mirror   => $mirror->copy(),
            database => XAS::Darkpan::DB::Packages->new(
                -schema => $schema,
                -url    => $mirror->copy(),
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
