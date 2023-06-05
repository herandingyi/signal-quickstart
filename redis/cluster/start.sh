#!/usr/bin/env bash
redis-cli --cluster create 172.23.1.1:6379 172.23.1.2:6379 172.23.1.3:6379 172.23.1.4:6379 172.23.1.5:6379 172.23.1.6:6379 --cluster-replicas 1 --cluster-yes
echo "finish" > /tmp/finish
#1000 years
sleep 31536000000

