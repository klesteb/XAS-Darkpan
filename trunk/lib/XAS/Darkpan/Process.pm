package XAS::Darkpan::Process;

our $VERSION = '0.01';

use Archive::Tar;
use CPAN::Checksums;
use CPAN::DistnameInfo;
use Params::Validate 'CODEREF';
use XAS::Lib::Modules::Locking;
use XAS::Darkpan::DB::Authors;
use XAS::Darkpan::DB::Mirrors;
use XAS::Darkpan::DB::Packages;
use Archive::Zip ':ERROR_CODES';
use Badger::Filesystem 'Dir File';
use File::Spec::Functions qw/splitdir/;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Darkpan::Base',
  accessors  => 'packages authors mirrors lockmgr',
  utils      => 'dotid left',
  constant => {
    PACKAGE => qr/\.pm$/,
    META    => qr/META\.json$|META\.yml$|META\.yaml$/,
    TAR     => qr/\.tar\.gz$|\.tar\.Z$|\.tgz$/,
    ZIP     => qr/\.zip$/,
  },
  vars => {
    PARAMS => {
      -schema     => 1,
      -authors    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors') },
      -modules    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/modules') },
      -root       => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan') },
      -authors_id => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors/id') },
      -mirror     => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org') },
    }
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -authors => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->authors },
        -modules => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->modules },
        -root    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->root },
        -auth_id => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->authors_id },
    });

    my @dirs = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    my $authors    = $p->{'authors'};
    my $modules    = $p->{'modules'};
    my $root       = $p->{'root'};
    my $authors_id = $p->{'auth_id'};
    

    $d = Dir($p->{'root'});
    $d->create unless ($d->exists);

    $d = Dir($p->{'root'}, $p->{'authors'});
    $d->create unless ($d->exists);

    $d = Dir($p->{'root'}, $p->{'modules'});
    $d->create unless ($d->exists);

    $d = Dir($p->{'root'}, $p->{'auth_id'});
    $d->create unless ($d->exists);

    foreach my $dir (@dirs) {

        $d = Dir($p->{'root'}, $p->{'auth_id'}, $dir);
        $d->create unless ($d->exists);

    }

}

sub mirror {
    my $self = shift;
    my ($destination) = $self->validate_params(\@_, [
       { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $schema  = $self->schema;
    my $auth_id = $self->authors_id;
    my $criteria = {
        location => 'remote'
    };

    if (my $rs = $self->packages->search($criteria)) {

        while (my $rec = $rs->next) {

            my $file = File($destination, $rec->path);
            my $lock = $file->directory;
            my $path = sprintf("%s/%s/%s", $rec->mirror, $auth_id, $rec->path); 
            my $url  = Badger::URL->new($path)

            $lock->create unless ($lock->exists);

            if ($self->lockmgr->lock_directory($lock)) {

                $self->copy($url, $file);
                $self->checksum($file->directory);
                $self->lockmgr->unlock_directory($lock);

            }

        }

    }

}

sub inject {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -pauseid     => 1,
	   -url         => { isa => 'Badger::URL', },
       -location    => { optional => 1, default => 'local' },
       -destination => { isa => 'Badger::Filesystem::Directory' },
    });

    my $url         = $p->{'url'};
    my $location    = $p->{'location'};
    my $pauseid     = $p->{'pauseid'};
    my $destination = $p->{'destination'};

    my $file;
    my $lock;
    my @parts;

    $parts[0] = $destination;
    $parts[1] = left($pauseid, 1);
    $parts[2] = left($pauseid, 2);
    $parts[3] = $pauseid;
    $parts[4] = File($url->path)->name;

    $file = File(@parts);
    $lock = $file->directory;
    $lock->create unless ($lock->exists);

    if ($self->lockmgr->lock_directory($lock)) {

        $self->copy($url, $file);
        $self->inspect_archive($file, $location);
        $self->checksum($file->directory);

        $self->lockmgr->unlock_directory($lock);

    }

}

sub copy {
    my $self = shift;
    my ($url, $file) = $self->validate_params(\@_ [
	   { isa => 'Badger::URL' },
       { isa => 'Badger::Filesystem::File' },
    ]);

    unless ($file->exists) {

        my $contents = $self->fetch($url);
        my $fh = $file->open('w');

        $fh->write($contents);
        $fh->close;

    }

}

sub checksum {
    my $self = shift;
    my ($directory) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    $CPAN::Checksums::IGNORE_MATCH = 'locked.lck';
    CPAN::Checksums::updatedir($directory->path);

}

sub inspect_archive {
    my $self = shift;
    my ($file, $location) = $self->validate_params(\@_, [1,1]);

    if ($file->path =~ m/TAR/i) {

        $self->_inspect_tar_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -location => $location,
            -callback => \&_collect_package_details
        );

        $self->_inspect_tar_archive(
            -filename => $file, 
            -filter   => META, 
            -location => $location,
            -callback => sub {}
        );

    } elsif ($file->path =~ m/ZIP/i) {

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -location => $location,
            -callback => \&_collect_package_details
        );

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => META, 
            -location => $location,
            -callback => sub {}
        );

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_archive.unknownarc',
            'unknownarc',
            $file,
        );

    }

}

