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

  has processor => (is => 'ro', lazy => 1, default => sub {
      my $self = shift;
      return SQS::Consumers::Default(worker => $self);
  });

  sub fetch_message {
    my $self = shift;
    $self->processor->fetch_message();
  }

  sub run {
    my $self = shift;
    while (1) {
      $self->fetch_message;
    }
  }

1;
