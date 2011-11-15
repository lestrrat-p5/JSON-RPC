use strict;
use Test::More;
use Plack::Test;
use JSON;

use_ok "JSON::RPC::Dispatcher";

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
        prefix => 't::JSON::RPC::Test::Handler',
        router => $router,
    );
    ok $dispatcher, "dispatcher ok";

    test_psgi
        app => sub {
            my $env = shift;
            my $res = $dispatcher->dispatch_rpc(
                Plack::Request->new($env)
            );
            return $res->finalize();
        },
        client => sub {
            my $cb = shift;
            my @params = ( 1, 2, 3, 4, 5 );
            my $uri = URI->new( "http://localhost" );
            $uri->query_form(
                method => 'sum',
                params => $coder->encode(\@params)
            );

            my $req = HTTP::Request->new( GET => $uri );
            my $res = $cb->( $req );
            if (! ok $res->is_success, "response is success") {
                diag $res->as_string;
            }

            my $json = $coder->decode( $res->decoded_content );
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
};

done_testing;