sub load_database {
    my $self = shift;

    $self->authors->load();
    $self->mirrors->load();
    $self->pacakges->load();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _package_at_usual_location {   
    my $self = shift;
    my ($file) = $self->validate_params(\@_, [1]);

    my ($top, $subdir, @rest) = splitdir($file);
    defined $subdir or return 0;

    ! @rest               # path is at top-level of distro
    || $subdir eq 'lib';  # inside lib

}

sub _collect_package_details {   
    my $self = shift;
    my ($fn, $dist, $content, $location) = $self->validate_params(\@_, [1,1,1,1]);

    my @lines  = split(/\r?\n/, $$content);
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

            $self->_register($package, $VERSION, $dist, $location) if (defined($package));

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
    $self->_register($package, $VERSION, $dist, $location) if defined $package;

}

sub _register {
    my $self = shift;
    my ($package, $version, $dist, $location) = $self->validate_params(\@_, [1,1,1,1]);

    my $auth_id = $self->authors_id;
    ($dist) = $dist =~ /$auth_id\/(.*)/;

    $self->packages->add(
        -name     => $package,
        -version  => $version,
        -path     => $dist,
        -location => $location,
    );

}

sub _inspect_tar_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -filename => { isa => 'Badger::Filesystem::File' },
        -location => { optional => 1, default => 'remote' },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return ref(shift) eq 'Regexp';
                }
            }
        },
        -callback => { type => CODEREF }
    });

    my $arc;
    my $dist = $p->{'filename'};
    my $filter = $p->{'filter'};
    my $callback = $p->{'callback'};
    my $location = $p->{'location'};

    if ($arc = Archive::Tar->new($dist->path, 1)) {

        foreach my $file ($arc->get_files) {

            my $path = $file->full_path;
              
            next unless ($file->is_file && 
                         $path =~ m/$filter/i && 
                         $self->_package_at_usual_location($path));

            $callback->($self, $path, $dist, $file->get_content_by_ref, $location);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_tar_archive.nofiles',
            'nofiles',
            $arc->error
        );

    }

}

sub _inspect_zip_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -filename => { isa => 'Badger::Filesystem::File' },
        -location => { optional => 1, default => 'remote' },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return ref(shift) eq 'Regexp';
                }
            }
        },
        -callback => { type => CODEREF }
    });

    my $arc;
    my $dist = $p->{'filename'};
    my $filter = $p->{'filter'};
    my $callback = $p->{'callback'};
    my $location = $p->{'location'};

    if ($arc = Archive::Zip->new($dist->path)) {

        foreach my $member ($arc->membersMatching($filter)) {

            my $file = $member->filename;

            next unless ($member->isTextFile && 
                         $self->_package_at_usual_location($file));

            my ($contents, $stat) = $member->contents;
            unless ($stat == AZ_OK) {

                $self->throw_msg(
                    dotid($self->class) . '.inspect_zip_archive.badzip',
                    'badzip',
                    $arc->error
                );

            }

            $callback->($self, $file, $dist, \$contents, $location);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_zip_archive.nofiles',
            'nofiles',
            $arc->error
        );

    }

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{packages} = XAS::Darkpan::DB::Packages->new(
        -schema => $self->schema,
        -mirror => $self->mirror,
    );

    $self->{authors} = XAS::Darkpan::DB::Authors->new(
        -schema => $self->schema,
        -mirror => $self->mirror,
    );

    $self->{mirrors} = XAS::Darkpan::DB::Mirrors->new(
        -schema => $self->schema,
        -mirror => $self->mirror,
    );

    $self->{lockmgr} = XAS::Lib::Modules::Locking->new();

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
