# ABSTRACT: manages workers reading from an SQS queue
package SQS::Worker::DefaultLogger;
  use Moose;
  sub _print { print sprintf "[%s] %s %s\n", @_ };
  sub debug { shift->_print('DEBUG', @_) }
  sub error { shift->_print('ERROR', @_) }
  sub info  { shift->_print('INFO', @_) }
1;
package SQS::Worker;
  use Paws;
  use Moose::Role;
  use Data::Dumper;

  our $VERSION = '0.01';

  requires 'process_message';

  has queue_url => (is => 'ro', isa => 'Str', required => 1);
  has region => (is => 'ro', isa => 'Str', required => 1);

  has sqs => (is => 'ro', isa => 'Paws::SQS', lazy => 1, default => sub {
    my $self = shift;
    Paws->service('SQS', region => $self->region);
  });

  has log => (is => 'ro', default => sub { SQS::Worker::DefaultLogger->new });

  has on_failure => (is => 'ro', isa => 'CodeRef', default => sub {
    my ($self, $message) = @_;
    $self->log->error("Error processing message " . $message->ReceiptHandle);
    $self->log->debug("Message Dump " . Dumper($message));
  });

  sub run {
    my $self = shift;
    while (1) {
      $self->log->debug('Receiving Messages');

      my $message_pack = $self->sqs->ReceiveMessage(
        WaitTimeSeconds => 20,
        QueueUrl => $self->queue_url,
        MaxNumberOfMessages => 1
      );

      $self->log->debug(sprintf "Got %d messages", scalar(@{ $message_pack->Messages }));
      
      foreach my $message ($message_pack->Messages) {
        $self->log->info("Processing message " . $self->ReceiptHandle);
        eval {
          $self->process_message($message);
        };

        if ($@) {
          $self->on_failure->($self, $message);
        } else {
          # If all went well we have to delete the message from the queue
          $self->sqs->DeleteMessage(
            QueueUrl      => $self->queue_name,
            ReceiptHandle => $message->ReceiptHandle,
          );
        }
      }
    }
  }

1;
