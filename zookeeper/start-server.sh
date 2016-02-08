#!/bin/bash

if [ -z ${ZOO_ID} ] ; then
  echo 'No ID specified, please specify one between 1 and 255'
  exit -1
fi

if [ ! -f /conf/zoo.cfg ] ; then
  echo 'Waiting for config file to appear...'
  while [ ! -f /zookeeper/conf/zoo.cfg ] ; do
    sleep 1
  done
  echo 'Config file found, starting server.'
fi

mkdir -p /zookeeper/data
echo "${ZOO_ID}" > /zookeeper/data/myid

/zookeeper/bin/zkServer.sh start-foreground
