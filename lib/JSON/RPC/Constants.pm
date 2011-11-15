package JSON::RPC::Constants;
use strict;
use parent qw(Exporter);

our @EXPORT_OK = qw(
    JSONRPC_DEBUG
    RPC_PARSE_ERROR
    RPC_INVALID_REQUEST
    RPC_METHOD_NOT_FOUND
    RPC_INVALID_PARAMS
    RPC_INTERNAL_ERROR
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my %constants;
BEGIN {
    %constants = (
        JSONRPC_DEBUG     => $ENV{JSONRPC_DEBUG} ? 1 : 0,
        RPC_PARSE_ERROR      => -32700,
        RPC_INVALID_REQUEST  => -32600,
        RPC_METHOD_NOT_FOUND => -32601,
        RPC_INVALID_PARAMS   => -32602,
        RPC_INTERNAL_ERROR   => -32603,
    );
    require constant;
    constant->import( \%constants );
}

1;
