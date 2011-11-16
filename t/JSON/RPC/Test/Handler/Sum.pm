package t::JSON::RPC::Test::Handler::Sum;
use strict;
use Class::Accessor::Lite new => 1;

sub blowup {
    die "I blew up!";
}

sub sum {
    my ($self, $params, $proc, @args) = @_;

    $params ||= [];
    my $sum = 0;
    foreach my $p (@$params) {
        $sum += $p;
    }
    return $sum;
}

1;
