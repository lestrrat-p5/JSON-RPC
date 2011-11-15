use strict;
use Test::More;
use Plack::Test;
use JSON;

use_ok "JSON::RPC::Dispatcher";

subtest 'defaults' => sub {
    my $dispatcher = JSON::RPC::Dispatcher->new();
    if (ok $dispatcher->coder) {
        isa_ok $dispatcher->coder, 'JSON';
    }

    if (ok $dispatcher->router) {
        isa_ok $dispatcher->router, "Router::Simple";
    }

    if (ok $dispatcher->parser) {
        isa_ok $dispatcher->parser, "JSON::RPC::Parser";
    }
};

subtest 'normal disptch' => sub {
    my $coder = JSON->new;
    my $router = Router::Simple->new;
    $router->connect( blowup => {
        handler => "Sum",
        action  => "blowup",
    } );
    $router->connect( 'sum' => {
        handler => 'Sum',
        action => 'sum',
    } );
    my $dispatcher = JSON::RPC::Dispatcher->new(
        coder  => $coder,
        parser => JSON::RPC::Parser->new( coder => $coder ),
        prefix => 't::JSON::RPC::Test::Handler',
        router => $router,
    );
    ok $dispatcher, "dispatcher ok";

    for my $raw_env ( 0..1 ) {
        test_psgi
            app => sub {
                my $env = shift;
                my $req = $raw_env ? $env : Plack::Request->new($env);
                my $res = $dispatcher->dispatch_rpc( $req );
                return $res->finalize();
            },
            client => sub {
                my $cb = shift;

                my ($req, $res, $json);
                my $uri = URI->new( "http://localhost" );

                # no such method...
                $uri->query_form(
                    method => 'not_found'
                );
                $req = HTTP::Request->new( GET => $uri );
                $res = $cb->( $req );
                if (! ok $res->is_success, "response is success") {
                    diag $res->as_string;
                }

                $json = $coder->decode( $res->decoded_content );
                if ( ! ok $json->{error}, "I should have gotten an error" ) {
                    diag explain $json;
                }

                if (! is $json->{error}->{code}, JSON::RPC::Constants::RPC_METHOD_NOT_FOUND(), "code is RPC_METHOD_NOT_FOUND" ) {
                    diag explain $json;
                }

                my @params = ( 1, 2, 3, 4, 5 );
                $uri->query_form(
                    method => 'sum',
                    params => $coder->encode(\@params)
                );

                $req = HTTP::Request->new( GET => $uri );
                $res = $cb->( $req );
                if (! ok $res->is_success, "response is success") {
                    diag $res->as_string;
                }

                $json = $coder->decode( $res->decoded_content );
                if (! ok ! $json->{error}, "no errors") {
                    diag explain $json;
                }

                my $sum = 0;
                foreach my $p (@params) {
                    $sum += $p;
                }
                is $json->{result}, $sum, "sum matches";

                my $id = time();
                $uri->query_form(
                    jsonrpc => '2.0',
                    id     => $id,
                    method => 'blowup',
                    params => "fuga",
                );
                $req = HTTP::Request->new( GET => $uri  );
                $res = $cb->( $req );
                if (! ok $res->is_success, "response is success") {
                    diag $res->as_string;
                }

                $json = $coder->decode( $res->decoded_content );
                is $json->{jsonrpc}, '2.0';
                is $json->{id}, $id;
                ok $json->{error};
            }
        ;
    }
};

done_testing;
