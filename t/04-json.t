#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use SQS::Worker::Client;
use Worker::Json;
use TestMessage;


my $client = SQS::Worker::Client->new(serializer => 'json', queue_url => '', region => '');
my $serialized = $client->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });

my $worker = Worker::Json->new(queue_url => '', region => '');

my $message = TestMessage->new(
  Body => $serialized,
  ReceiptHandle => ''
);
lives_ok { $worker->process_message($message) } 'expecting to live';

my $message_to_fail = TestMessage->new(
  Body => '',
  ReceiptHandle => ''
);
dies_ok { $worker->process_message($message_to_fail) } 'expecting to die';


done_testing();
