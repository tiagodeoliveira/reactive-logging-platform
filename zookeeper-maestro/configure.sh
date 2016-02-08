#!/bin/bash
containers_ids=$(docker ps --filter "label=zookeeper.server" -q)
config=$(cat zoo.cfg.initial)

for id in $containers_ids ; do
  instance_id=$(docker inspect --format '{{ range .Config.Env }}{{println .}}{{end}}' ${id} | grep ZOO_ID | cut -d= -f 2)
  container_ip=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $id)
  line="server.${instance_id}=${container_ip}:2888:3888"
  config="${config}"$'\n'"${line}"
done

echo "${config}"
echo "${config}" | cat > /zookeeper/conf/zoo.cfg
