package SQS::Consumers::Default;
use Moose;
use namespace::autoclean;

has worker => (is => 'ro', isa => 'SQS::Worker', required => 1);

sub fetch_message {
    my $self = shift;

    $self->worker->log->debug('Receiving Messages');
    my $message_pack = $self->worker->receive_message();

    $self->worker->log->debug(sprintf "Got %d messages", scalar(@{ $message_pack->Messages }));

    foreach my $message (@{$message_pack->Messages}) {
        $self->worker->log->info("Processing message " . $message->ReceiptHandle);
        eval {
            $self->worker->process_message($message);
        };

        if ($@) {
            $self->worker->log->error("Exception caught: " . $@);
            $self->worker->on_failure->($self->worker, $message);
        } else {
            # If all went well we have to delete the message from the queue
            $self->worker->delete_message($message);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
