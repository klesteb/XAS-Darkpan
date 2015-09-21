package XAS::Darkpan::Process;

our $VERSION = '0.01';

use IO::Zlib;
use DateTime;
use CPAN::Meta;
use Archive::Tar;
use XAS::Darkpan;
use CPAN::Checksums;
use CPAN::DistnameInfo;
use Params::Validate 'CODEREF';
use XAS::Darkpan::DB::Authors;
use XAS::Darkpan::DB::Mirrors;
use XAS::Darkpan::DB::Packages;
use XAS::Lib::Modules::Locking;
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
    PACKAGE  => qr/\.pm$/,
    META     => qr/META\.json$|META\.yml$|META\.yaml$/,
    TAR      => qr/\.tar\.gz$|\.tar\.Z$|\.tgz$/,
    ZIP      => qr/\.zip$/,
    LOCATION => qr/remote|local/,
  },
  vars => {
    PARAMS => {
      -schema          => 1,
      -root_path       => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan') },
      -authors_path    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors') },
      -modules_path    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/modules') },
      -authors_id_path => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors/id') },
      -mirror_url      => { optional => 1, isa => 'Badger::URL', default => Badger::URL->new('http://www.cpan.org') },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create_dirs {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -root    => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->root_path },
        -authors => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->authors_path },
        -modules => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->modules_path },
        -auth_id => { optional => 1, isa => 'Badger::Filesystem::Directory', default => $self->authors_id_path },
    });

    my $root       = $p->{'root'};
    my $authors    = $p->{'authors'};
    my $modules    = $p->{'modules'};
    my $authors_id = $p->{'auth_id'};

    my @dirs = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    $root->create       unless ($root->exists);
    $authors->create    unless ($authors->exists);
    $modules->create    unless ($modules->exists);
    $authors_id->create unless ($authors_id->exists);

    foreach my $dir (@dirs) {

        my $d = Dir($authors_id,  $dir);
        $d->create unless ($d->exists);

    }

}

sub create_authors {
    my $self = shift;
    my ($location) = $self->validate_params(\@_, [
        { optional => 1, default => 'local', regex => qr/remote|local|all/ },
    ]);

    my $fh;
    my $file = File($self->authors_path, '01mailrc.txt.gz');
    my $criteria = {
        location => $location
    };
    my $options = {
        order_by => 'pauseid'
    };

    $criteria = {} if ($location eq 'all');

    unless ($fh = IO::Zlib->new($file->path, 'wb')) {

        $self->throw_msg(
            dotid($self->class) . '.create_authors.nocreate',
            'nocreate',
            $file->path
        );

    }

    if (my $rs = $self->authors->search($criteria, $options)) {

        while (my $rec = $rs->next) {

            $fh->printf("alias %-10s \"%s <%s>\"\n", $rec->pauseid, $rec->name, $rec->email);

        }

    }

    $fh->close();

}

sub create_packages {
    my $self = shift;
    my ($mirror, $location) = $self->validate_params(\@_, [
        { optional => 1, default => $self->mirror_url, isa => 'Badger::URL' },
        { optional => 1, default => 'local', regex => qr/remote|local|all/ },
    ]);

    my $fh;
    my $module = $self->class;
    my $program = $self->env->script;
    my $dt = DateTime->now(time_zone => 'GMT');
    my $file = File($self->modules_path, '02packages.details.txt.gz');
    my $packages = $self->packages->data(-criteria => { location => $location });

    my $date  = $dt->strftime('%a %b %d %H:%M:%S %Y %Z');
    my $count = $self->packages->count() + 9;
    my $path  = $mirror . '/modules/02packages.details.txt';

    unless ($fh = IO::Zlib->new($file->path, 'wb')) {

        $self->throw_msg(
            dotid($self->class) . '.create_packages.nocreate',
            'nocreate',
            $file->path
        );

    }

    $fh->print (<<__HEADER);
File:         02packages.details.txt
URL:          $path
Description:  Packages listed in CPAN and local repository
Columns:      package name, version, path
Intended-For: private CPAN
Line-Count:   $count
Written-By:   $program with $module $XAS::Darkpan::VERSION (full)
Last-Updated: $date

__HEADER

    foreach my $package (@$packages) {

        $fh->printf("%s\n", $package->to_string);

    }

    $fh->close();

}

sub create_modlist {
    my $self = shift;

    my $fh;
    my $dt = DateTime->now(time_zone => 'GMT');
    my $date = $dt->strftime('%a %b %d %H:%M:%S %Y %Z');
    my $file = File($self->modules_path, '03modlist..gz');

    unless ($fh = $file->open('w')) {

        $self->throw_msg(
            dotid($self->class) . '.create_packages.nocreate',
            'nocreate',
            $file->path
        );

    }

    $fh->print (<<__MODLIST);
File:        03modlist.data
Description: This was once the "registered module list" but has been retired.
        No replacement is planned.
Modcount:    0
Written-By:  XAS Darkpan $XAS::Darkpan::VERSION
Date:        $date

package CPAN::Modulelist;
sub data {
return {};
}
1;
__MODLIST

    $fh->close();

}

