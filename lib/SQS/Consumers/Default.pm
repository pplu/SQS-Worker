package SQS::Consumers::Default;
use Moose;
use namespace::autoclean;

has worker => (is => 'ro', isa => 'SQS::Worker', required => 1);

sub fetch_message {
    my $self = shift;
    my $worker = $self->worker;

    $worker->log->debug('Receiving Messages');

    my $message_pack = $worker->sqs->ReceiveMessage(
        WaitTimeSeconds => 20,
        QueueUrl => $worker->queue_url,
        MaxNumberOfMessages => 1
        );

    $worker->log->debug(sprintf "Got %d messages", scalar(@{ $message_pack->Messages }));

    foreach my $message (@{$message_pack->Messages}) {
        $worker->log->info("Processing message " . $message->ReceiptHandle);
        eval {
            $worker->process_message($message);
        };

        if ($@) {
            $worker->log->error("Exception caught: " . $@);
            $worker->on_failure->($worker, $message);
        } else {
            # If all went well we have to delete the message from the queue
            $worker->sqs->DeleteMessage(
                QueueUrl      => $worker->queue_url,
                ReceiptHandle => $message->ReceiptHandle,
                );
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
