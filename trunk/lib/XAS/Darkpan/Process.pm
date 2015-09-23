package XAS::Darkpan::Process;

our $VERSION = '0.01';

use PPI;
use IO::Zlib;
use DateTime;
use Try::Tiny;
use CPAN::Meta;
use Archive::Tar;
use XAS::Darkpan;
use CPAN::Checksums;
use CPAN::DistnameInfo;
use XAS::Darkpan::DB::Authors;
use XAS::Darkpan::DB::Mirrors;
use XAS::Darkpan::DB::Packages;
use XAS::Lib::Modules::Locking;
use Archive::Zip ':ERROR_CODES';
use Badger::Filesystem 'Dir File';
use File::Spec::Functions qw/splitdir/;
use Params::Validate qw/CODEREF HASHREF/;

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

use Data::Dumper;

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

    $self->log->debug('entering create_dirs()');

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

    $self->log->debug('leaving create_dirs()');

}

sub create_authors {
    my $self = shift;
    my ($location) = $self->validate_params(\@_, [
        { optional => 1, default => 'local', regex => qr/remote|local|all/ },
    ]);

    $self->log->debug('entering create_authors()');

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

    $self->log->debug('leaving create_authors()');

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

    $self->log->debug('leaving create_packages()');

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

    $self->log->debug('leaving create_packages()');

}

sub create_modlist {
    my $self = shift;

    my $fh;
    my $dt = DateTime->now(time_zone => 'GMT');
    my $date = $dt->strftime('%a %b %d %H:%M:%S %Y %Z');
    my $file = File($self->modules_path, '03modlist..gz');

    $self->log->debug('entering create_modlist()');

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

    $self->log->debug('leaving create_modlist()');

}

sub mirror {
    my $self = shift;
    my ($destination) = $self->validate_params(\@_, [
       { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $auth_id = 'authors/id';
    my $options = {
        order_by => 'package',
    };

    $self->log->debug('entering mirror()');

    if (my $rs = $self->packages->search(-options => $options)) {

        while (my $rec = $rs->next) {

            my $path = sprintf("%s/%s/%s", $rec->mirror, $auth_id, $rec->pathname);
            my $url  = Badger::URL->new($path);

            $self->inject(
                -url         => $url,
                -pauseid     => $rec->pauseid,
                -package_id  => $rec->id,
                -destination => $destination,
            );

        }

    }

    $self->log->debug('leaving mirror()');

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

    $self->log->debug('entering inject()');

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
        $self->load_archive($file, $package_id);
        $self->checksum($file->directory);

        $self->lockmgr->unlock_directory($lock);

    }

    $self->log->debug('leaving inject()');

}

sub inject_author {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -pauseid  => 1,
       -name     => 1,
       -email    => 1,
       -location => { optional => 1, default => 'local', regex => qr/LOCATION/ },
    });

    $self->log->debug('entering inject_author()');

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

    $self->log->debug('leaving inject_author()');

}

sub copy {
    my $self = shift;
    my ($url, $file) = $self->validate_params(\@_, [
	   { isa => 'Badger::URL' },
       { isa => 'Badger::Filesystem::File' },
    ]);

    $self->log->debug('entering copy()');

    unless ($file->exists) {

        my $contents = $self->fetch($url);
        my $fh = $file->open('w');

        $fh->write($contents);
        $fh->close;

    }

    $self->log->debug('leaving copy()');

}

sub checksum {
    my $self = shift;
    my ($directory) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    $self->log->debug('entering checksum()');

    $CPAN::Checksums::IGNORE_MATCH = 'locked.lck';
    CPAN::Checksums::updatedir($directory->path);

    $self->log->debug('leaving checksum()');

}

sub load_archive {
    my $self = shift;
    my ($file, $package_id) = $self->validate_params(\@_, [1,1]);

    my $hash = {}; # this will be normalized

    $self->log->debug('entering load_archive()');

    if ($file->path =~ m/TAR/i) {

        $self->_inspect_tar_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -hash     => $hash,
            -callback => \&_collect_package_details
        );

        $self->_inspect_tar_archive(
            -filename => $file, 
            -filter   => META, 
            -hash     => $hash,
            -callback => \&_collect_meta_details
        );

    } elsif ($file->path =~ m/ZIP/i) {

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => PACKAGE, 
            -hash     => $hash,
            -callback => \&_collect_package_details
        );

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => META, 
            -hash     => $hash,
            -callback => \&_collect_meta_details
        );

    } else {

        $self->throw_msg(
            dotid($self->class) . '.load_archive.unknownarc',
            'unknownarc',
            $file,
        );

    }

