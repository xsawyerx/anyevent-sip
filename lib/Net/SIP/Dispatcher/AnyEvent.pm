use strict;
use warnings;
package Net::SIP::Dispatcher::AnyEvent;
# ABSTRACT: AnyEvent dispatcher for Net::SIP

use AnyEvent;
use AnyEvent::AggressiveIdle;
use Net::SIP::Dispatcher::AnyEvent::Timer;
use Net::SIP::Util 'invoke_callback';

sub new {
    my $class = shift;
    my $self  = bless { _cv => AE::cv }, $class;

    $self->{'_idle'} = aggressive_idle {
        exists $self->{'_stopvar'} or return;
        foreach my $var ( @{ $self->{'_stopvar'} } ) {
            if ( ${$var} ) {
                delete $self->{'_stopvar'};
                $self->{'_cv'}->send;
            }
        }
    };

    return $self;
}

sub addFD {
    my $self = shift;
    my ( $fh, $cb_data, $name ) = @_;

    my $fn = fileno $fh or return;

    $self->{'_fd_watchers'}{$fn} = AE::io $fh, 0, sub {
        invoke_callback( $cb_data, $fh );
    }
}

sub delFD {
    my $self = shift;
    my $fh   = shift;
    my $fn   = fileno $fh or return;

    delete $self->{'_fd_watchers'}{$fn};
}

sub add_timer {
    my $self = shift;
    my ( $when, $cb_data, $repeat, $name ) = @_;
    defined $repeat or $repeat = 0;

    # is $when epoch or relative?
    if ( $when >= 3600*24*365 ) {
        $when = AE::now - $when;
    }

    return Net::SIP::Dispatcher::AnyEvent::Timer->new(
        $name, $when, $repeat, $cb_data
    );
}

sub looptime { AE::now }

sub loop {
    my $self = shift;
    my ( $timeout, @stopvar ) = @_;

    $self->{'_stopvar'} = \@stopvar;

    if ($timeout) {
        my $timer; $timer = AE::timer $timeout, 0, sub {
            undef $timer;
            $self->{'_cv'}->send;
        };
    }

    $self->{'_cv'}->recv;

    # clean up, prepare for another round
    $self->{'_cv'} = AE::cv;
}

1;

__END__

=head1 DESCRIPTION

This module allows L<Net::SIP> to work with L<AnyEvent> as the event loop,
instead of its own event loop. This means you can combine them.

While this is the implementation itself, you probably want to use
L<AnyEvent::SIP> instead. You definitely want to read the documentation there
instead of here. Go ahead, click the link. :)

The rest only documents how the loop implementation works. If you use this
directly, the only method you care about is C<loop>.

=head1 WARNING

C<Net::SIP> requires dispatchers (event loops) to check their stopvars
(condition variables) every single iteration of the loop. In my opinion, it's
a wasteful and heavy operation. When it comes to loops like L<EV>, they run
a B<lot> of cycles, and it's probably not very effecient. Take that under
advisement.

I would happily accept any suggestions on how to improve this. Meanwhile,
we're using L<AnyEvent::AggressiveIdle>.

=head1 INTERNAL ATTRIBUTES

These attributes have no accessors, they are saved as intenral keys.

=head2 _idle

Hold the L<AnyEvent::AggressiveIdle> object that checks stopvars.

=head2 _stopvar

Condition variables to be checked for stopping the loop.

=head2 _cv

Main condition variable allowing for looping.

=head2 _fd_watchers

All the watched file descriptors.

=head1 METHODS

=head2 new

The object constructor. It creates a default CondVar in C<_cv> hash key,
and sets an aggressive idle CondVar in the C<_idle> hash key, which checks
the stopvars every loop cycle.

=head2 addFD($fd, $cb_data, [$name])

Add a file descriptor to watch input for, and a callback to run when it's ready
to be read.

=head2 delFD($fd)

Delete the watched file descriptor.

=head2 add_timer($when, $cb_data, [$repeat])

Create a timer to run a callback at a certain point in time. If the point
in time is rather large (3,600 * 24 * 365 and up), it's a specific point in
time. Otherwise, it's a number of seconds from now.

The C<repeat> option is an optional interval for the timer.

=head2 looptime

Provide the event loop time.

=head2 loop($timeout, [\@stopvars])

Run the event loop and wait for all events to finish (whether by timeout or
stopvars becoming true).

