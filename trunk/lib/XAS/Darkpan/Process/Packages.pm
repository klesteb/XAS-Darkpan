package XAS::Darkpan::Process::Packages;

our $VERSION = '0.01';

use PPI;
use DateTime;
use Try::Tiny;
use CPAN::Meta;
use Archive::Tar;
use XAS::Darkpan;
use CPAN::Checksums;
use CPAN::DistnameInfo;
use XAS::Darkpan::DB::Packages;
use XAS::Darkpan::Lib::Package;
use Archive::Zip ':ERROR_CODES';
use Badger::Filesystem 'Dir File';
use Params::Validate qw/CODEREF HASHREF/;
use File::Spec::Functions qw/splitdir catfile/;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Darkpan::Process::Base',
  utils     => 'dotid left',
  vars => {
    PARAMS => {
      -path => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/srv/dpan/authors/id') },
    }
  }
;

# ----------------------------------------------------------------------
# Compiled regex's
# ----------------------------------------------------------------------

my $PACKAGE  = qr/\.pm$/;
my $META     = qr/META\.json$|META\.yml$|META\.yaml$/;
my $TAR      = qr/\.tar\.gz$|\.tar\.Z$|\.tgz$/;
my $ZIP      = qr/\.zip$/;
my $LOCATION = qr/remote|local/;
my $xVERSION = qr/\$(?:\w+::)*VERSION/;
my $xISA     = qr/\@ISA/;
my $PRAGMAS  = qr/constant|diagnostics|integer|sigtrap|strict|subs|warnings|sort/;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub create {
    my $self = shift;
    my ($mirror) = $self->validate_params(\@_, [
        { optional => 1, default => $self->mirror, isa => 'Badger::URL' },
    ]);

    my $fh;
    my $criteria = {
        mirror => $mirror->service
    };
    my $module = $self->class;
    my $program = $self->env->script;
    my $dt = DateTime->now(time_zone => 'GMT');
    my $file = File($self->path, '02packages.details.txt.gz');
    my $packages = $self->database->data(-criteria => $criteria);

    my $date  = $dt->strftime('%a %b %d %H:%M:%S %Y %Z');
    my $count = $self->database->count(-criteria => $criteria) + 9;
    my $path  = $mirror . '/modules/02packages.details.txt';

    $self->log->debug('entering create()');

    if ($self->lockmgr->lock_directory($self->path)) {

        unless ($fh = IO::Zlib->new($file->path, 'wb')) {

            $self->throw_msg(
                dotid($self->class) . '.create.nocreate',
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

        $self->lockmgr->unlock_directory($self->path);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.create.nolock',
            'lock_dir_error',
            $self->path->path
        );

    }

    $self->log->debug('leaving create()');

}

sub inject {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -path   => 1,
        -mirror => { optional => 1, isa => 'Badger::URL', default => $self->mirror },
    });

    $self->database->add(
        -path   => $p->{'path'},
        -mirror => $p->{'mirror'}->service,
    );

}

sub process {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -pauseid     => 1,
       -package_id  => 1,
	   -url         => { isa => 'Badger::URL', },
       -destination => { isa => 'Badger::Filesystem::Directory' },
    });

    my $url         = $p->{'url'};
    my $pauseid     = $p->{'pauseid'};
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

        $self->_copy_archive($url, $file);
        $self->_load_archive($file, $package_id);
        $self->_checksum($file->directory);

        $self->lockmgr->unlock_directory($lock);

    }

    $self->log->debug('leaving inject()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _copy_archive {
    my $self = shift;
    my ($url, $file) = $self->validate_params(\@_, [
	   { isa => 'Badger::URL' },
       { isa => 'Badger::Filesystem::File' },
    ]);

    $self->log->debug('entering _copy_archive()');
    $self->log->debug('copying '. $url);

    unless ($file->exists) {

        my $contents = $self->database->fetch($url);
        my $fh = $file->open('w');

        $fh->write($contents);
        $fh->close;

    }

    $self->log->debug('leaving _copy_archive()');

}

