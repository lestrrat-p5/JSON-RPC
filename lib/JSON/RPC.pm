package JSON::RPC;
use strict;
our $VERSION = '0.04';

1;

__END__

=head1 NAME

JSON::RPC - JSON RPC 2.0 Server Implementation

=head1 SYNOPSIS

    # app.psgi
    use strict;
    use JSON::RPC::Dispatcher;

    my $dispatcher = JSON::RPC::Dispatcher->new(
        prefix => "MyApp::JSONRPC::Handler",
        router => Router::Simple->new( ... )
    );

    sub {
        my $env = shift;
        $dispatcher->handle_psgi($env);
    };

=head1 DESCRIPTION

JSON::RPC is a set of modules that implment JSON RPC 2.0 protocol.

=head1 BASIC USAGE

The dispatcher is responsible for marshalling the request.

The routing between the JSON RPC methods and their implementors are handled by
Router::Simple. For example, if you want to map method "foo" to a "MyApp::JSONRPC::Handler" object instance's "handle_foo" method, you specify something like the following in your router instance:

    use Router::Simple::Declare;
    my $router = router {
        connect "foo" => {
            handler => "+MyApp::JSONRPC::Handler",
            action  => "handle_foo"
        };
    };

The "+" prefix in the handler classname denotes that it is already a fully qualified classname. Without the prefix, the value of "prefix" in the dispatcher object will be used to qualify the classname.

The implementors are called handlers. Handlers are simple objects, and will be instantiated automatically for you. Their return values are converted to JSON objects automatically.

You may also choose to pass objects in the handler argument to connect in  your router. This will save you the cost of instantiating the handler object, and you also don't have to rely on us instantiating your handler object.

    use Router::Simple::Declare;
    use MyApp::JSONRPC::Handler;

    my $handler = MyApp::JSONRPC::Handler->new;
    my $router = router {
        connect "foo" => {
            handler => $handler,
            action  => "handle_foo"
        };
    };

=head1 EMBED IT IN YOUR WEBAPP

If you already have a web app (and whatever framework you might already have), you may choose to embed JSON::RPC in your webapp instead of directly calling it in your PSGI application.

For example, if you would like to your webapp's "rpc" handler to marshall the JSON RPC request, you can do something like the following:

    package MyApp;
    use My::Favorite::WebApp;

    sub rpc {
        my ($self, $context) = @_;

        my $dispatcher =  ...; # grab it from somewhere
        $dispatcher->handle_psgi( $context->env );
    }

=head1 BACKWARDS COMPATIBILITY

Eh, not compatible at all. JSON RPC 0.xx was fine, but it predates PSGI, and things are just... different before and after PSGI.

Code at version 0.96 has been moved to JSON::RPC::Legacy namespace, so change your application to use JSON::RPC::Legacy if you were using the old version.

=head1 AUTHORS

Daisuke Maki

Shinichiro Aska

Yoshimitsu Torii

=head1 AUTHOR EMERITUS

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt> - JSON::RPC modules up to 0.96

=cut
