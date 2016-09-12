unit class Sourceable::Plugin::Sourcery;
use MONKEY-SEE-NO-EVAL;
use CoreHackers::Sourcery;

has $.executable-dir is required;
has $.core-hackers   is required;

method irc-privmsg-channel ($ where /^ 's:' \s+ $<code>=.+/) {
    my $code = ~$<code>;
    is-safeish $code or return "Ehhh... I'm too scared to run that code.";

    chdir $.executable-dir;
    my $p = run(
        :err,
        :out,  './perl6-m', '-I', $.core-hackers,
        '-e', qq:to/END/
            BEGIN \{
                \%*ENV<SOURCERY_SETTING>
                = '{$.executable-dir}gen/moar/m-CORE.setting';
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

sub is-safeish ($code) {
    return if $code ~~ /<[;{]>/;
    return if $code.comb('(') != $code.comb(')');
    for <run shell qx EVAL> -> $danger {
        return if $code ~~ /$danger/ and not $code ~~ /'"' $danger '"'/;
    }
    return True;
}
