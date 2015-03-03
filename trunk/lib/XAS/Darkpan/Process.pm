package XAS::Darkpan::Process;

our $VERSION = '0.01';

use Archive::Tar;
use Archive::Zip;
use CPAN::Checksums;
use CPAN::DistnameInfo;
use XAS::Lib::Modules::Locking;
use XAS::Darkpan::DB::Packages;
use Params::Validate 'CODEREF';
use File::Spec::Functions qw/splitdir/;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Darkpan::Base',
  accesors   => 'packages',
  filesystem => 'Dir File',
  utils      => 'dir_walk dotid',
  constant => {
    PACKAGE => qr/\.pm$/i,
    META    => qr/^META\.json | ^META\.yml | ^META\.yaml/x1;
    TAR     => qr/ \.tar\.gz$ | \.tar\.Z$ | \.tgz$/xi,
    ZIP     => qr/ \.zip$ /xi,
  },
  vars => {
    PARAMS => {
      -schema => 1,
      -cfg    => 1,
    }
  }
;

# badversion = "illegal version for %s, found '%s': %s"
# noarch = "unknow archive type: %s"

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -authors => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->cfg->authors },
        -modules => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->cfg->modules },
        -root    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->cfg->root }
        -auth_id => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->cfg->auth_id },
    });

    my $d;
    my @dirs = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    $d = Dir($p->{root});
    $d->create unless ($d->exists);

    $d = Dir($p->{root}, $p->{authors});
    $d->create unless ($d->exists);

    $d = Dir($p->{root}, $p->{modules});
    $d->create unless ($d->exists);

    $d = Dir($p->{root}, $p->{auth_id});
    $d->create unless ($d->exists);

    foreach my $dir (@dirs) {

        $d = Dir($p->{root}, $p->{auth_id}, $dir);
        $d->create unless ($d->exists);

    }

}

sub mirror {
    my $self = shift;
    my ($source, $destination) = $self->validate_params(\@_, [
       { isa => 'Badger::URL' },
       { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $data = $self->fetch($source);
    my $file = File($destination, $source->path);
    my $lock = $file->directory;

    $lock->create unless ($lock->exists);

    if ($self->lockmgr->lock_directory($lock)) {

        unless ($file->exists) {

            my $fh = $file->open('w');
            $fh->write($data);
            $fh->close;

        }

        $self->inspect_archive($file);
        $self->lockmgr->unlock_directory($lock);

    }

}

sub checksums {
    my $self = shift;
    my ($dir) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors/id') },
    ]);

}

sub inspect_archive {
    my $self = shift;
    my ($file) = $self->validate_params(\@_, [1]);

    if ($file =~ /TAR/) {

        $self->inspect_tar_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -callback => sub {}
        );

        $self->inspect_tar_archive(
            -filename => $file, 
            -filter   => META, 
            -callback => sub {}
        );

    } elsif ($file =~ /ZIP/) {

        $self->inspect_zip_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -callback => sub {}
        );

        $self->inspect_zip_archive(
            -filename => $file, 
            -filter   => META, 
            -callback => sub {}
        );

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_archive.unknown',
            'unknowwarc'
            $file
        );

    }

}

sub inspect_tar_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -filename => { isa => 'Badger::Filesystem::File' },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return shift->ref('RegExp');
                }
            }
        },
        -callback => { isa => CODEREF }
    });

    my $arc;
    my $dist = $p->{'filename'};
    my $filter = $p->{'filter'};
    my $callback = $p->{'callback'};

    if ($arc = Archive::Tar->new($dist->path, 1)) {

        foreach my $file ($arc->get_files) {

            my $path = $file->full_path;

            next unless ($file->is_file && 
                         path =~ /$filter/ && 
                         $self->_package_at_usual_location($file));

            $callback->($self, $path, $dist, $file->get_content_by_ref);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_tar_archive.nofiles',
            'nofiles',
            $arc->error
        );

    }

}

sub inspect_zip_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -filename => { isa => 'Badger::Filesystem::File' },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return shift->ref('RegExp');
                }
            }
        },
        -callback => { isa => CODEREF }
    });

    my $arc;
    my $dist = $p->{'filename'};
    my $filter = $p->{'filter'};
    my $callback = $p->{'callback'};

    if ($arc = Archive::Zip->new($dist->path)) {

        foreach my $member ($arc->membersMatching($filter)) {

            my $file = $member->filename;

            next unless ($member->isTextFile && 
                         $self->_package_at_usual_location($file));

            my ($content, $stat) = $member->contents;
            unless ($stat == AZ_OK) {

                $self->throw_msg(
                    dotid($self->class) . '.inspect_zip_archive.badzip',
                    'badzip',
                    $arc->error
                );

            }

            $callback->($self, $file, $dist, \$contents);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_zip_archive.nofiles',
            'nofiles',
            $arc->error
        );

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _package_at_usual_location {   
    my $self = shift;
    my ($file) = $self->validate_params(\@_, [1]);

    my ($top, $subdir, @rest) = splitdir($file->path);
    defined $subdir or return 0;

    ! @rest               # path is at top-level of distro
    || $subdir eq 'lib';  # inside lib

}

sub _collect_package_details {   
    my $self = shift;
    my ($fn, $dist, $content) = $self->validate_params(\@_, [1,1,1]);

    my @lines  = split(/\r?\n/, $content);
    my $in_pod = 0;
    my $package;

    local $VERSION = undef;  # may get destroyed by eval

    while (@lines) {

        local $_ = shift @lines;
        last if m/^__(?:END|DATA)__$/;

        $in_pod = ($1 ne 'cut') if (m/^=(\w+)/);
        next if ($in_pod || m/^\s*#/);

        $_ .= shift @lines while m/package|use|VERSION/ && !m/\;/;

        if ( m/^\s* package \s* ((?:\w+\:\:)*\w+) (?:\s+ (\S*))? \s* ;/x ) {

            my ($thispkg, $v) = ($1, $2);
            my $thisversion;

            if ($v) {

                $thisversion = eval {qv($v)};

                $self->log->warn_msg('badversion', $thispkg, $v, $@) if ($@);

            }

            # second package in file?

            $self->_register($package, $VERSION, $dist) if (defined($package));

            ($package, $VERSION) = ($thispkg, $thisversion);

            $self->log->debug("pkg $package from $fn");

        }

        if ( m/^ (?:use\s+version\s*;\s*)?
            (?:our)? \s* \$ ((?: \w+\:\:)*) VERSION \s* \= (.*)/x ) {

            defined $2 or next;
            my ($ns, $vers) = ($1, $2);

            # some versions of CPAN.pm do contain lines like "$VERSION =~ ..."
            # which also need to be processed.

            eval "\$VERSION =$vers";
            if (defined $VERSION) {   

                ($package = $ns) =~ s/\:\:$// if (length $ns);

                $self->log->debug("pkg $package version $VERSION");

            }

        }

    }

    $VERSION = $VERSION->numify if (ref($VERSION));
    $self->_register($package, $VERSION, $dist) if defined $package;

}

sub _register {
    my $self = shift;
    my ($package, $verson, $dist) = $self->validate_params(\@_, [1,1,1]);

    my $auth_id = $self->cfg->author_id;
    my ($path) = $dist->path =~ /$atuth_id(.*)/;

    $self->packages->add(
        -name    => $package,
        -version => $version,
        -path    => $path
    );

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{packages} = XAS::Darkpan::DB::Package->new(
        -schema => $self->schema
    );

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

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
