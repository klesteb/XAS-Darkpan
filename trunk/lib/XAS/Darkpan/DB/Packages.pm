package XAS::Darkpan::DB::Packages;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  tables => 'Packages Requires Provides'
;

use DateTime;
use Badger::URL;
use CPAN::DistnameInfo;
use Badger::Filesystem 'File';
use Params::Validate 'HASHREF';
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

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub add {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -path     => 1,
       -mirror   => { optional => 1, default => $self->url->server },
       -location => { optional => 1, default => 'remote', regex => qr/remote|local/ },
    });

    my $criteria;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $info = CPAN::DistnameInfo->new($p->{path});
    my ($package) = $info->dist =~ s/-/::/;

    my $data = {      
        package   => $package,
        dist      => $info->dist,
        version   => $info->version   || '0.0',
        maturity  => $info->maturity  || 'unknown',
        filename  => $info->filename,
        pauseid   => $info->cpanid    || 'unknown',
        extension => $info->extension,
        pathname  => $info->pathname,
        mirror    => $self->url->server,
        datetime  => dt2db($dt),
    };

    $schema->txn_do(sub {

        Packages->create($schema, $data); 

    });

}

sub search {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => {} },
       -options  => { optional => 1, type => HASHREF, default => {} },
    });

    my $schema = $self->schema;

    return Packages->search($schema, $p->{'criteria'}, $p->{'options'});

}

sub data {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => { location => 'all'} },
       -options  => { optional => 1, type => HASHREF, default => { order_by => 'packages', prefetch => ['provides','requires']} },
    });

    my @datum = ();
    my $schema = $self->schema;

    if (my $rs = Packages->search($schema, $p->{'criteria'}, $p->{'options'})) {

        while (my $rec = $rs->next) {

            push(@datum, XAS::Lib::Darkpan::Package->new(
                -name    => $rec->provides->module,
                -version => $rec->provides->version,
                -path    => $rec->packages->pathname
            ));

        }

    }

    return wantarray ? @datum : \@datum;

}

sub load {
    my $self = shift;

    my $hash;
    my @recs;
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

        # filter the packages

        my $package = $info->dist;
        $package =~ s/-/::/g;

        $hash->{$package} = {      
            dist      => $info->dist,
            version   => $info->version   || '0.0',
            maturity  => $info->maturity  || 'unknown',
            filename  => $info->filename,
            pauseid   => $info->cpanid    || 'unknown',
            extension => $info->extension,
            pathname  => $info->pathname,
            mirror    => $self->url->server,
            datetime  => dt2db($dt),
        };

    });

    foreach my $key (sort(keys %$hash)) {

        push(@recs, {
            package   => $key,
            dist      => $hash->{$key}->{'dist'},      
            version   => $hash->{$key}->{'version'},
            maturity  => $hash->{$key}->{'maturity'},
            filename  => $hash->{$key}->{'filename'},
            pauseid   => $hash->{$key}->{'pauseid'},
            extension => $hash->{$key}->{'extension'},
            pathname  => $hash->{$key}->{'pathname'},
            mirror    => $hash->{$key}->{'mirror'},
            datetime  => $hash->{$key}->{'datetime'},
        });

    }

    $schema->txn_do(sub {

        Packages->populate($schema, \@recs);

    });

    $hash  = {};
    @recs  = ();

}

sub clear {
    my $self = shift;

    my $schema = $self->schema;
    my $criteria = {
        location => 'remote'
    };

    Packages->delete_records($schema, $criteria);

}

sub count {
    my $self = shift;

    my $schema = $self->schema;

    return Packages->count($schema);

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
