# An elastic and reactive-ish logging platform

This stack is meant to be an 'easy to scale' logging platform, the [presentation link is here](https://github.com/tiagodeoliveira/docker-log-platform-presentation).

It leverages of the kafka high throughput to feed and elasticsearch cluster.

This elasticsearch cluster is composed with:

* Data nodes, that are meant to store and index information;
* Client nodes, that are a kind of load balancer, that are responsible for some processing but not the entire query/ index flow;
* Master nodes are the glue to tie everything together, they do not do any operation other than manage the cluster;

This architecture allows us to scale up and down the cluster as it is needed.

We are also using fluentd daemon in order to process fulfill the messages deliver all the way to elasticsearch.
The fluentdprocessor container aims to send the data to elasticsearch, but send that to an raw storage as well. The first idea is to send that to Amazon S3, where it will remain for one month and will be moved to Amazon Glacier.

The topics (info, debug, warn, error) are being converged to one single logstash index style, we need to separate those concerns, also route the debug info directly to S3, so it can be iterate over by and Apache Hive, Apache Spark or a specific elasticsearch node.

On the log-generator folder, we have a groovy script who sends a 1000 messages to fluentdreceiver. Also there is a FluentAppender that can be used with Logback API in order to create an appender from the application to fluentd instance.


This stack is meant to run over Rancher cluster management. It will make really easier to provision and scale the infra on demand.
