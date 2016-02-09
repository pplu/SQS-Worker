#!/usr/bin/env perl
use strict;
use warnings;

my $queue  = $ENV{SQS_TEST_QUEUE};
my $region = $ENV{SQS_TEST_REGION};

my ($worker) = @ARGV;

eval("use $worker");
if ($@) {
  print 'Error loading worker: '.$worker;
  die $@;
}

# Instance worker
my $worker_instance = $worker->new(
  queue_url => $queue,
  region    => $region
);

$worker_instance->run();
