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
use XAS::Darkpan::Lib::Package;
use XAS::Darkpan::Parse::Packages;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Darkpan::DB::Base',
  utils   => 'dt2db :validation left',
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

sub remove {
    my $self = shift;
    my ($package, $version) = validate_params(\@_, [1,1]);

    my $schema = $self->schema;
    my $criteria = {
        package => $package,
        version => $version,
    };

    Packages->delete_records($schema, $criteria);

}

sub add {
    my $self = shift;
    my $p = validate_params(\@_, {
       -path   => 1,
       -mirror => 1,
    });

    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $info = CPAN::DistnameInfo->new($p->{'path'});
    my $dist = $info->dist;
    my $package = ($dist =~ /::/) ? $dist =~ s/-/::/ : $dist;

    my $data = {      
        package   => $package,
        dist      => $info->dist,
        version   => $info->version   || '0.0',
        maturity  => $info->maturity  || 'unknown',
        filename  => $info->filename,
        pauseid   => $info->cpanid    || 'unknown',
        extension => $info->extension,
        pathname  => $info->pathname,
        mirror    => $p->{'mirror'},
        datetime  => dt2db($dt),
        downloads => 0,
    };

    return Packages->create_record($schema, $data); 

}

sub update {
    my $self = shift;
    my $p = validate_params(\@_, {
       -id        => 1,
       -package   => { optional => 1, default => undef },
       -dist      => { optional => 1, default => undef },
       -version   => { optional => 1, default => undef },
       -maturity  => { optional => 1, default => undef },
       -filename  => { optional => 1, default => undef },
       -pauseid   => { optional => 1, default => undef },
       -extension => { optional => 1, default => undef },
       -pathname  => { optional => 1, default => undef },
       -mirror    => { optional => 1, default => undef },
       -downloads => { optional => 1, default => undef },
    });

	my $data;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');

    $data->{'id'}        = $p->{'id'};
    $data->{'package'}   = $p->{'package'}   if (defined($p->{'package'}));
    $data->{'dist'}      = $p->{'dist'}      if (defined($p->{'dist'}));
    $data->{'version'}   = $p->{'version'}   if (defined($p->{'version'}));
    $data->{'maturity'}  = $p->{'maturity'}  if (defined($p->{'maturity'}));
    $data->{'filename'}  = $p->{'filename'}  if (defined($p->{'filename'}));
    $data->{'pauseid'}   = $p->{'pauseid'}   if (defined($p->{'pauseid'}));
    $data->{'extension'} = $p->{'extension'} if (defined($p->{'extension'}));
    $data->{'pathname'}  = $p->{'pathname'}  if (defined($p->{'pathname'}));
    $data->{'mirror'}    = $p->{'mirror'}    if (defined($p->{'mirror'}));
    $data->{'downloads'} = $p->{'downloads'} if (defined($p->{'downloads'}));
    $data->{'datetime'}  = dt2db($dt),

    return Packages->update_record($schema, $data); 

}

sub data {
    my $self = shift;
    my $p = validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => { mirror => 'http://www.cpan.org' } },
       -options  => { optional => 1, type => HASHREF, default => { order_by => 'package' } },
    });

    my $path;
    my @parts = ();
    my @datum = ();
    my $schema = $self->schema;

    if (my $rs = Packages->search($schema, $p->{'criteria'}, $p->{'options'})) {

        while (my $rec = $rs->next) {

            $parts[0] = left($rec->pauseid, 1);
            $parts[1] = left($rec->pauseid, 2);
            $parts[2] = $rec->pauseid;
            $parts[3] = $rec->filename;
            
            $path = join('/', @parts);

            if (my $provides = $rec->search_related('provides')) {
                
                while (my $provide = $provides->next) {
                                        
                    push(@datum, XAS::Darkpan::Lib::Package->new(
                        -name    => $provide->module,
                        -version => $provide->version,
                        -path    => $path,
                    ));
                    
                }

            }

        }

    }

    return wantarray ? @datum : \@datum;

}

sub search {
    my $self = shift;
    my $p = validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => {} },
       -options  => { optional => 1, type => HASHREF, default => {} },
    });

    my $schema = $self->schema;

    return Packages->search($schema, $p->{'criteria'}, $p->{'options'});

}

sub find {
    my $self = shift;
    my $p = validate_params(\@_, {
       -criteria => { optional => 1, type => HASHREF, default => {} },
       -options  => { optional => 1, type => HASHREF, default => {} },
    });

    my $schema = $self->schema;

    return Packages->find($schema, $p->{'criteria'}, $p->{'options'});

}

sub fields {
    my $self = shift;
    
    my @fields = [Packages->columns()];
    
    return wantarray ? @fields : \@fields;
    
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

    $packages->load();
    $packages->parse(sub {
        my $data = shift;

        my $info = CPAN::DistnameInfo->new($data->{'path'});

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
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    Packages->delete_records($schema, $p->{'criteria'});

}

sub count {
    my $self = shift;
    my $p = validate_params(\@_, {
        -criteria => { optional => 1, default => {}, type => HASHREF },
    });

    my $schema = $self->schema;

    return Packages->count($schema, $p->{'criteria'});

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
