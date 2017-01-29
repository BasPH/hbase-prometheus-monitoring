# Monitoring HBase with Prometheus demo

This repo serves as a demo for [this blog](https://blog.godatadriven.com/hbase-prometheus-monitoring). Running `./run-demo.sh` will set up HBase, Prometheus and Grafana. Browse to http://localhost:3000/dashboard/db/hbase to view the metrics.

There are several dependencies, e.g. Docker on OS X is used for Prometheus and Grafana. You might need to install something or edit configs.

To simulate some usage and view nice graphs on the HBase cluster, you could use [HBase performance evaluation](http://hbase.apache.org/book.html#__code_hbase_pe_code).

## Software & versions used
* Prometheus 1.5.0
* Grafana 4.1.0-beta1
* HBase 1.2.4
* Docker
