#!/bin/bash

if [ -n "$MASTER_NODE" ]; then
  OPTS="$OPTS -Dnode.master=true"
fi

if [ -n "$CLIENT_NODE" ]; then
  OPTS="$OPTS -Dnode.data=false -Dnode.master=false"
fi

if [ -n "$DATA_NODE" ]; then
  OPTS="$OPTS -Dnode.data=true"
fi

if [ -n "$CLUSTER" ]; then
  OPTS="$OPTS -Des.cluster.name=$CLUSTER"
fi

if [ -n "$NODE_NAME" ]; then
  OPTS="$OPTS -Des.node.name=$NODE_NAME"
fi

if [ -n "$MULTICAST" ]; then
  OPTS="$OPTS -Des.discovery.zen.ping.multicast.enabled=$MULTICAST"
fi

if [ -n "$UNICAST_HOSTS" ]; then
  OPTS="$OPTS -Des.discovery.zen.ping.unicast.hosts=$UNICAST_HOSTS"
fi

if [ -n "$PLUGINS" ]; then
  for p in $(echo $PLUGINS | awk -v RS=, '{print}')
  do
    echo "Installing the plugin $p"
    $ES_HOME/bin/plugin install $p
  done
fi

echo "Starting Elasticsearch with the options $OPTS"
gosu elasticsearch elasticsearch $OPTS
