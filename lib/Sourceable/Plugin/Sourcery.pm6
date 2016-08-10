use CoreHackers::Sourcery;
unit class Sourceable::Plugin::Sourcery;
# use MONKEY-SEE-NO-EVAL;

method irc-privmsg-channel ($ where /^ 's:' \s* $<code>=.+/) {
    my $code = ~$<code>;
    is-safeish $code or return "Ehhh... I'm too scared to run that code.";
    # sourcery( EVAL $code )[1];
}

sub is-safeish ($code) {
    return if $code ~~ /<[;){]>/;
    for <run shell qx EVAL> {
        return if $code ~~ /$_/ and not $code ~~ /'"' $_ '"'/;
    }
    return True;
}
