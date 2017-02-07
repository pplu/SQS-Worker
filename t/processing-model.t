use Test::Spec;
use strict;
use warnings;
use lib 't/lib';
use SQS::Worker::Client;
use SQS::Worker::DefaultLogger;
use Worker::NothingWorker;
use TestMessage;

sub stub_sqs {
    my $client = SQS::Worker::Client->new(serializer => 'json', queue_url => '', region => '');
    my $serialized = $client->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });
    my $message = TestMessage->new(Body => $serialized, ReceiptHandle => '');
    my $message_pack = stub(Messages => [$message]);
    my $sqs_stub = stub(
        ReceiveMessage => $message_pack,
        DeleteMessage => undef
    );
    return $sqs_stub;
}

sub logmock {
    return stub(
        info => sub {},
        error => sub {},
        warning => sub {},
        debug => sub {});
}

sub mk_success_worker {
    my $worker = Worker::NothingWorker->new(
        queue_url => '',
        region => '',
        log => logmock(),
        sqs => stub_sqs()
    );
    $worker->stubs(process_message => sub {
        print STDERR "processing message\n";
        return 42;
    });
    return $worker;
};

sub mk_failure_worker {
    my $logmock = mock();
    my $worker = Worker::NothingWorker->new(
        queue_url => '',
        region => '',
        log => logmock(),
        sqs => stub_sqs()
        );
    $worker->stubs(process_message => sub { die "I'm falling" });
    return $worker;
}

# describe "I can stub" => sub {
#     it "message processing" => sub {
#         my $worker = mk_success_worker();
#         $worker->fetch_message();
#     };
# };

describe "DefaultProcessingModel" => sub {
    it "will delete message on success" => sub {
        my $worker = mk_success_worker();
        my $expectation = $worker->expects('delete_message')->once();
        $worker->fetch_message();
        ok($expectation->verify);
    };

    it "will not delete message on failure" => sub {
        my $worker = mk_failure_worker();
        my $expectation = $worker->expects('delete_message')->never();
        $worker->fetch_message();
        ok($expectation->verify);
    };
};

# xdescribe "DeleteAlwaysProcessingModel" => sub {
#     my $client = SQS::Worker::Client->new(serializer => 'json', queue_url => '', region => '');
#     my $serialized = $client->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });
#     my $message = TestMessage->new(Body => $serialized, ReceiptHandle => '');

#     it "will delete message on success" => sub {
#         my $worker = mk_success_worker();
#         $worker->process_message($message);
#     };

#     it "will delete message on failure" => sub {
#         my $worker = mk_failure_worker();
#         $worker->process_message($message);
#     };
# };

runtests unless caller;
1;
