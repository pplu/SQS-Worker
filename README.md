# SQS Workers

This project is a framework, much like Paws::API::Server, that allows to just code the behaviour you need from a SQS Queue event, and let the framework take care of launching the workers (a process that will be listening for queue events) and making the process persistent.

# Architecture

## The worker

The worker is the unit of work. Each worker is launched independently of other workers, which fits the asynchronous and independent nature of messaging. In fact, each worker will be a full process, that will dispatch messages from the queue to your code.

A worker is a role that your code will consume, and that will let the framework know how to send messages to it.
The role ```SQS::Worker``` is to be used for this purpose.

```
package YourClass;

use Moose;
with 'SQS::Worker';

sub process_message {
	my ($self, $message) = @_;

	# do something with that message
}
```

Once you have this class, there's a script in local/bin (installed as part of the SQS::Worker framework, with carton) called *spawn_worker* that, along with some extra configuration, launch a process that will receive messages from the queue and pass them to the worker class you've created.

```
spawn_worker --worker YourClass --queue_url sqs_endpoint_url --region aws_sqs_region --log_conf log4perl_config_file_path
```

## Composable interceptors for workers

While the basic worker role will provide your code with a raw sqs message, there are many interceptors that can be composed into your class that will pre-process the message. Among them:

- SQS::Worker::DecodeJson
- SQS::Worker::DecodeStorable
- SQS::Worker::Multipex
- SQS::Worker::SNS

For example, if you compose your worker with the role SQS::Worker::DecodeJSON, the message received by the worker will be a perl datastructure.
Look the documentation of each interceptor too see what each does, and how to be used.

## Credentials handling

SQS::Worker is an abstraction over Paws, it thus uses the same credential system that Paws does, which means the three ways you can provide the access key and secret key for the code to use:

- having the credentials in the home of the user launching the script, in the ~/.aws/credentials file.
- by assigning an IAM role to the EC2 instance that is running the code (if deploying the code inside an EC2 instance)
- by using environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

# Installing the framework

Your project needs to declare SQS::Worker as a dependency in the cpanfile. This package is only available through CPS-CPAN, so be sure to include the mirror when calling carton install. As in:
```PERL_CARTON_MIRROR=file://$(HOME)/src/cps-cpan/repo carton install```.

Once installed as a dependency, you can use it as described in the architecture section.
