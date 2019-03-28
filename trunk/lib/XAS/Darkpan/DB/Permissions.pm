package XAS::Darkpan::DB::Permissions;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  table  => 'Permissions'
;

use DateTime;
use Params::Validate 'ARRAYREF HASHREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::DB::Base',
  accessors => 'authors',
  utils     => 'dt2db :validation',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Compiled regex's
# ----------------------------------------------------------------------

my $PERMS = qr/m|f|c/;

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
        -module  => 1,
        -perms   => { regex => $PERMS },
        -mirror  => { optional => 1, default => 'http://www.cpan.org' },
    });

    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');

    $p->{'datetime'} = dt2db($dt);

    return Permissions->create_record($schema, $p);

}

sub update {
    my $self = shift;
    my $p = validate_params(\@_, {
        -id      => 1,
        -pauseid => { optional => 1, default => undef },
        -module  => { optional => 1, default => undef },
        -perms   => { optional => 1, default => undef },
        -mirror  => { optional => 1, default => undef },
    });

    my $data;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');

    $data->{'id'}       = $p->{'id'};
    $data->{'pauseid'}  = $p->{'pauseid'} if (defined($p->{'pauseid'}));
    $data->{'module'}   = $p->{'module'}  if (defined($p->{'module'}));
    $data->{'mirror'}   = $p->{'mirror'}  if (defined($p->{'mirror'}));
    $data->{'datetime'} = dt2db($dt);

    if ((defined($p->{'perms'})) && ($p->{'perms'} =~ $PERMS)) {
        
        $data->{'perms'} = $p->{'perms'}   
        
    }
        
    return Permissions->update_record($schema, $data);

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

            push(@datum, XAS::Darkpan::Lib::Permission->new(
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

sub find {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
        -options  => { optional => 1, default => {}, type => HASHREF},
    });

    my $schema = $self->schema;

    return Permissions->find($schema, $p->{'criteria'}, $p->{'options'});

}

sub fields {
    my $self = shift;
    
    my @fields = [Permissions->columns()];
    
    return wantarray ? @fields : \@fields;
    
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

sub populate {
    my $self = shift;
    my ($data) = validate_params(\@_, [1]);

    my $schema = $self->schema;

    $schema->txn_do(sub {

        Permissions->populate($schema, $data);

    });
        
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
