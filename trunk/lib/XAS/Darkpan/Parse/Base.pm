package XAS::Darkpan::Parse::Base;

our $VERSION = '0.01';

use CHI;
use HTTP::Request;
use Compress::Zlib;
use XAS::Lib::Curl::HTTP;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  accessors  => 'cache curl',
  utils      => 'dotid',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -cache_path   => { optional => 1, default => '.cache' },
      -cache_expiry => { optional => 1, default => '3 minutes' },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub fetch {
    my $self = shift;
    my ($url) = $self->validate_params(\@_, [
        { isa => 'Badger::URL' },
    ]);

    my $content;
    my $scheme = lc($url->scheme);

    if ($scheme =~ /http/) {

        my $response;
        my $request;
        my $key = $url->path;

        unless ($content = $self->cache->get($key)) {

            $request = HTTP::Request->new(GET => $url->text);
            $request->header('User-Agent', 'XAS Darkpan');

            $response = $self->curl->request($request);

            if ($response->is_success) {

                $content = $response->content;
                $self->cache->set($key, $content);

            } else {

                $self->throw_msg(
                    dotid($self->class) . '.fetch.request',
                    'badrequest',
                    $url,
                    $response->status_line
                );

            }

        }

    } elsif ($scheme =~ /file/) {

        my $file = File($url->path);
        $content = $file->read;

    } else {

        $self->throw_msg(
            dotid($self->class) . '.fetch.scheme',
            'badscheme',
            $scheme
        );

    }

    return $content;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _gzip_unpack {
    my $self = shift;
    my $packed = shift;

    return Compress::Zlib::memGunzip($packed);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{cache} = CHI->new(
        driver     => 'File',
        root_dir   => $self->cache_path,
        expires_in => $self->cache_expiry,
        on_get_error => sub {
            my ($message, $key, $error) = @_;
            $self->log->error_msg('chi_get', $message, $key, $error);
        },
        on_set_error => sub {
            my ($message, $key, $error) = @_;
            $self->log->error_msg('chi_set', $message, $key, $error);
        },
    );

    $self->{curl} = XAS::Lib::Curl::HTTP->new();

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
