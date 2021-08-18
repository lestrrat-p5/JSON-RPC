package t::JSON::RPC::Test::Handler::Sum;
use strict;
use Class::Accessor::Lite new => 1;

use base 'Exporter';

our @EXPORT_OK = qw( CUSTOM_ERROR_CODE );
use constant CUSTOM_ERROR_CODE => -32000;

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

sub tidy_error {
    die {
        message => "short description of the error",
        data    => "additional information about the error"
    };
}

sub custom_error {
    die {
        code => CUSTOM_ERROR_CODE,
        message => "short description of the error",
        data    => {
            some => 'data'
        }
    };
}

1;
