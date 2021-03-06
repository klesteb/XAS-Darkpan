package XAS::Darkpan::DB::Mirrors;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  table  => 'Mirrors'
;

use DateTime;
use JSON::XS;
use Params::Validate 'HASHREF';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::DB::Base',
  utils   => 'dt2db :validation',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub remove {
    my $self = shift;
    my ($id) = validate_params(\@_, [1]);

    my $rec->{'id'} = $id;
    my $schema = $self->schema;

    return Mirrors->delete_records($schema, $rec);

}

sub add {
    my $self = shift;
    my $p = validate_params(\@_, {
        -mirror => 1,
        -type   => 1,
    });

    my $results;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $rec = {
        mirror   => $p->{'mirror'},
        type     => $p->{'type'},
        datetime => dt2db($dt),
    };

    return Mirrors->create_record($schema, $rec);

}

sub update {
    my $self = shift;
    my $p = validate_params(\@_, {
        -id     => 1,
        -mirror => { optional => 1, default => undef },
        -type   => { optional => 1, default => undef },
    });

    my $data;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');

    $data->{'id'}       = $p->{'id'};
    $data->{'mirror'}   = $p->{'mirror'} if (defined($p->{'mirror'}));
    $data->{'type'}     = $p->{'type'}   if (defined($p->{'type'}));
    $data->{'datetime'} = dt2db($dt);

    return Mirrors->update_record($schema, $data);
    
}

sub data {
    my $self = shift;
    my $p = validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => { type => { '!=', 'master' } } },
       -options  => { optional => 1, type => HASHREF, default => {} },
    });

    my $schema = $self->schema;
    my $json   = JSON::XS->new->pretty->utf8();
    my $dt     = DateTime->now(time_zone => 'GMT');
    my $master = Mirrors->find($schema, { type => 'master' });

    my $mirrors = {
        master    => $master->mirror,
        timestamp => $dt->strftime('%Y-%m-%dT%d:%M:%S%z'),
        version   => '1.0',
        name      => 'Comprehensive Perl Archive Network',
    };

    if (my $rs = Mirrors->search($schema, $p->{'criteria'}, $p->{'options'})) {

        while (my $rec = $rs->next) {

            push(@{$mirrors->{'mirrors'}}, $rec->mirror);

        }

    }

    return $json->encode($mirrors);

}

sub search {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
        -options  => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    return Mirrors->search($schema, $p->{'criteria'}, $p->{'options'});

}

sub find {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
        -options  => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    return Mirrors->find($schema, $p->{'criteria'}, $p->{'options'});

}

sub fields {
    my $self = shift;
    
    my @fields = [Mirrors->columns()];
    
    return wantarray ? @fields : \@fields;
    
}
    
sub clear {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    Mirrors->delete_records($schema, $p->{'criteria'});

}

sub count {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    return Mirrors->count($schema, $p->{'criteria'});

}

sub populate {
    my $self = shift;
    my ($data) = validate_params(\@_, [1]);

    my $schema = $self->schema;

    $schema->txn_do(sub {

        Mirrors->populate($schema, $data);

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
