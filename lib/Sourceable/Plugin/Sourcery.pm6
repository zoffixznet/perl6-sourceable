unit class Sourceable::Plugin::Sourcery;
use MONKEY-SEE-NO-EVAL;
use JSON::Fast;
use CoreHackers::Sourcery;

%*ENV<RAKUDO_ERROR_COLOR> = 0;

has $.executable-dir is required;
has $.core-hackers   is required;

subset NonBlocked where sub ($user) {
    my @blocked = |from-json "/home/zoffix/services/sourceable/blocked.json".IO.slurp;
    for @blocked -> $b {
        return False if
               ($b<host> andthen $_ eq $user.host)
            or ($b<nick> andthen $_ eq $user.nick);
    }
    True;
};

method irc-privmsg-channel (NonBlocked $e where /^ 's:' \s+ $<code>=.+/) {
    my $code = ~$<code>;
    unless $e.host eq 'unaffiliated/zoffix' | 'perl6.party' {
        is-safeish $code or return "Ehhh... I'm too scared to run that code.";
    }
    indir $.executable-dir, sub {
        my $p = run(
            :err,
            :out,  './perl6-m', '-I', $.core-hackers,
            '-e', qq:to/END/
                BEGIN \{
                    \%*ENV<SOURCERY_SETTING>
                    = '{$.executable-dir}gen/moar/CORE.setting';
                \};
                use CoreHackers::Sourcery;
                put sourcery( $code )[1];
            END
        );
        my $result = $p.out.slurp-rest;
        my $merge = $result ~ "\nERR: " ~ $p.err.slurp-rest;
        return "Something's wrong: $merge.subst("\n", '␤', :g)"
            unless $result ~~ /github/;

        return "Sauce is at $result";
    }
}

method irc-addressed (NonBlocked $e where /^ :i 'qast' \s+ $<code>=.+/) {
    my $code = ~$<code>;
    indir $.executable-dir, sub {
        my $p = run :err, :out,  './install/bin/nqp', '-e', QAST-box $code;
        my $result = $p.out.slurp: :close;
        my $merge = $result ~ "\nERR: " ~ $p.err.slurp: :close;
        return "Something's wrong: $merge.subst("\n", '␤', :g)"
            unless $result ~~ /github/;

        return "Sauce is at $result";
    }
}

sub is-safeish ($code) {
    return if $code ~~ /<[;{]>/;
    return if $code.comb('(') != $code.comb(')');
    for <run shell qx EVAL> -> $danger {
        return if $code ~~ /«$danger»/
    }
    return True;
}

sub QAST-box ($code) {
    return Q:to/END/.subst: 'INSERT-CODE-HERE', $code
        #!/usr/bin/env nqp
        use NQPHLL;
        grammar Perl7::Grammar is HLL::Grammar {
            token TOP { ^ .* $ }
        }
        grammar Perl7::Actions is HLL::Actions {
            method TOP($/) {
                make INSERT-CODE-HERE
            }
        }

        class Perl7::Compiler is HLL::Compiler {
            method eval($code, *@_args, *%adverbs) {
                my $output := self.compile($code, :compunit_ok, |%adverbs);
                if %adverbs<target> eq '' {
                    my $outer_ctx := %adverbs<outer_ctx>;
                    $output := self.backend.compunit_mainline($output);
                    if nqp::defined($outer_ctx) {
                        nqp::forceouterctx($output, $outer_ctx);
                    }
                    $output := $output();
                }
                $output;
            }
        }
        sub MAIN (*@ARGS) {
            my $comp := Perl7::Compiler.new;
            $comp.language('Perl7');
            $comp.parsegrammar(Perl7::Grammar);
            $comp.parseactions(Perl7::Actions);
            $comp.command_line(@ARGS, :encoding<utf8>);
        }
    END
}
