# ABSTRACT: manages workers reading from an SQS queue
package SQS::Worker;
  use Paws;
  use Moose::Role;
  use Data::Dumper;

  our $VERSION = '0.03';

  requires 'process_message';

  has queue_url => (is => 'ro', isa => 'Str', required => 1);
  has region => (is => 'ro', isa => 'Str', required => 1);

  has sqs => (is => 'ro', isa => 'Paws::SQS', lazy => 1, default => sub {
    my $self = shift;
    Paws->service('SQS', region => $self->region);
  });

  has log => (is => 'ro', required => 1);

  has on_failure => (is => 'ro', isa => 'CodeRef', default => sub {
    return sub {
      my ($self, $message) = @_;
      $self->log->error("Error processing message " . $message->ReceiptHandle);
      $self->log->debug("Message Dump " . Dumper($message));
    }
  });

  sub fetch_message {
    my $self = shift;

    $self->log->debug('Receiving Messages');

    my $message_pack = $self->sqs->ReceiveMessage(
      WaitTimeSeconds => 20,
      QueueUrl => $self->queue_url,
      MaxNumberOfMessages => 1
    );

    $self->log->debug(sprintf "Got %d messages", scalar(@{ $message_pack->Messages }));
    
    foreach my $message (@{$message_pack->Messages}) {
      $self->log->info("Processing message " . $message->ReceiptHandle);
      eval {
        $self->process_message($message);
      };

      if ($@) {
        $self->log->error("Exception caught: " . $@);
        $self->on_failure->($self, $message);
      } else {
        # If all went well we have to delete the message from the queue
        $self->sqs->DeleteMessage(
          QueueUrl      => $self->queue_url,
          ReceiptHandle => $message->ReceiptHandle,
        );
      }
    }
  }

  sub run {
    my $self = shift;
    while (1) {
      $self->fetch_message;
    }
  }

1;

=head1 NAME

SQS::Worker

=head1 DESCRIPTION

This role is to be composed into the end user code that want to receive messages from an SQS queue. 

The worker is running uninterrumped, fetching messages from it's configured queue, one at a time and then executing the process_message
of the consuming class.

The worker consumer can compose further funcionality by consuming more roles from the SQS::Worker namespace.

=head1 USAGE

Simple usage

	package MyConsumer;

	use Moose;
	with 'SQS::Worker';

	sub process_message {
		my ($self,$message) = @_;

		# do something with the message
	}

Composing automatic json decoding to perl data structure

	package MyConsumer;

	use Moose;
	with 'SQS::Worker', 'SQS::Worker::DecodeJson';

	sub process_mesage {
		my ($self, $data) = @_;
		
		# Do something with the data, already parsed into a structure
		my $name = $data->{name};
	}
