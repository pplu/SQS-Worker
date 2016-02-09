#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Client::Storable;
use Worker::Storable;
use TestMessage;


my $qstclient = Client::Storable->new();

my $serialized = $qstclient->store_params(1, 'param2', [1,2,3], { a => 'hash' });

my $wst = Worker::Storable->new(queue_url => '', region => '');

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
