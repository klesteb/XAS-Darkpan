package XAS::Apps::Darkpan::Processor;

use Template;
use JSON::XS;
use Web::Machine;
use Plack::Builder;
use Authen::Simple;
use Plack::App::File;
use Badger::URL 'URL';
use XAS::Lib::Lockmgr;
use XAS::Model::Schema;
use Plack::App::URLMap;
use XAS::Service::Server;
use XAS::Darkpan::DB::Packages;
use XAS::Darkpan::Process::Authors;

use XAS::Class
  version    => '0.01',
  base       => 'XAS::Lib::App::Service',
  mixin      => 'XAS::Lib::Mixins::Configs',
  utils      => 'load_module trim',
  filesystem => 'File Dir',
  accessors  => 'cfg',
  vars => {
      SERVICE_NAME         => 'DPAN_SERVERD',
      SERVICE_DISPLAY_NAME => 'DPAN Server',
      SERVICE_DESCRIPTION  => 'A local CPAN implementation'
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub build_routes {
    my $self        = shift;
    my $urlmap      = shift;
    my $base        = shift;
    my $template    = shift;
    my $json        = shift;
    my $name        = shift;
    my $description = shift;
    my $authen      = shift;
    my $dpath       = shift;
    my $mirror      = shift;

    my $lockmgr = XAS::Lib::Lockmgr->new();
    my $schema  = XAS::Model::Schema->opendb('darkpan');
    
    $$urlmap->mount('/authors/id' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Darkpan::Downloads',
        resource_args => [
            alias    => 'downloader',
            root     => Dir($dpath),
            mirror   => $mirror->copy(),
            database => XAS::Darkpan::DB::Packages->new(
                -schema => $schema,
                -url    => $mirror->copy()
            )
        ])
    );

    $$urlmap->mount('/authors' => Plack::App::File->new(
        root => Dir($dpath, '/authors')->path )
    );

    $$urlmap->mount('/modules' => Plack::App::File->new(
        root => Dir($dpath, '/modules')->path )
    );

}

sub build_static {
    my $self   = shift;
    my $urlmap = shift;
    my $root   = shift;
    
    # static routes

}

sub build_authen {
    my $self = shift;

    my @parameters;
    my $authen = $self->cfg->val('authenticator', 'name', 'Authen::Simple::PAM');
    my $params = $self->cfg->val('authenticator', 'parameters', "service = 'login'");

    foreach my $p (split(',', $params)) {

        my ($key, $value) = split('=', $p);

        push(@parameters, trim($key));
        push(@parameters, trim($value));

    }

    load_module($authen);

    return Authen::Simple->new( $authen->new(@parameters) );

}

sub build_app {
    my $self   = shift;

    # define base, name and description

    my @paths;
    my $def_root = Dir($self->env->lib, 'darkpan');

    my $path = Dir($self->env->lib, 'web', 'root');
    my $root = Dir($self->cfg->val('app', 'root', $path->path));
    my $base = Dir($self->cfg->val('app', 'base', $path->path));
    my $name = $self->cfg->val('app', 'name', 'WEB Services');
    my $description = $self->cfg->val('app', 'description', 'Test api using RESTFUL HAL-JSON');

    my $dpath = Dir($self->cfg->val('darkpan', 'path', $def_root));
    my $mirror = URL($self->cfg->val('darkpan', 'mirror', 'http://www.cpan.org'));

    push(@paths, $base->path);
    push(@paths, $root->path) unless ($base eq $root);

    # Template config

    my $config = {
        INCLUDE_PATH => \@paths,   # or list ref
        INTERPOLATE  => 1,         # expand "$var" in plain text
    };

    # create various objects

    my $authen   = $self->build_authen;
    my $json     = JSON::XS->new->utf8();
    my $template = Template->new($config);
    my $urlmap   = Plack::App::URLMap->new();

    # allow variables with preceeding _

    $Template::Stash::PRIVATE = undef;

    # handlers, using URLMap for routing

    my $builder = Plack::Builder->new();
    
    $self->build_routes(\$urlmap, $base, $template, $json, $name, $description, $authen, $dpath, $mirror);
    $self->build_static(\$urlmap, $root);

    return $builder->to_app($urlmap->to_app);

}

sub setup {
    my $self = shift;

    my $interface = XAS::Service::Server->new(
        -alias   => 'interface',
        -port    => $self->cfg->val('system', 'port', 8080),
        -address => $self->cfg->val('system', 'address', 'localhost'),
        -app     => $self->build_app,
    );

    $self->service->register('interface');

}

sub main {
    my $self = shift;

    $self->log->info_msg('startup');

    $self->setup();
    $self->service->run();

    $self->log->info_msg('shutdown');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Darkpan::Processor - This module provides a micro CPAN

=head1 SYNOPSIS

 use XAS::Apps::Darkpan::Processor;

 my $app = XAS::Apps::Processor::Processor->new();

 exit $app->run();

=head1 DESCRIPTION

This module module provides a micro CPAN.

=head1 CONFIGURATION

The configuration file follows the familiar Windows .ini format. It contains
following stanzas.

 [system]
 port = 8080
 address = 127.0.0.1

This stanza defines the network interface. By default the process listens on
port 8080 on the 127.0.0.1 network.

 [app]
 base = /var/lib/xas/web
 name = My Great service
 description = This is a really great service

This stanza defines where the root directory for html assets are stored and
the name and description of the micro service.

 [darkpan]
 path = /var/lib/xas/darkpan
 mirror = http://localhost:8080

This stanza defines where the local darkpan resides and the default mirror
for it.

=head1 EXAMPLE

 [system]
 port = 8080
 address = 127.0.0.1

 [app]
 base = /var/lib/xas/web
 name = My Great service
 description = This is a really great service

 [darkpan] 
 path = /var/lib/xas/darkpan
 mirror = http://localhost:8080

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
