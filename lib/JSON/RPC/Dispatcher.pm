package JSON::RPC::Dispatcher;
use strict;
use JSON::RPC::Constants qw(:all);
use JSON::RPC::Parser;
use JSON::RPC::Procedure;
use Class::Load ();
use Router::Simple;
use Try::Tiny;
use JSON::XS;

use Class::Accessor::Lite
    rw => [ qw(
        coder
        handlers
        parser
        prefix
        router
    ) ]
;

sub new {
    my ($class, @args) = @_;
    my $self = bless {
        handlers => {},
        @args,
    }, $class;
    if (! $self->{coder}) {
        require JSON;
        $self->{coder} = JSON->new->utf8;
    }
    if (! $self->{parser}) {
        $self->{parser} = JSON::RPC::Parser->new( coder => $self->coder )
    }
    if (! $self->{router}) {
        $self->{router} = Router::Simple->new;
    }
    return $self;
}

sub guess_handler_class {
    my ($self, $klass) = @_;

    my $prefix = $self->prefix || '';
    return "$prefix\::$klass";
}

sub construct_handler {
    my ($self, $klass) = @_;

    my $handler = $self->handlers->{ $klass };
    if (! $handler) {
        Class::Load::load_class( $klass );
        $handler = $klass->new();
        if (! $handler->isa( 'JSON::RPC::Handler' ) ) {
            Carp::croak( "$klass does not implement JSON::RPC::Handler" );
        }
        $self->handlers->{$klass} = $handler;
    }
    return $handler;
}

sub get_handler {
    my ($self, $klass) = @_;

    if ($klass !~ s/^\+//) {
        $klass = $self->guess_handler_class( $klass );
    }

    my $handler = $self->construct_handler( $klass );
    if (JSONRPC_DEBUG > 1) {
        warn "$klass -> $handler";
    }
    return $handler;
}

sub dispatch_rpc {
    my ($self, $req, @args) = @_;

    my @response;
    my $procedures;
    try {
        $procedures = $self->parser->construct_from_req( $req );
        if (@$procedures <= 0) {
            push @response, {
                error => {
                    code => RPC_INVALID_REQUEST,
                    message => "Could not find any procedures"
                }
            };
        }
    } catch {
        my $e = $_;
        if (JSONRPC_DEBUG) {
            warn "error while creating jsonrpc request: $e";
        }
        if ($e =~ /Invalid parameter/) {
            push @response, {
                error => {
                    code => RPC_INVALID_PARAMS,
                    message => "Invalid parameters",
                }
            };
        } elsif ( $e =~ /Parse error/ ) {
            push @response, {
                error => {
                    code => RPC_PARSE_ERROR,
                    message => "Failed to parse json",
                }
            };
        } else {
            push @response, {
                error => {
                    code => RPC_INVALID_REQUEST,
                    message => $e
                }
            }
        }
    };

    my $router = $self->router;
    foreach my $procedure (@$procedures) {
        if ( ! $procedure->{method} ) {
            my $message = "Procedure name not given";
            if (JSONRPC_DEBUG) {
                warn $message;
            }
            push @response, {
                error => {
                    code => RPC_METHOD_NOT_FOUND,
                    message => $message,
                }
            };
            next;
        }

        my $matched = $router->match( $procedure->{method} );
        if (! $matched) {
            my $message = "Procedure '$procedure->{method}' not found";
            if (JSONRPC_DEBUG) {
                warn $message;
            }
            push @response, {
                error => {
                    code => RPC_METHOD_NOT_FOUND,
                    message => $message,
                }
            };
            next;
        }

        my $action = $matched->{action};
        try {
            if (JSONRPC_DEBUG > 1) {
                warn "Procedure '$procedure->{method}' maps to action $action";
            }

            my $ip = $req->address;
            my $ua = $req->user_agent;
            my $params = $procedure->params;
            my $handler = $self->get_handler( $matched->{handler} );
            my $result = $handler->execute( $action, $procedure, @args );
            warn "[INFO] action=$action "
                . "params=["
                . (ref $params ? encode_json($params) : $params)
                . "] ret="
                . (ref $result ? encode_json($result) : $result)
                . " IP=$ip UA=$ua";

            push @response, {
                jsonrpc => '2.0',
                result  => $result,
                id      => $procedure->id,
            };
        } catch {
            my $e = $_;
            if (JSONRPC_DEBUG) {
                warn "Error while executing $action: $e";
            }
            push @response, {
                jsonrpc => '2.0',
                id => $procedure->id,
                error => {
                    code => RPC_INTERNAL_ERROR,
                    message => $e,
                }
            };
        };
    }
    my $res = $req->new_response(200);
    $res->content_type( 'application/json; charset=utf8' );
    $res->body(
        $self->coder->encode( @$procedures > 1 ? \@response : $response[0] )
    );

    return $res;
}

no Try::Tiny;

1;

