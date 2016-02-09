package Client::Json {
  use Moose;
  use JSON::MaybeXS;
  #has region;
  #has queue_url;

  sub serialize_params {
    my ($self, @params) = @_;

    return encode_json \@params;
  }

  sub call {
    my ($self, $method, @params) = @_;
  }
}
1;