package JSON::RPC::Procedure;
use strict;
use Carp ();
use Class::Accessor::Lite
    new => 1,
    rw => [ qw(
        id
        method
        params
    ) ]
;

1;
