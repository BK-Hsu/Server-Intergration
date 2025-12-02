#!/bin/bash

echo "=====  " $1 "  ====="
readarray -t hosts < nvos_ip.txt
export=$1
for host in "${hosts[@]}"; do
  echo "$host"
  sshpass -p "Admin1@admin" ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no admin@$host $1
  echo "========"
done