sub mirror {
    my $self = shift;
    my ($destination) = $self->validate_params(\@_, [
       { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $options = {
        order_by => 'package',
    };

    if (my $rs = $self->packages->search(-options => $options)) {

        while (my $rec = $rs->next) {

            my $path = sprintf("%s/%s", $rec->mirror, $rec->pathname);
            my $url  = Badger::URL->new($path);

            $self->inject(
                -url         => $url,
                -pauseid     => $rec->pauseid,
                -package_id  => $rec->id,
                -destination => $destination,
            );

        }

    }

}

sub inject {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -pauseid     => 1,
       -package_id  => 1,
	   -url         => { isa => 'Badger::URL', },
       -destination => { isa => 'Badger::Filesystem::Directory' },
       -location    => { optional => 1, default => 'local', regex => LOCATION },
    });

    my $url         = $p->{'url'};
    my $pauseid     = $p->{'pauseid'};
    my $location    = $p->{'location'};
    my $package_id  = $p->{'package_id'};
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
        $self->inspect_archive($file, $package_id);
        $self->checksum($file->directory);

        $self->lockmgr->unlock_directory($lock);

    }

}

sub inject_author {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -pauseid  => 1,
       -name     => 1,
       -email    => 1,
       -location => { optional => 1, default => 'local', regex => qr/LOCATION/ },
    });

    my $name     = $p->{'name'};
    my $email    = $p->{'email'};
    my $location = $p->{'location'};
    my $pauseid  = $p->{'pauseid'};

    $self->authors->add(
        -name     => $name,
        -email    => $email,
        -pauseid  => $pauseid,
        -location => $location,
    );

}

sub copy {
    my $self = shift;
    my ($url, $file) = $self->validate_params(\@_, [
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
    my ($file, $package_id) = $self->validate_params(\@_, [1,1]);

    if ($file->path =~ m/TAR/i) {

        $self->_inspect_tar_archive(
            -filename   => $file, 
            -filter     => PACKAGE, 
            -package_id => $package_id,
            -callback   => \&_collect_package_details
        );

        $self->_inspect_tar_archive(
            -filename   => $file, 
            -filter     => META, 
            -package_id => $package_id,
            -callback   => sub {}
        );

    } elsif ($file->path =~ m/ZIP/i) {

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -package_id => $package_id,
            -callback => \&_collect_package_details
        );

        $self->_inspect_zip_archive(
            -filename   => $file, 
            -filter     => META, 
            -package_id => $package_id,
            -callback   => sub {}
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
    $self->log->info('loaded authors');

    $self->mirrors->load();
    $self->log->info('loaded mirrors');

    $self->packages->load();
    $self->log->info('loaded packages');

}

sub clear_database {
    my $self = shift;

    $self->authors->clear();
    $self->log->info('cleared authors');

    $self->mirrors->clear();
    $self->log->info('cleared mirrors');

    $self->packages->clear();
    $self->log->info('cleared packages');

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

sub _collect_meta_details {
    my $self = shift;
    my ($path, $package_id, $content) = $self->validate_params(\@_, [1,1,1]);

    my $meta = CPAN::Meta->load_string($content);
    my $prereqs = $meta->effective_prereqs();
    
    foreach my $provided ($prereqs->requirements_for('','')) {
        
    }

}

sub _collect_package_details {   
    my $self = shift;
    my ($path, $package_id, $content) = $self->validate_params(\@_, [1,1,1]);



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

            $self->_register($package, $VERSION, $dist, $package_id) if (defined($package));

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
    $self->_register($package, $VERSION, $dist, $package_id, $location) if defined $package;

}

sub _register {
    my $self = shift;
    my ($package, $version, $dist, $package_id, $location) = $self->validate_params(\@_, [1,1,1,1]);

    my $auth_id = $self->authors_id_path;
    ($dist) = $dist =~ /$auth_id\/(.*)/;

    $self->provides->add(
        -package_id => $package_id,
        -module     => $package,
        -version    => $version,
        -pathname   => $dist,
        -datetime   => dt2db($dt),
    );

}

sub _inspect_tar_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -package_id => 1,
        -filename   => { isa => 'Badger::Filesystem::File' },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return ref(shift) eq 'Regexp';
                }
            }
        },
        -callback => { type => CODEREF }
    });

    my $arc;
    my $filter = $p->{'filter'};
    my $archive = $p->{'filename'};
    my $callback = $p->{'callback'};
    my $package_id = $p->{'package_id'};

    if ($arc = Archive::Tar->new($archive->path, 1)) {

        foreach my $file ($arc->get_files) {

            my $path = $file->full_path;

            next unless ($file->is_file && 
                         $path =~ m/$filter/i && 
                         $self->_package_at_usual_location($path));

            $callback->($self, $path, $package_id, $file->get_content_by_ref);

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
        -package_id => 1,
        -filename   => { isa => 'Badger::Filesystem::File' },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return ref(shift) eq 'Regexp';
                }
            }
        },
        -callback => { type => CODEREF }
    });

    my $arc;
    my $filter = $p->{'filter'};
    my $archive = $p->{'filename'};
    my $callback = $p->{'callback'};
    my $package_id = $p->{'package_id'};

    if ($arc = Archive::Zip->new($archive->path)) {

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

            $callback->($self, $file, $package_id, \$contents);

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

    my $authors  = $self->mirror_url->copy();
    my $mirrors  = $self->mirror_url->copy();
    my $packages = $self->mirror_url->copy();

    $packages->path('/modules/02packages.details.txt.gz');

    $self->{packages} = XAS::Darkpan::DB::Packages->new(
        -schema => $self->schema,
        -url    => $packages,
    );

    $authors->path('/authors/01mailrc.txt.gz');

    $self->{authors} = XAS::Darkpan::DB::Authors->new(
        -schema => $self->schema,
        -url    => $authors,
    );

    $mirrors->path('/modules/07mirror.json');

    $self->{mirrors} = XAS::Darkpan::DB::Mirrors->new(
        -schema => $self->schema,
        -url    => $mirrors,
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
