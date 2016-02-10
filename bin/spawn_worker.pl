#!/usr/bin/env perl
use strict;
use warnings;

use Module::Runtime qw/require_module/;


package SpawnWorkerArgs {
  use Moose;
  with 'MooseX::Getopt';

  has 'worker'    => (is => 'ro', isa => 'Str', required => 1, documentation => 'The SQS::Worker class name');
  has 'queue_url' => (is => 'ro', isa => 'Str', required => 1, documentation => 'The SQS queue URL to poll for messages');
  has 'region'    => (is => 'ro', isa => 'Str', required => 1, documentation => 'The SQS region identifier');
}


my $args = SpawnWorkerArgs->new_with_options();

require_module($args->worker);

# Instance worker
my $worker_instance = $args->worker->new(
  queue_url => $args->queue_url,
  region    => $args->region
);

if ($worker_instance->does('SQS::Worker')) {
  $worker_instance->run();
}
