use strict;
use warnings;

use PPI;
use PPI::Dumper;

#my $dom = PPI::Document->new('ANN.pm', readonly => 1);
#my $dom = PPI::Document->new('DH.pm', readonly => 1);
#my $dom = PPI::Document->new('../lib/XAS/Darkpan/Process.pm', readonly => 1);
#my $dom = PPI::Document->new('Release.pm', readonly => 1);
#my $dom = PPI::Document->new('SocketTest.pm', readonly => 1);
my $dom = PPI::Document->new('Set.pm', readonly => 1);

foreach my $element ($dom->elements) {

    if ($element->isa('PPI::Statement::Package')) {

        printf("PACKAGE = %s\n", $element->namespace);
        next;

    } elsif ($element->isa('PPI::Statement::Include')) {

        printf("module = %s, version = %s\n", $element->module, $element->module_version || '0.0');
        next;

    } elsif ($element->isa('PPI::Statement')) {

        if ($element->content =~ /\$(?:\w+::)*VERSION/) {

            my $version;
            my @tokens = $element->tokens;

            foreach my $token (@tokens) {

                if ($token->isa('PPI::Token::Symbol')) {

                    last if ($token->content !~ /\$(?:\w+::)*VERSION/);

                    $version = get_version($token);
                    printf("version = %s\n", $version);
                    last;

                }

            }

        }

    }

}

sub get_version {
    my $token = shift;

    # a VERSION could have the following:
    #
    # our $VERSION = '0.01';
    #
    # which would parse out to be:
    #
    # word,whitespace,symbol,whitespace,operator,quote|number,structure
    #
    # or
    #
    # $VERSION = '0.01';
    #
    # which would parse out to be:
    #
    # symbol,whitespace,operator,quote|number,structure
    #

    do {

        if ($token->isa('PPI::Token::Word')) {

            return 'undef' if ($token->content ne 'our');

        } elsif ($token->isa('PPI::Token::Operator')) {

            return 'undef' if ($token->content ne '=');

        } elsif ($token->isa('PPI::Token::Quote')) {

            if ($token->can('literal')) {

                return $token->literal;

            } else {

                return $token->string;

            }

        } elsif ($token->isa('PPI::Token::Number')) {

            if ($token->can('literal')) {

                return $token->literal;

            } else {

                return $token->content;

            }

        } elsif ($token->isa('PPI::Token::Structure')) {

            return 'undef';

        }

    } while ($token = $token->next_token);

}

