use strict;
use warnings;

use PPI;
use PPI::Dumper;

my $PRAGMAS = qr/constant|diagnostics|integer|sigtrap|strict|subs|warnings|sort/;

#my $dom = PPI::Document->new('ANN.pm', readonly => 1);
#my $dom = PPI::Document->new('DH.pm', readonly => 1);
#my $dom = PPI::Document->new('../lib/XAS/Darkpan/Process.pm', readonly => 1);
#my $dom = PPI::Document->new('Release.pm', readonly => 1);
#my $dom = PPI::Document->new('SocketTest.pm', readonly => 1);
#my $dom = PPI::Document->new('Set.pm', readonly => 1);
my $dom = PPI::Document->new('NNFlex.pm', readonly => 1);
#my $dom = PPI::Document->new('/home/kevin/dev/XAS/trunk/lib/XAS/Lib/Stomp/Frame.pm', readonly => 1);

my $token = $dom->first_token;

do {

    if ($token->isa('PPI::Token::Word')) {

        if ($token->content eq 'package') {

            parse_package(\$token);

        } elsif (($token->content eq 'use') ||
                 ($token->content eq 'require')) {

            parse_module(\$token);

        }

    } elsif ($token->isa('PPI::Token::Symbol')) {

        if ($token->content =~ /\$(?:\w+::)*VERSION/) {

            parse_version(\$token);

        } elsif ($token->content =~ /\@ISA/) {

            parse_isa(\$token);

        }

    }

} while ($token = $token->next_token);

# ----------------------------------------------------------------------


sub parse_version {
    my $token = shift;

    my $version = '0';

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

    check_previous($token, 'our');

    while ($$token = $$token->next_token) {

#printf("parse_version - ref: %s, content: %s\n", ref($$token), $$token->content);

        if ($$token->isa('PPI::Token::Operator')) {

            goto_eos($token) if (($$token->content ne '=') &&
                                 ($$token->content ne '->'));

        } elsif ($$token->isa('PPI::Token::Quote')) {

            $version = get_quoted($token);
            printf("version: %s\n", $version);
            goto_eos($token);

        } elsif ($$token->isa('PPI::Token::Number')) {

            $version = get_number($token);
            printf("version: %s\n", $version);
            goto_eos($token);

        }

        last if check_eos($token);

    }

}

sub parse_isa {
    my $token = shift;

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

    check_previous($token, 'use');

    while ($$token = $$token->next_token) {

#printf("parse_isa - ref: %s, content: %s\n", ref($$token), $$token->content);

        if ($$token->isa('PPI::Token::Quote')) {

            $module = get_quoted($token);

            printf("module : %s, version: %s\n", $module, $version);

        } elsif ($$token->isa('PPI::Token::QuoteLike::Words')) {

            my @datum = $$token->literal; 

            foreach my $data (@datum) {

                printf("module : %s, version: %s\n", $data, $version);

            }

        }

        last if check_eos($token);

    }

}

sub parse_package {
    my $token = shift;

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

        if ($$token->isa('PPI::Token::Word')) {

            $package = $$token->content;

        } elsif ($$token->isa('PPI::Token::Number')) {

            $version = $$token->content;

        } elsif ($$token->isa('PPI::Token::Structure')) {

            last if ($$token->content eq '{');

        }

        last if check_eos($token);

    }

    printf("package: %s\n", $package);

}

sub parse_module {
    my $token = shift;

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

    check_previous($token, 'use');

    while ($$token = $$token->next_token) {

#printf("get_module - ref: %s, content: %s\n", ref($$token), $$token->content);

        if ($$token->isa('PPI::Token::Word')) {

            return parse_isa($token) if ($$token->content eq 'base');
            return parse_isa($token) if ($$token->content eq 'parent');

            $module = $$token->content if ($module eq '');
            goto_eos($token) if ($$token->content =~ $PRAGMAS);

        } elsif ($$token->isa('PPI::Token::Number')) {

            $version = get_number($token);
            goto_eos($token);

        }

        last if check_eos($token);

    }

    $module = 'perl' if ($module eq '');

    printf("module : %s, version: %s\n", $module, $version);

}

sub get_quoted {
    my $token = shift;

    if ($$token->can('literal')) {

        return $$token->literal;

    } else {

        return  $$token->string;

    }

}

sub get_number {
    my $token = shift;

    if ($$token->can('literal')) {

        return $$token->literal;

    } else {

        return $$token->content;

    }

}

sub goto_eos {
    my $token = shift;

    while ($$token = $$token->next_token) {

        last if check_eos($token);

    }

    $$token = $$token->previous_token;

}

sub check_eos {
    my $token = shift;

    return (($$token->isa('PPI::Token::Structure')) &&
            ($$token->content eq ';'));

}

sub check_previous {
    my $token = shift;
    my $wanted = shift;

    if (my $t = $$token->sprevious_sibling) {
#printf("check_previous - last: %s, content: %s\n", ref($t), $t->content);

        goto_eos($token) if ($t->content eq '');
        goto_eos($token) if ($t->content ne $wanted);

    }

}
    