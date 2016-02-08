package Worker1 {
  use Moose;
  with 'SQS::Worker', 'SQS::Worker::DecodeJson';

  sub process {
    
  }

}
