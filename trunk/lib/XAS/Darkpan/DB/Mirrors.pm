package XAS::Darkpan::DB::Mirrors;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  table  => 'Mirrors'
;

use DateTime;
use JSON::XS;
use Badger::URL;
use Badger::Filesystem 'File';
use Params::Validate 'HASHREF';
use XAS::Darkpan::Parse::Mirrors;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::DB::Base',
  utils   => 'dt2db',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/modules/07mirror.json') },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub remove {
    my $self = shift;
    my ($mirror) = $self->validate_params(\@_, [1]);

    my $schema = $self->schema;
    my $criteria = {
        mirror => $mirror
    };

    Mirrors->delete_records($schema, $criteria);

}

sub add {
    my $self = shift;
    my ($mirror, $type) = $self->validate_params(\@, [
        1,
        { optional => 1, default => 'remote' }
    ]);

    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $rec = {
        mirror   => $mirror,
        type     => $type,
        datetime => dt2db($dt),
    };

    Mirrors->create_record($schema, $rec);

}

sub data {
    my $self = shift;

    my $schema = $self->schema;
    my $json   = JSON::XS->new->pretty->utf8();
    my $dt     = DateTime->now(time_zone => 'UTC');
    my $master = Mirrors->find($schema, { type => 'master' });

    my $mirrors = {
        master    => $master->mirror,
        timestamp => $dt->strftime('%Y-%m-%dT%l:%M:%S%z'),
        version   => '1.0',
        name      => 'Comprehensive Perl Archive Network',
    };

    if (my $rs = Mirrors->search($schema, { type => { '!=', 'master' }})) {

        while (my $rec = $rs->next) {

            push(@{$mirrors->{mirrors}}, $rec->mirror);

        }

    }

    return $json->encode($mirrors);

}

sub search {
    my $self = shift;
    my ($criteria, $options) = $self->validate_params(\@_, [
        { optional => 1, default => {}, type => HASHREF },
        { optional => 1, default => {}, type => HASHREF },
    ]);

    my $schema = $self->schema;

    return Mirrors->search($schema, $criteria, $options);

}

sub load {
    my $self = shift;

    my @datum;
    my $schema  = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $mirrors = XAS::Darkpan::Parse::Mirrors->new(
        -cache_path   => $self->cache_path,
        -cache_expiry => $self->cache_expiry,
        -url          => $self->url,
    );

    $mirrors->parse(sub {
        my $data = shift;
        $data->{datetime} = dt2db($dt);
        push(@datum, $data);
    });

    Mirrors->populate($schema, \@datum);

    @datum = ();

}

sub clear {
    my $self = shift;

    my $schema = $self->schema;
    my $criteria = {
        type => ['master', 'mirror']
    };

    Mirrors->delete_records($schema, $criteria);

}

sub count {
    my $self = shift;
    my ($location) = $self->validate_params(\@_, [
        { optional => 1, default => 'local', regex => qr/remote|local|all/ },
    ]);

    my $schema = $self->schema;
    my $criteria = {
        location => $location
    };

    $criteria = {} if ($location eq 'all');

    return Mirrors->count($schema, $criteria);

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
