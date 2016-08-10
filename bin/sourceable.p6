#!/usr/bin/env perl6
use lib <
    /home/zoffix/CPANPRC/IRC-Client/lib
    /home/zoffix/services/lib/IRC-Client/lib
    lib
>;

use IRC::Client;
use Sourceable::Plugin::Sourcery;

class Sourceable::Info {
    multi method irc-to-me ($ where /^\s* help \s*$/) {
        "Use s: trigger with args to give to sourcery sub."
        ~ " e.g. s: Int, 'base'. See"
        ~ " http://modules.perl6.org/dist/CoreHackers::Sourcery";
    }
    multi method irc-to-me ($ where /^\s* source \s*$/) {
        "See: https://github.com/zoffixznet/perl6-sourceable";
    }

    multi method irc-to-me ($ where /'bot' \s* 'snack'/) { "om nom nom nom"; }
}

.run with IRC::Client.new:
    :nick<sourceable>,
    :host(%*ENV<SOURCEABLE_IRC_HOST> // 'irc.freenode.net'),
    :channels( %*ENV<SOURCEABLE_DEBUG> ?? '#zofbot' !! |<#perl6  #perl6-dev  #zofbot>),
    :debug,
    :plugins(
        Sourceable::Info.new,
        Sourceable::Plugin::Sourcery.new,
    );
