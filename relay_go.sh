#!/bin/bash

# 提示用户输入 relay_node_id
read -p "请输入 relay_node_id (这是一个数字): " relay_node_id

# 检查输入是否为数字
if ! [[ "$relay_node_id" =~ ^[0-9]+$ ]]; then
  echo "输入无效，请输入一个数字。"
  exit 1
fi

sed -i "s/command: \[\"-c\", \".*\"\]/command: \[\"-c\", \"$relay_node_id\"\]/" docker-compose.yaml

docker-compose up -d

docker cp ehco ehco:/usr/bin/ehco
docker restart ehco

docker logs -n 20 ehco