warn Dumper($hash);
    
    $self->log->debug('leaving load_archive()');

}

sub load_database {
    my $self = shift;

    $self->log->debug('entering load_database()');

    $self->authors->load();
    $self->log->info('loaded authors');

    $self->mirrors->load();
    $self->log->info('loaded mirrors');

    $self->packages->load();
    $self->log->info('loaded packages');

    $self->log->debug('leaving load_database()');

}

sub clear_database {
    my $self = shift;

    $self->log->debug('entering clear_database()');

    $self->authors->clear();
    $self->log->info('cleared authors');

    $self->mirrors->clear();
    $self->log->info('cleared mirrors');

    $self->packages->clear();
    $self->log->info('cleared packages');

    $self->log->debug('leaving clear_database()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _load_meta {
    my $self = shift;
    my $content = shift; # a reference to a scalar

    my $meta;

    $self->log->debug('entering load_meta');

    # later versions of CPAN::Meta has a load_string() method that
    # handles this problem. But that version is not available for Debian 7.8.

    try {

        if ($$content =~ /^---/ ) { # looks like YAML

            $self->log->debug('meta is yaml');
            $meta = CPAN::Meta->load_yaml_string($$content);

        } elsif ($$content =~ /^\s*\{/ ) { # looks like JSON

            $self->log->debug('meta is json');
            $meta = CPAN::Meta->load_json_string($$content);

        } else { # maybe doc-marker-free YAML

            $self->log->debug('meta is yaml');
            $meta = CPAN::Meta->load_yaml_string($$content);

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.load_meta.invalid',
            'invalid_meta',
            $ex
        );

    };

    $self->log->debug('leaving load_meta');

    return $meta;

}

sub _package_at_usual_location {   
    my $self = shift;
    my ($file) = $self->validate_params(\@_, [1]);

    my ($top, $subdir, @rest) = splitdir($file);
    defined $subdir or return 0;

    ! @rest               # path is at top-level of distro
    || $subdir eq 'lib';  # inside lib

}

sub _inspect_tar_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -filename => { isa => 'Badger::Filesystem::File' },
        -hash     => { type => HASHREF },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return ref(shift) eq 'Regexp';
                }
            }
        },
        -callback => { type => CODEREF }
    });

    my $arc;
    my $hash = $p->{'hash'};
    my $filter = $p->{'filter'};
    my $archive = $p->{'filename'};
    my $callback = $p->{'callback'};

    $self->log->debug('entering _inspect_tar_archive()');

    if ($arc = Archive::Tar->new($archive->path, 1)) {

        foreach my $file ($arc->get_files) {

            my $path = $file->full_path;

            next unless ($file->is_file && 
                         $path =~ m/$filter/i && 
                         $self->_package_at_usual_location($path));

            $callback->($self, $hash, $path, $file->get_content_by_ref);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_tar_archive.nofiles',
            'nofiles',
            $arc->error
        );

    }

    $self->log->debug('leaving _inspect_tar_archie()');

}

sub _inspect_zip_archive {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -filename => { isa => 'Badger::Filesystem::File' },
        -hash     => { type => HASHREF },
        -filter => { callbacks => {
            'must be a compiled regex' => sub {
                    return ref(shift) eq 'Regexp';
                }
            }
        },
        -callback => { type => CODEREF }
    });

    my $arc;
    my $hash = $p->{'hash'};
    my $filter = $p->{'filter'};
    my $archive = $p->{'filename'};
    my $callback = $p->{'callback'};

    $self->log->debug('entering _inspect_zip_archie()');

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

            $callback->($self, $hash, $file, \$contents);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.inspect_zip_archive.nofiles',
            'nofiles',
            $arc->error
        );

    }

    $self->log->debug('leaving _inspect_zip_archie()');

}

