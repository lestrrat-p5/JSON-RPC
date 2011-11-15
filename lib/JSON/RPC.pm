package JSON::RPC;
use strict;
our $VERSION = '1.00';

1;

__END__

=head1 NAME

JSON::RPC

=head1 SYNOPSIS

    # rpc.pl
    use strict;
    use Router::Simple::Declre;
    router {
        connect "method1" => {
            handler => "HandlerClass",
            action  => "method_name"
        }
    };

    my $dispatcher = JSONRPC::Dispatcher->new(
        prefix => "MyApp::JSONRPC::Handler",
        router => do "rpc.pl", # or Router::Simple instance
    );

    # Suppose you get a request for method = "method1"
    # This below dispatches to 
    #    MyApp::JSONRPC::Handler::HandlerClass->method_name( \%params, $procedure, @extra_args )
    my $res = $dispatcher->dispatch_rpc(
        $request, # object like Plack::Request
        @extra_parameters
    );

    # $res depends on your application

=head1 IN YOUR WEBAPP

    # In your controller:
    package MyController;

    sub dispatch {
        my ($self, $c) = @_;
        my $res = $c->get('JSONRPC::Dispatcher')->dispatch_rpc( $c->request, $c );

        # if this is pickles, you need to copy the values yourself
        my $pres = $c->response;
        foreach my $field ( qw(status headers boyd) ) {
            $pres->$field( $res->$field );
        }
        # avoid rendering the view
        $c->finished(1);
    }

=cut
