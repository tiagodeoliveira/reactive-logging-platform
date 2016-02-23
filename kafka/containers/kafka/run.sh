#!/bin/bash

# some defaults
KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
KAFKA_CONFIG_FILE=$KAFKA_HOME/config/server.properties

broker_id_config="$KAFKA_HOME/conf.d/broker_id"
while [ ! -s $broker_id_config ]; do
  echo "Waiting for $broker_id_config to appear"
  sleep 1
done
broker_id=$(cat $broker_id_config)
echo "broker.id = $broker_id" > $KAFKA_CONFIG_FILE

hostname_config="$KAFKA_HOME/conf.d/hostname"
while [ ! -s $hostname_config ]; do
  echo "Waiting for $hostname_config to appear"
  sleep 1
done
kafka_hostname=$(cat $hostname_config | xargs | tr ' ' ',')

export KAFKA_CONFIG_HOST_NAME=${KAFKA_CONFIG_HOST_NAME:-$kafka_hostname}
export KAFKA_CONFIG_ZOOKEEPER_CONNECT=${KAFKA_CONFIG_ZOOKEEPER_CONNECT:-$(env | grep ZK.*PORT_2181_TCP= | sed -e 's|.*tcp://||' | paste -sd ,)}
export KAFKA_CONFIG_PORT=${KAFKA_CONFIG_PORT:-9092}
export KAFKA_CONFIG_LOG_DIRS=${KAFKA_CONFIG_LOG_DIRS:-"/kafka/kafka-logs-$KAFKA_CONFIG_HOST_NAME"}

for v in `env | egrep '^KAFKA_CONFIG_'`; do
  name=$(echo "$v" | cut -d '=' -f 1 | sed -e 's/KAFKA_CONFIG_//' | tr '[A-Z]' '[a-z]' | tr '_' '.')
  value=$(echo "$v" | cut -d '=' -f 2)
  echo "$name = $value" >> $KAFKA_CONFIG_FILE
done

echo "Starting kafka .."
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_CONFIG_FILE &
pid=$!

# wait for kafka to start up
while ! netstat -lnt | awk '{ print $4 }' | egrep -q ":$KAFKA_CONFIG_PORT$"; do
  # make sure we do not wait forever though
  kill -0 $pid &>/dev/null || { echo "Kafka shut down unexpectedly"; exit 1; }
  echo "Waiting for kafka to bind to TCP $KAFKA_CONFIG_PORT"
  sleep 1
done

if [[ -n $KAFKA_CREATE_TOPICS ]]; then
    unset JMX_PORT
    IFS=','; for topicToCreate in $KAFKA_CREATE_TOPICS; do
        IFS=':' read -a topicConfig <<< "$topicToCreate"
        echo "Creating topic $topicConfig"
        $KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper $KAFKA_CONFIG_ZOOKEEPER_CONNECT --replication-factor ${topicConfig[2]} --partition ${topicConfig[1]} --topic "${topicConfig[0]}"
    done
fi

wait $pid
