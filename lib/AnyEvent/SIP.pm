use strict;
use warnings;
package AnyEvent::SIP;
# ABSTRACT: Fusing together AnyEvent and Net::SIP

use Net::SIP::Dispatcher::AnyEvent;
use Net::SIP::Dispatcher::Eventloop;

{
    no warnings qw<redefine once>;
    *Net::SIP::Dispatcher::Eventloop::new = sub {
        Net::SIP::Dispatcher::AnyEvent->new
    };
}

1;

__END__

=head1 SYNOPSIS

    use SNMP::AnyEvent;

    my $cv   = AE::cv;
    my $ua   = Net::SIP::Simple->new(...);
    my $call = $uac->invite(
        'you.uas@example.com',
        cb_final => sub { $cv->send },
    );

    $cv->recv;

=head1 DESCRIPTION

This module allows you to use L<AnyEvent> as the event loop (and thus any
other supported event loop) for L<Net::SIP>.

L<Net::SIP::Simple> allows you to define the event loop. You can either define
it using L<Net::SIP::Dispatcher::AnyEvent> manually or you can simply use
L<AnyEvent::SIP> which will automatically set it for you.

    # doing it automatically and globally
    use AnyEvent::SIP;
    use Net::SIP::Simple;

    my $cv = AE::cv;
    my $ua = Net::SIP::Simple->new(...);
    $ua->register( cb_final => sub { $cv->send } );
    $cv->recv;

    # defining it for a specific object
    use Net::SIP::Simple;
    use Net::SIP::Dispatcher::AnyEvent;

    my $cv = AE::cv;
    my $ua = Net::SIP::Simple->(
        ...
        loop => Net::SIP::Dispatcher::AnyEvent->new,
    );

    $ua->register;
    $cv->recv;

You can also call L<Net::SIP>'s C<loop> method in order to keep it as close as
possible to the original syntax. This will internally use L<AnyEvent>, whether
you're using L<AnyEvent::SIP> globally or L<Net::SIP::Dispatcher::AnyEvent>
locally.

    use AnyEvent::SIP;
    use Net::SIP::Simple;

    my $stopvar;
    my $ua = Net::SIP::Simple->new(...);
    $ua->register( cb_final => sub { $stopvar++ } );

    # call Net::SIP's event loop runner,
    # which calls AnyEvent's instead
    $ua->loop( 1, \$stopvar );

