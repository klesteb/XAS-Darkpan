package XAS::Darkpan::DB::Authors;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Darkpan',
  table  => 'Authors'
;

use DateTime;
use Badger::URL;
use Badger::Filesystem 'File';
use XAS::Lib::Darkpan::Author;
use XAS::Darkpan::Parse::Authors;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::DB::Base',
  accessors => 'authors',
  utils     => 'dt2db',
  vars => {
    PARAMS => {
      -url => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org/authors/01mailrc.txt.gz') },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub remove {
    my $self = shift;
    my ($id) = $self->validate_params(\@_, [1]);

    my $schema = $self->schema;
    my $criteria = {
        pausied => $id
    };

    Authors->delete_records($schema, $criteria);

}

sub add {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -pauseid => 1,
        -name    => 1,
        -email   => 1,
    });

    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');

    $p->{datetime} = dt2db($dt);

    Authors->create_record($schema, $p);

}

sub data {
    my $self = shift;

    my @datum = ();
    my $criteria = {};
    my $options = {
        order_by => 'pauseid'
    };
    my $schema = $self->schema;

    if (my $rs = Authors->search($schema, $criteria, $options)) {

        while (my $rec = $rs->next) {

            push(@datum, XAS::Lib::Darkpan::Author->new(
                -pauseid => $rec->pauseid,
                -name    => $rec->name,
                -email   => $rec->email,
            ));

        }

    }

    return wantarray ? @datum : \@datum;

}

sub search {
    my $self = shift;
    my ($criteria, $options) = $self->validate_params(\@_, [
        { optional => 1, default => {} },
        { optional => 1, default => {} },
    ]);

    my $schema = $self->schema;

    return Authors->search($schema, $criteria, $options);

}

sub load {
    my $self = shift;

    my @datum;
    my $schema = $self->schema;
    my $dt = DateTime->now(time_zone => 'local');
    my $authors = XAS::Darkpan::Parse::Authors->new(
        -cache_path   => $self->cache_path,
        -cache_expiry => $self->cache_expiry,
        -url          => $self->url,
    );

    $authors->parse(sub {
        my $data = shift;
        $data->{datetime} = dt2db($dt);
        push(@datum, $data);
    });

    Authors->populate($schema, \@datum);

    @datum = ();

}

sub clear {
    my $self = shift;

    my $schema = $self->schema;
    my $criteria = {
        locataion => 'remote'
    };

    Authors->delete_records($schema, $criteria);

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