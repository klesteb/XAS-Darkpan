package XAS::Darkpan::DB::Packages;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  tables => 'Modules Packages'
;

use DateTime;
use Badger::URL;
use CPAN::DistnameInfo;
use Badger::Filesystem 'File';
use XAS::Lib::Darkpan::Package;
use XAS::Darkpan::Parse::Packages;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::DB::Base',
  utils   => 'dt2db',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/modules/02packages.details.txt.gz') },
    }
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub add {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -name     => 1,
       -version  => 1,
       -path     => 1,
       -mirror   => { optional => 1, default => $self->url->server },
       -location => { optional => 1, default => 'remote', regex => qr/remote|local/ },
    });

    my $criteria;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $info = CPAN::DistnameInfo->new($p->{path});
    my $module = {
        pauseid   => $info->cpanid,
        module    => $p->{'name'},
        version   => $p->{'version'} || 'undef',
        package   => $info->distvname,
        datetime  => dt2db($dt),
        location  => $p->{'location'}, 
    };
    my $package = {
        name     => $info->distvname,
        maturity => $info->maturity,
        path     => $info->pathname,
        mirror   => $p->{'mirror'},
        datetime => dt2db($dt),
    };

    $schema->txn_do(sub {

        Modules->create($schema, $module);

        eval { Pacakges->create($schema, $package); }

    });

}

sub search {
    my $self = shift;
    my ($criteria, $options) = $self->validate_params(\@_, [
        { optional => 1, default => {} },
        { optional => 1, default => {} },
    ]);

    my $schema = $self->schema;

    return Modules->search($schema, $criteria, $options);

}

sub data {
    my $self = shift;

    my @datum = ();
    my $criteria = {};
    my $schema = $self->schema;
    my $options = {
        order_by => 'module',
        prefetch => 'packages',
    };

    if (my $rs = Modules->search($schema, $criteria, $options)) {

        while (my $rec = $rs->next) {

            push(@datum, XAS::Lib::Darkpan::Package->new(
                -name    => $rec->module,
                -version => ($rec->version eq '0.0') ? 'undef' : $rec->version,
                -path    => $rec->packages->path
            ));

        }

    }

    return wantarray ? @datum : \@datum;

}

sub load {
    my $self = shift;

    my $hash;
    my @recs;
    my @datum;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $packages = XAS::Darkpan::Parse::Packages->new(
        -cache_path   => $self->cache_path,
        -cache_expiry => $self->cache_expiry,
        -url          => $self->url,
    );

    $packages->parse(sub {
        my $data = shift;

        my $info = CPAN::DistnameInfo->new($data->{path});

    	return unless ($info->distvname);

        push(@datum, {
            pauseid  => $info->cpanid || 'unknown',
            module   => $data->{name},
            version  => ($data->{version} eq 'undef') ? '0.0' : $data->{version},
            package  => $info->distvname,
            datetime => dt2db($dt),
        });

        # filter the packages

        $hash->{$info->distvname} = {
            maturity => $info->maturity || 'unknown',
            path     => $info->pathname,
            mirror   => $self->url->server,
            datetime => dt2db($dt),
        };

    });

    foreach my $key (sort(keys %$hash)) {

        push(@recs, {
            name     => $key,
            maturity => $hash->{$key}->{maturity},
            mirror   => $hash->{$key}->{mirror},
            path     => $hash->{$key}->{path},
            datetime => $hash->{$key}->{datetime},
        });

    }

    $schema->txn_do(sub {

        Modules->populate($schema, \@datum);
        Packages->populate($schema, \@recs);

    });

    $hash  = {};
    @recs  = ();
    @datum = ();

}

sub clear {
    my $self = shift;

    my $schema = $self->schema;
    my $criteria = {
        location => 'remote'
    };

    Modules->delete_records($schema, $criteria);

}

sub count {
    my $self = shift;
    my ($class, $location) = $self->validate_params(\@_, [
        { optional => 1, default => 'Packages', regex => qr/Packages|Modules/ },
        { optional => 1, default => 'remote', regex => qr/remote|local|all/ },
    ]);

    my $criteria = {
        location => $location
    };

    $criteria = {} if ($location = 'all');

    return $class->count($criteria);

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
