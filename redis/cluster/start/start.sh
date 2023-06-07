#!/usr/bin/env bash
if [ ! -f /tmp/finish ]; then
  redis-cli --cluster create 172.23.1.1:6379 172.23.1.2:6379 172.23.1.3:6379 172.23.1.4:6379 172.23.1.5:6379 172.23.1.6:6379 --cluster-replicas 1 --cluster-yes
  cd /mylua || exit
  find . -name "*.lua" | while IFS= read -r file; do
    echo -n "$file : "
    redis-cli -h 172.23.1.1 -p 6379 -x script load < "$file"
  done
  cd - || exit
  echo "finish" >/tmp/finish
fi
#1000 years
sleep 31536000000
