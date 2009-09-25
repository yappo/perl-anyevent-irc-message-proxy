#!/usr/bin/perl
# Usage: ./client.pl 'sent message'
use strict;
use warnings;
use AnyEvent::Handle;
use AnyEvent::Socket;

my $msg = shift;
my $c = AE::cv;
my $guard = tcp_connect 'localhost', 19190 => sub {
    my $fh = shift;
    my $handle; $handle = AnyEvent::Handle->new( fh => $fh );
    $handle->push_write( json => { msg => $msg } );
    $c->send;
};
$c->recv;
