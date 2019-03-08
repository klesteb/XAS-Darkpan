package XAS::Darkpan::Process::Permissions;

our $VERSION = '0.01';

use IO::Zlib;
use XAS::Darkpan;
use Badger::URL 'URL';
use XAS::Darkpan::DB::Permissions;
use Badger::Filesystem 'Dir File';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::Process::Base',
  utils   => 'dotid :validation',
;

# ----------------------------------------------------------------------
# Compiled regex's
# ----------------------------------------------------------------------

my $PERMS = qr/m|f|c/;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my $p = validate_params(\@_, {
        -mirror => { optional => 1, isa => 'Badger::URL', default => $self->mirror }
    });

    $self->log->debug('entering create()');

    my $criteria = {
        mirror => $p->{'mirror'}->server
    };

    my $fh;
    my $module  = $self->class;
    my $program = $self->env->script;
    my $dt      = DateTime->now(time_zone => 'GMT');
    my $date    = $dt->strftime('%a, %d %b %Y %T %Z');
    my $file    = File($self->path, '06perms.txt.gz');
    my $perms   = $self->database->data(-criteria => $criteria);
    my $count   = $self->database->count(-criteria => $criteria) + 9;

    if ($self->lockmgr->lock($self->path)) {

        unless ($fh = IO::Zlib->new($file->path, 'wb')) {

            $self->throw_msg(
                dotid($self->class) . '.create.nocreate',
                'nocreate',
                $file->path
            );

        }

        $fh->print (<<__HEADER);
File:         06perms.txt
Description:  CSV file of upload permission to the CPAN per namespace
    best-permission is one of "m" for "modulelist", "f" for
    "first-come", "c" for "co-maint"    
Columns:      package,userid,best-permission
Intended-For: private CPAN
Line-Count:   $count
Written-By:   XAS Darkpan version $XAS::Darkpan::VERSION
Date:         $date

__HEADER

        foreach my $perm (@$perms) {

            $fh->print(sprintf("%s\n", $perm->to_string));

        }

        $fh->close();

        $self->lockmgr->unlock($self->path);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.create.nolock',
            'lock_dir_error',
            $self->file->path
        );

    }

    $self->log->debug('leaving create()');

}

sub inject {
    my $self = shift;
    my $p = validate_params(\@_, {
        -pause_id => 1,
        -module   => 1,
        -perms    => { regex => $PERMS },
        -mirror   => { optional => 1, isa => 'Badger::URL', default => $self->mirror }
    });

    $self->log->debug('entering inject()');

    my $pauseid = uc($p->{'pause_id'});
    my $module  = $p->{'module'};
    my $perms   = $p->{'perms'};
    my $mirror  = $p->{'mirror'}->server;
    
    $self->database->add(
        -pauseid => $pauseid,
        -module  => $module,
        -perms   => $perms,
        -mirror  => $mirror
    );

    $self->log->debug('leaving inject()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->mirror->path('/modules/06perms.txt.gz');

    $self->{'database'} = XAS::Darkpan::DB::Permissions->new(
        -schema => $self->schema,
        -url    => $self->mirror,
    );

    $self->lockmgr->add(-key => $self->path);
    
    return $self;

}

1;

__END__

=head1 NAME

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
