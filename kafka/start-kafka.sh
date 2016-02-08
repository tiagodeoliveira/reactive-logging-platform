#!/bin/bash

if [[ -z "$KAFKA_ADVERTISED_PORT" ]]; then
    export KAFKA_ADVERTISED_PORT=$(docker port `hostname` 9092 | sed -r "s/.*:(.*)/\1/g")
fi
if [[ -z "$KAFKA_BROKER_ID" ]]; then
    # By default auto allocate broker ID
    export KAFKA_BROKER_ID=-1
fi
if [[ -z "$KAFKA_LOG_DIRS" ]]; then
    export KAFKA_LOG_DIRS="/kafka/kafka-logs-$HOSTNAME"
fi
if [[ -z "$KAFKA_ZOOKEEPER_CONNECT" ]]; then
    export KAFKA_ZOOKEEPER_CONNECT=$(env | grep ZK.*PORT_2181_TCP= | sed -e 's|.*tcp://||' | paste -sd ,)
fi

if [[ -n "$KAFKA_HEAP_OPTS" ]]; then
    sed -r -i "s/(export KAFKA_HEAP_OPTS)=\"(.*)\"/\1=\"$KAFKA_HEAP_OPTS\"/g" $KAFKA_HOME/bin/kafka-server-start.sh
    unset KAFKA_HEAP_OPTS
fi

if [[ -z "$KAFKA_ADVERTISED_HOST_NAME" && -n "$HOSTNAME_COMMAND" ]]; then
    export KAFKA_ADVERTISED_HOST_NAME=$(eval $HOSTNAME_COMMAND)
fi

for VAR in `env`
do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR =~ ^KAFKA_HOME ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/server.properties #note that no config values may contain an '@' char
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/server.properties
    fi
  fi
done

# Capture kill requests to stop properly
trap "$KAFKA_HOME/bin/kafka-server-stop.sh; echo 'Kafka stopped.'; exit" SIGHUP SIGINT SIGTERM

$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties &
KAFKA_SERVER_PID=$!

while netstat -lnt | awk '$4 ~ /:9092$/ {exit 1}'; do sleep 1; done

if [[ -n "$JMX_EXPOSE" ]]; then
  export PUBLIC_JMX_PORT=$(docker port `hostname` ${JMX_PORT} | sed -r "s/.*:(.*)/\1/g")
  BROKER_ID=$(cat /kafka/kafka-logs-${HOSTNAME}/meta.properties | grep broker.id | cut -d= -f2)
  NEW_BROKER_JSON=$(echo "get /brokers/ids/${BROKER_ID}" | ./$KAFKA_HOME/bin/kafka-run-class.sh org.apache.zookeeper.ZooKeeperMain -server ${KAFKA_ZOOKEEPER_CONNECT} | sed -n '8,9p' | jq -c --arg PUBLIC_JMX_PORT $PUBLIC_JMX_PORT '.jmx_port=($PUBLIC_JMX_PORT|tonumber)')
  echo "set /brokers/ids/${BROKER_ID} ${NEW_BROKER_JSON}" | ./$KAFKA_HOME/bin/kafka-run-class.sh org.apache.zookeeper.ZooKeeperMain -server ${KAFKA_ZOOKEEPER_CONNECT}
fi

if [[ -n $KAFKA_CREATE_TOPICS ]]; then
    unset JMX_PORT
    echo "Creating topics $KAFKA_CREATE_TOPICS"
    IFS=','; for topicToCreate in $KAFKA_CREATE_TOPICS; do
        IFS=':' read -a topicConfig <<< "$topicToCreate"
        $KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper $KAFKA_ZOOKEEPER_CONNECT --replication-factor ${topicConfig[2]} --partition ${topicConfig[1]} --topic "${topicConfig[0]}"
    done
fi

wait $KAFKA_SERVER_PID
