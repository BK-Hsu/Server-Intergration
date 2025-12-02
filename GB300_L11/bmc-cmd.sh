#!/bin/bash

echo "=====  " $1 "  ====="
readarray -t hosts < bmc_ip.txt
export=$1
for host in "${hosts[@]}"; do
  echo "$host"
  sshpass -p "superuser" ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no sysadmin@$host $1
  echo "========"
done
