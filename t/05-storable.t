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

use WorkerStorable;


my $qstclient = SQS::StClient->new();

my $serialized = $qstclient->store_params(1, 'param2', [1,2,3], { a => 'hash' });

my $wst = WorkerStorable->new(queue_url => '', region => '');

my $message_st = TestMessage->new(
  Body => $serialized,
  ReceiptHandle => ''
);
lives_ok { $wst->process_message($message_st) } 'expecting to live';

my $message_to_fail_st = TestMessage->new(
  Body => '',
  ReceiptHandle => ''
);
dies_ok { $wst->process_message($message_to_fail_st) } 'expecting to die';


done_testing();


package SQS::StClient {
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