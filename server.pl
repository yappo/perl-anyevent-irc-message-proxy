#!/usr/bin/perl
# Usage: ./server.pl irc.example.com 6667 nickname '#channel1' '#channel2' '#channel3'
use strict;
use warnings;
use AnyEvent::IRC::Client;
use AnyEvent::Socket;
use AnyEvent::Handle;

my($server, $port, $nick, @channels) = @ARGV;
warn join ', ', @channels;

my $c = AE::cv;;
my $con = AnyEvent::IRC::Client->new;
$con->reg_cb (connect => sub {
    my ($con, $err) = @_;
    if (defined $err) {
        warn "connect error: $err\n";
        return;
    }
});
$con->reg_cb (registered => sub { print "I'm in!\n"; });
$con->reg_cb (disconnect => sub { print "I'm out!\n"; $c->broadcast });

warn "$server, $port";
$con->connect ($server, $port, { nick => $nick });
warn "join channel; $_" for @channels;
$con->send_srv( JOIN => $_ ) for @channels;

my $guard = tcp_server undef, 19190, sub {
    my($fh, $host, $port) = @_;

    my $handle; $handle = AnyEvent::Handle->new(
        fh => $fh,
        on_eof   => sub { undef $handle; },
        on_error => sub { undef $handle; warn $! if $! != Errno::EPIPE },
        on_timeout => sub { undef $handle; },
    );

    $handle->push_read( json => sub {
        my(undef, $json) = @_;
        return unless $json->{msg};
        warn "sent: $json->{msg}";
        $con->send_chan( $_, "NOTICE", $_, $json->{msg} ) for @channels;
    });
};
$c->recv;
#$con->disconnect;