sub _collect_package_details {
    my $self    = shift;
    my $hash    = shift;
    my $path    = shift;
    my $content = shift;

    $self->log->debug('entering _collect_package_details()');

    my $package;
    my $dom = PPI::Document->new($content, readonly => 1);

    foreach my $element ($dom->elements) {

        if ($element->isa('PPI::Statement::Package')) {

            $package = $element->namespace;
            $self->log->debug(sprintf('package: %s', $package));

            $hash->{'provides'}->{$package}->{'pathname'} = $path;
            $self->log->debug(sprintf('pathname: %s', $path));

        } elsif ($element->isa('PPI::Statement::Variable')) {

            if ($element->content =~ /VERSION/) {

                my $content = $element->content;
                my ($version) = $content =~ /VERSION\s+\=\s+(.*)/;

                $self->log->debug(sprintf('version: %s', $version));

                $hash->{'provides'}->{$package}->{'version'} = $version;

            }

        } elsif ($element->isa('PPI::Statement::Include')) {

            my $module  = $element->module;
            my $version = $element->module_version || '0.0';

            next if ($element->type !~ /use|require/);
            next if ($module =~ /strict|warnings|vars/);

            $self->log->debug(sprintf('module: %s, version: %s', $module, $version));

            $hash->{'requires'}->{$module}->{'phase'} = 'runtime';
            $hash->{'requires'}->{$module}->{'version'} = $version;
            $hash->{'requires'}->{$module}->{'relation'} = 'required';

        }

    }

    $self->log->debug('leaving _collect_package_details()');

}

sub _collect_meta_details {
    my $self      = shift;
    my $hash     = shift;
    my $filepath = shift;
    my $content  = shift;

    $self->log->debug('entering _collect_meta_details()');

    my $meta = $self->_load_meta($content);
    my $prereqs = $meta->effective_prereqs();

    if (my $data = $prereqs->requirements_for('build','requires')) {

        $self->log->debug('found build/requires');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'build';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'required';

        }

    }

    if (my $data = $prereqs->requirements_for('build','recommends')) {

        $self->log->debug('found build/recommends');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'build';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'recommends';

        }

    }
        
    if (my $data = $prereqs->requirements_for('build','suggests')) {

        $self->log->debug('found build/suggests');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'build';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'suggests';

        }

    }

    if (my $data = $prereqs->requirements_for('build','conflicts')) {

        $self->log->debug('found build/conflicts');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'build';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'conflicts';

        }

    }

    if (my $data = $prereqs->requirements_for('test','requires')) {

        $self->log->debug('found test/requires');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'test';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'required';

        }

    }

    if (my $data = $prereqs->requirements_for('test','recommends')) {

        $self->log->debug('found test/recommends');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'test';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'recommends';

        }

    }
        
    if (my $data = $prereqs->requirements_for('test','suggests')) {

        $self->log->debug('found test/suggests');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'test';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'suggests';

        }

    }

    if (my $data = $prereqs->requirements_for('test','conflicts')) {

        $self->log->debug('found test/conflicts');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'test';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'conflicts';

        }

    }

    if (my $data = $prereqs->requirements_for('runtime','requires')) {

        $self->log->debug('found runtime/requires');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'runtime';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'required';

        }

    }

    if (my $data = $prereqs->requirements_for('runtime','recommends')) {

        $self->log->debug('found runtime/recommends');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'runtime';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'recommends';

        }

    }
        
    if (my $data = $prereqs->requirements_for('runtime','suggests')) {

        $self->log->debug('found runtime/suggests');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'runtime';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'suggests';

        }

    }

    if (my $data = $prereqs->requirements_for('runtime','conflicts')) {

        $self->log->debug('found runtime/conflicts');
        my $expr = $data->as_string_hash();

        while (my ($key, $value) = each($expr)) {

            $hash->{'requires'}->{$key}->{'phase'} = 'runtime';
            $hash->{'requires'}->{$key}->{'version'} = $value;
            $hash->{'requires'}->{$key}->{'relation'} = 'conflicts';

        }

    }

    $self->log->debug('leaving _collect_meta_details()');

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
