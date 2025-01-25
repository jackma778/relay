#!/bin/bash

# 提示用户输入 relay_node_id
read -p "请输入 relay_node_id (这是一个数字): " relay_node_id

# 检查输入是否为数字
if ! [[ "$relay_node_id" =~ ^[0-9]+$ ]]; then
    echo "输入无效，请输入一个数字。"
    exit 1
fi
# 优化内核参数 检查是否存在重复配置项
if ! grep -q "^net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf; then
    cat <<EOF >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sysctl -p
fi

if ! grep -q "^net.nf_conntrack_max = 20971520" /etc/sysctl.conf; then
    cat <<EOF >> /etc/sysctl.conf
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_rmem = 4096 87380 25000000
net.ipv4.tcp_wmem = 4096 16384 25000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768
net.nf_conntrack_max = 20971520
EOF
    sysctl -p
fi


if ! grep -q "*               soft    nofile           1000000" /etc/security/limits.conf; then
    echo "*               soft    nofile           1000000
*               hard    nofile          1000000" > /etc/security/limits.conf
fi

if ! grep -q "^ulimit -SHn 1000000" /etc/profile; then
    echo "ulimit -SHn 1000000" >> /etc/profile
    source /etc/profile
fi

sed -i "s/command: \[\"-c\", \".*\"\]/command: \[\"-c\", \"$relay_node_id\"\]/" docker-compose.yaml

docker compose up -d

docker cp ehco ehco:/usr/bin/ehco
docker restart ehco
sleep 3 
if crontab -l | grep -q "ehco" && crontab -l | grep -q "iperf3"; then
    echo "pass"
else
    echo "add crontab"
    minute=$(shuf -i 0-59 -n 1)
    hour=$(shuf -i 3-6 -n 1)
    weekday=$(shuf -i 0-6 -n 1)
    (crontab -l ; echo "$minute $hour * * $weekday docker restart ehco iperf3") | crontab -
fi
docker logs -n 10 ehco

