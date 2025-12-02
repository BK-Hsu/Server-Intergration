#!/bin/bash

echo "=====  " $1 "  ====="
readarray -t hosts < os_ip.txt
export=$1
for host in "${hosts[@]}"; do
  echo "$host"
  sshpass -p "abcdef" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$host $1
  echo "========"
done
