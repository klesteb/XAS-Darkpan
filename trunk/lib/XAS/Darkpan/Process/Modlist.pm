package XAS::Darkpan::Process::Modlist;

our $VERSION = '0.01';

use DateTime;
use XAS::Darkpan;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Darkpan::Process::Base',
  filesystem => 'File',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;

    my $fh;
    my $dt = DateTime->now(time_zone => 'GMT');
    my $date = $dt->strftime('%a %b %d %H:%M:%S %Y %Z');
    my $file = File($self->path, '03modlist.data.gz');

    $self->log->debug('entering create()');

    unless ($fh = $file->open('w')) {

        $self->throw_msg(
            dotid($self->class) . '.create_packages.nocreate',
            'nocreate',
            $file->path
        );

    }

    $fh->print (<<__MODLIST);
File:        03modlist.data
Description: This was once the "registered module list" but has been retired.
        No replacement is planned.
Modcount:    0
Written-By:  XAS Darkpan $XAS::Darkpan::VERSION
Date:        $date

package CPAN::Modulelist;
sub data {
return {};
}
1;
__MODLIST

    $fh->close();

    $self->log->debug('leaving create_modlist()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->master->path('/modules/03modlist.data.gz');

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
