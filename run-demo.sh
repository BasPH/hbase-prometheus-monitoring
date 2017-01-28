#!/bin/bash
# Demo installation script for HBase monitoring with Prometheus JMX exporter and Grafana
# This script will install in /tmp/demo

# Stop all HBase & HDFS processes
rm -v -rf /tmp/demo
rm -v -rf /tmp/hadoop-${USER} # cleanup HDFS
docker rm --force demo_prometheus demo_grafana

GREEN='\033[0;32m'
NOCOLOR='\033[0m'
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DEMO_DIR=/tmp/demo

# Run Prometheus
docker run --name demo_prometheus -d -p 9090:9090 prom/prometheus:v1.5.0 &&
echo -e "${GREEN}You can now browse to http://localhost:9090 for the Prometheus UI${NOCOLOR}"

# Run Grafana
docker run --name demo_grafana -d -i -p 3000:3000 grafana/grafana:4.1.0-beta1 &&
echo -e "${GREEN}You can now browse to http://localhost:3000 for the Grafana UI${NOCOLOR}"

# Create directory for local files
mkdir -p $DEMO_DIR
cd $DEMO_DIR

# Download HBase
wget http://apache.proserve.nl/hbase/1.2.4/hbase-1.2.4-bin.tar.gz
tar zxvf hbase-1.2.4-bin.tar.gz
rm hbase-1.2.4-bin.tar.gz

# Download Hadoop
wget http://apache.proserve.nl/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
tar zxvf hadoop-2.7.3.tar.gz
rm hadoop-2.7.3.tar.gz

# Start HDFS
cp $SCRIPT_DIR/files/hdfs/hdfs-site.xml $DEMO_DIR/hadoop-2.7.3/etc/hadoop/
cp $SCRIPT_DIR/files/hdfs/core-site.xml $DEMO_DIR/hadoop-2.7.3/etc/hadoop/
$DEMO_DIR/hadoop-2.7.3/bin/hdfs namenode -format -force -nonInterActive
$DEMO_DIR/hadoop-2.7.3/sbin/start-dfs.sh
echo -e "${GREEN}Namenode UI available at http://localhost:50070${NOCOLOR}"

# Download Prometheus JMX exporter & copy config
wget http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.7/jmx_prometheus_javaagent-0.7.jar
cp $SCRIPT_DIR/files/hbase_jmx_config.yaml $DEMO_DIR

# Start 2 HBase masters & 3 HBase regionservers with Prometheus JMX exporter. start-hbase.sh starts 1 additional regionserver.
cp $SCRIPT_DIR/files/hbase/hbase-site.xml $DEMO_DIR/hbase-1.2.4/conf/
cp $SCRIPT_DIR/files/hbase/hbase $DEMO_DIR/hbase-1.2.4/bin/hbase
echo "export JAVA_HOME=${JAVA_HOME}" | cat - $DEMO_DIR/hbase-1.2.4/conf/hbase-env.sh > $DEMO_DIR/hbase-1.2.4/conf/hbase-env.sh.tmp && mv $DEMO_DIR/hbase-1.2.4/conf/hbase-env.sh.tmp $DEMO_DIR/hbase-1.2.4/conf/hbase-env.sh
${DEMO_DIR}/hbase-1.2.4/bin/start-hbase.sh
${DEMO_DIR}/hbase-1.2.4/bin/local-master-backup.sh start 1
${DEMO_DIR}/hbase-1.2.4/bin/local-regionservers.sh start 2 3 4
echo -e "${GREEN}You can now browse to http://localhost:16010 for the HBase master UI${NOCOLOR}"

# Configure Prometheus
docker cp $SCRIPT_DIR/files/prometheus.yml demo_prometheus:/etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload

# Add Prometheus datasource to Grafana
curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"Demo Prometheus","type":"prometheus","url":"http://localhost:9090","access":"direct","isDefault":true}'
curl 'http://admin:admin@localhost:3000/api/dashboards/db' -X POST -H 'Content-Type: application/json;charset=UTF-8' -d @$SCRIPT_DIR/files/hbasedashboard.json
echo -e "${GREEN}You can now browse to http://localhost:3000/dashboard/db/hbase for the demo dashboard${NOCOLOR}"
