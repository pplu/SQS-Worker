#!/usr/bin/env perl
use strict;
use warnings;

package TestMessage {
  use Moose;
  has Body => (is => 'ro');
  has ReceiptHandle => (is => 'ro');
}

use Test::More;
use Test::Exception;

use WorkerJson;


my $qcclient = SQS::Client->new();

my $json = $qcclient->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });

my $w = WorkerJson->new(queue_url => '', region => '');

my $message = TestMessage->new(
  Body => $json,
  ReceiptHandle => ''
);
lives_ok { $w->process_message($message) } 'expecting to live';

my $message_to_fail = TestMessage->new(
  Body => '',
  ReceiptHandle => ''
);
dies_ok { $w->process_message($message_to_fail) } 'expecting to die';


done_testing();


package SQS::Client {
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