package Client::Storable {
  use Moose;
  use Storable qw/freeze/;
  #has region;
  #has queue_url;

  sub store_params {
    my ($self, @params) = @_;

    return freeze \@params;
  }

  sub call {
    my ($self, $method, @params) = @_;
  }
}
1;