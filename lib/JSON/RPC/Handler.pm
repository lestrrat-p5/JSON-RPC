package JSON::RPC::Handler;
use Class::Accessor::Lite
    new => 1,
;

sub execute {
    my ($self, $action, $procedure, @args) = @_;
    $self->$action( $procedure->params, $procedure, @args );
}

1;
