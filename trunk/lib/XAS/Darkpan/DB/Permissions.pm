package XAS::Darkpan::DB::Permissions;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  table  => 'Permissions'
;

use DateTime;
use Badger::URL;
use Badger::Filesystem 'File';
use Params::Validate 'HASHREF';
use XAS::Darkpan::Lib::Permission;
use XAS::Darkpan::Parse::Permissions;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::DB::Base',
  accessors => 'authors',
  utils     => 'dt2db :validation',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/modules/06perms.txt.gz') },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub remove {
    my $self = shift;
    my ($id, $mirror) = validate_params(\@_, [1,1]);

    my $schema = $self->schema;
    my $criteria = {
        pauseid => $id,
        mirror  => $mirror
    };

    Permissions->delete_records($schema, $criteria);

}

sub add {
    my $self = shift;
    my $p = validate_params(\@_, {
        -pauseid => 1,
        -module   => 1,
        -perms    => 1,
        -mirror   => { optional => 1, default => 'http://www.cpan.org' },
    });

    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');

    $p->{'datetime'} = dt2db($dt);

    return Permissions->create_record($schema, $p);

}

sub data {
    my $self = shift;
    my $p = validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => {} },
       -options  => { optional => 1, type => HASHREF, default => { order_by => 'module' } },
    });

    my @datum = ();
    my $schema = $self->schema;

    if (my $rs = Permissions->search($schema, $p->{'criteria'}, $p->{'options'})) {

        while (my $rec = $rs->next) {

            push(@datum, XAS::Darkpan::Lib::Perms->new(
                -pauseid => $rec->pauseid,
                -module  => $rec->module,
                -perms   => $rec->perms,
            ));

        }

    }

    return wantarray ? @datum : \@datum;

}

sub search {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
        -options  => { optional => 1, default => {}, type => HASHREF},
    });

    my $schema = $self->schema;

    return Permissions->search($schema, $p->{'criteria'}, $p->{'options'});

}

sub load {
    my $self = shift;

    my @datum;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $perms = XAS::Darkpan::Parse::Permissions->new(
        -cache_path   => $self->cache_path,
        -cache_expiry => $self->cache_expiry,
        -url          => $self->url,
    );

    $perms->load();
    $perms->parse(sub {
        my $data = shift;
        $data->{'datetime'} = dt2db($dt);
        return unless (defined($data->{'pauseid'}));
        push(@datum, $data);
    });

    Permissions->populate($schema, \@datum);

    @datum = ();

}

sub clear {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    Permissions->delete_records($schema, $p->{'criteria'});

}

sub count {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    return Permissions->count($schema, $p->{'criteria'});

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

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

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
