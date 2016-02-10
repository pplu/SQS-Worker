package Client::Storable {
  use Moose;
  use Paws;
  use Storable qw/freeze/;

  has queue_url => (is => 'ro', isa => 'Str', required => 1);
  has region    => (is => 'ro', isa => 'Str', required => 1);

  has sqs => (is => 'ro', isa => 'Paws::SQS', lazy => 1, default => sub {
    my $self = shift;
    Paws->service('SQS', region => $self->region);
  });

  sub serialize_params {
    my ($self, @params) = @_;

    return freeze \@params;
  }

  sub call {
    my ($self, @params) = @_;

    my $serialized = $self->serialize_params(@params);

    my $message_pack = $self->sqs->SendMessage(
      MessageBody => $serialized,
      QueueUrl => $self->queue_url
    );
  }
}
1;