use strict;
use warnings;
package Net::SIP::Dispatcher::AnyEvent::Timer;
# ABSTRACT: A timer object for Net::SIP::Dispatcher::AnyEvent

use AnyEvent;
use Net::SIP::Util 'invoke_callback';

sub new {
    my $class = shift;
    my ( $name, $when, $repeat, $cb ) = @_;
    my $self  = bless {}, $class;

    $self->{'timer'} = AE::timer $when, $repeat, sub {
        invoke_callback( $cb, $self );
    };

    return $self;
}

sub cancel {
    my $self = shift;
    delete $self->{'timer'};
}

1;

__END__

=head1 DESCRIPTION

The timer object L<Net::SIP::Dispatcher::AnyEvent> creates when asked for a
new timer.

=head1 INTERNAL ATTRIBUTES

These attributes are saved in a hash key and have no accessors.

=head2 timer

The actual timer object

=head1 METHODS

=head2 new($when, $cb, $repeat)

A constructor creating the new timer. You set when to start, the callback and
how often to repeat.

=head2 cancel

Cancel the timer.