sub _load_archive {
    my $self = shift;
    my ($file, $package_id) = $self->validate_params(\@_, [1,1]);

    my $hash = {}; # this will be normalized

    $self->log->debug('entering _load_archive()');

    if ($file->path =~ $TAR) {

        $self->_inspect_tar_archive(
            -filename => $file, 
            -filter   => $PACKAGE, 
            -hash     => $hash,
            -callback => \&_collect_package_details
        );

        $self->_inspect_tar_archive(
            -filename => $file, 
            -filter   => $META, 
            -hash     => $hash,
            -callback => \&_collect_meta_details
        );

    } elsif ($file->path =~ $ZIP) {

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => $PACKAGE, 
            -hash     => $hash,
            -callback => \&_collect_package_details
        );

        $self->_inspect_zip_archive(
            -filename => $file, 
            -filter   => $META, 
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
    
    $self->log->debug('leaving _load_archive()');

}

sub _checksum {
    my $self = shift;
    my ($directory) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    $self->log->debug('entering _checksum()');

    $CPAN::Checksums::IGNORE_MATCH = 'locked.lck';
    CPAN::Checksums::updatedir($directory->path);

    $self->log->debug('leaving _checksum()');

}

sub _load_meta {
    my $self = shift;
    my $content = shift; # a reference to a scalar

    my $meta;

    $self->log->debug('entering _load_meta');

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

    $self->log->debug('leaving _load_meta');

    return $meta;

}

sub _package_at_usual_location {   
    my $self = shift;
    my ($file) = $self->validate_params(\@_, [1]);

    my ($top, $subdir, @rest) = splitdir($file);
    defined $subdir or return 0;

    # path is at top-level of distro, inside of 'lib'

    ! @rest || ($subdir eq 'lib');

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

    my $process_package = sub {
        my $xpackage = shift;
        my $version = shift;

        $package = $xpackage;

        if (defined($version)) {

            $hash->{'provides'}->{$package}->{'version'} = $version;

        } else {

            $hash->{'provides'}->{$package}->{'version'} = 'undef';

        }

        $hash->{'provides'}->{$package}->{'pathname'} = $path;

    };

    my $process_version = sub {
        my $version = shift;

        if ($hash->{'provides'}->{$package}->{'version'} eq 'undef') {

            $hash->{'provides'}->{$package}->{'version'} = $version;

        }

    };

    my $process_module = sub {
        my $module = shift;
        my $version = shift;

        $hash->{'requires'}->{$module}->{'phase'} = 'runtime';
        $hash->{'requires'}->{$module}->{'version'} = $version;
        $hash->{'requires'}->{$module}->{'relation'} = 'required';

    };

    my $dom = PPI::Document->new($content, readonly => 1);
    my $token = $dom->first_token;

    do {

        if ($token->isa('PPI::Token::Word')) {

            if ($token->content eq 'package') {

                $self->_parse_package(\$token, $process_package);

            } elsif (($token->content eq 'use') ||
                     ($token->content eq 'require')) {

                $self->_parse_module(\$token, $process_module);

            }

        } elsif ($token->isa('PPI::Token::Symbol')) {

            if ($token->content =~ $xVERSION) {

                $self->_parse_version(\$token, $process_version);

            } elsif ($token->content =~ $xISA) {

                $self->_parse_isa(\$token, $process_module);

            }

        }

    } while ($token = $token->next_token);

    $self->log->debug('leaving _collect_package_details()');

}

sub _collect_meta_details {
    my $self     = shift;
    my $hash     = shift;
    my $filepath = shift;
    my $content  = shift;

    $self->log->debug('entering _collect_meta_details()');

    my $meta = $self->_load_meta($content);
    my $prereqs = $meta->effective_prereqs();

    if (my $data = $meta->as_struct) {

        if (defined($data->{'provides'})) {

            $self->log->debug('found provides');

            while (my ($key, $value) = each($data->{'provides'})) {

                $hash->{'provides'}->{$key}->{'version'} = $value->{'version'};
                $hash->{'provides'}->{$key}->{'pathname'} = $value->{'file'};

            }

        }

    }

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

sub _parse_version {
    my $self = shift;
    my $token = shift;
    my $callback = shift;

    my $version = 'undef';

    # $VERSION - declarations
    #
    # our $VERSION = '0.01';
    # word,whitespace,symbol,whitespace,operator,whitespace,quote,structure
    #
    # our $VERSION = 0.01;
    # word,whitespace,symbol,whitespace,operator,whitespace,number,structure
    #
    # $Module::VERSION = '0.01';
    # symbol,whitespace,operator,whitspace,quote,structure
    #
    # $Module::VERSION = 0.01;
    # symbol,whitespace,operator,whitspace,number,structure
    #
    # our $VERSION = version->declare('0.01');
    # word,whitespace,symbol,whitespace,operator,whitespace,
    #    word,operator,word,structure,quote,structure,structure
    #

    $self->_check_previous($token, 'our');

    while ($$token = $$token->next_token) {

        $self->log->debug(
            sprintf('_parse_version - ref: %s, content: %s', 
                ref($$token), $$token->content)
        );

        if ($$token->isa('PPI::Token::Operator')) {

            $self->_goto_eos($token) if (($$token->content ne '=') &&
                                         ($$token->content ne '->'));

        } elsif ($$token->isa('PPI::Token::Quote')) {

            $version = $self->_get_quoted($token);
            $callback->($version);

            $self->_goto_eos($token);

        } elsif ($$token->isa('PPI::Token::Number')) {

            $version = $self->_get_number($token);
            $callback->($version);

            $self->_goto_eos($token);

        }

        last if $self->_check_eos($token);

    }

}

sub _parse_isa {
    my $self = shift;
    my $token = shift;
    my $callback = shift;

    my $module;
    my $version = 'undef';

    # @ISA or "use base" or "use parent" - declarations
    #
    # @ISA = 'Module';
    # symbol,whitespace,operator,whitespace,qutote|quotelike,structure
    #
    # use base 'Module';
    #
    # word,whitespace,word,whitespace,quote|quotelike,structure
    #
    # use parent qw/Module1 Module2/;
    #
    # word,whitespace,word,whitespace,quote|quotelike,structure
    #

    $self->_check_previous($token, 'use');

    while ($$token = $$token->next_token) {

        $self->log->debug(
            sprintf('_parse_isa - ref: %s, content: %s', 
                ref($$token), $$token->content)
        );

        if ($$token->isa('PPI::Token::Quote')) {

            $module = $self->_get_quoted($token);
            $callback->($module, $version);

        } elsif ($$token->isa('PPI::Token::QuoteLike::Words')) {

            my @datum = $$token->literal; 

            foreach my $data (@datum) {

                $callback->($data, $version);

            }

        }

        last if $self->_check_eos($token);

    }

}

sub _parse_package {
    my $self = shift;
    my $token = shift;
    my $callback = shift;

    my $package = '';
    my $version = 'undef';

    # package - declartions
    #
    # package Package;
    # word,whitespace,word,structure
    #
    # package Package 0.01;
    # word,whitespace,word,whitespace,number,structure
    #
    # package Package 0.01 {
    # word,whitespace,word,whitespace,number,struture
    #

    while ($$token = $$token->next_token) {

        $self->log->debug(
            sprintf('_parse_package - ref: %s, content: %s', 
                ref($$token), $$token->content)
        );

        if ($$token->isa('PPI::Token::Word')) {

            $package = $$token->content;

        } elsif ($$token->isa('PPI::Token::Number')) {

            $version = $$token->content;

        } elsif ($$token->isa('PPI::Token::Structure')) {

            last if ($$token->content eq '{');

        }

        last if $self->_check_eos($token);

    }

    $callback->($package, $version);

}

sub _parse_module {
    my $self = shift;
    my $token = shift;
    my $callback = shift;

    my $module = '';
    my $version = 'undef';

    # module - declarations
    #
    # use module;
    # word,whitepace,word,structure
    #
    # use module 1.02;
    # word,whitespace,word,whitespace,number,structure
    #
    # use base 'Module';
    # word,whitespace,word,whitespace,quote|quotelike,structure
    #
    # use parent 'Module';
    # word,whitespace,word,whitespace,quote|quotelike,structure
    #

    $self->_check_previous($token, 'use');

    while ($$token = $$token->next_token) {

        $self->log->debug(
            sprintf('_parse_module - ref: %s, content: %s', 
                ref($$token), $$token->content)
        );

        if ($$token->isa('PPI::Token::Word')) {

            if ($$token->content eq 'base') {

                return $self->_parse_isa($token, $callback);

            }

            if ($$token->content eq 'parent') {

                return $self->_parse_isa($token, $callback);

            }

            $module = $$token->content if ($module eq '');
            $self->_goto_eos($token) if ($$token->content =~ $PRAGMAS);

        } elsif ($$token->isa('PPI::Token::Number')) {

            $version = $self->_get_number($token);
            $self->_goto_eos($token);

        }

        last if $self->_check_eos($token);

    }

    $module = 'perl' if ($module eq '');
    $callback->($module, $version);

}

sub _get_quoted {
    my $self = shift;
    my $token = shift;

    if ($$token->can('literal')) {

        return $$token->literal;

    } else {

        return $$token->string;

    }

}

sub _get_number {
    my $self = shift;
    my $token = shift;

    if ($$token->can('literal')) {

        return $$token->literal;

    } else {

        return $$token->content;

    }

}

sub _goto_eos {
    my $self = shift;
    my $token = shift;

    while ($$token = $$token->next_token) {

        last if $self->_check_eos($token);

    }

    $$token = $$token->previous_token;

}

sub _check_eos {
    my $self = shift;
    my $token = shift;

    return (($$token->isa('PPI::Token::Structure')) &&
            ($$token->content eq ';'));

}

sub _check_previous {
    my $self;
    my $token = shift;
    my $wanted = shift;

    if (my $t = $$token->sprevious_sibling) {

        $self->log->debug(
            sprintf('_check_previous - last: %s, content: %s', 
                ref($t), $t->content)
        );

        $self->_goto_eos($token) if ($t->content eq '');
        $self->_goto_eos($token) if ($t->content ne $wanted);

    }

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $packages = $self->mirror->copy();

    $packages->path('/modules/02packages.details.txt.gz');

    $self->{database} = XAS::Darkpan::DB::Packages->new(
        -schema => $self->schema,
        -url    => $packages,
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

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
