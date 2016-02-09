#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Client::Json;
use Worker::Json;
use TestMessage;


my $qcclient = Client::Json->new();

my $json = $qcclient->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });

my $w = Worker::Json->new(queue_url => '', region => '');

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
