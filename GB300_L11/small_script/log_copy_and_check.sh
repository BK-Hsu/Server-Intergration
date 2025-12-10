#!/bin/bash

echo "=====  PING LOG Check ====="
readarray -t hosts < os_ip.txt
for host in "${hosts[@]}"; do
  echo "$host"
  sshpass -p "abcdef" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$host \
    "cat /root/*log 2>/dev/null | grep 'Successful attempts'" || echo "$host [ LOG] FAIL"
  echo "===== L10 Diag LOG Check ====="
  sshpass -p "abcdef" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$host \
    "cat /root/629-24975-0000-FLD-42872/dgx/logs*/run* 2>/dev/null | grep 'Final'" || echo "$host [L10 LOG] FAIL"

  mkdir -p logs/$host
  sshpass -p "abcdef" scp -r -o StrictHostKeyChecking=no root@$host:/root/*log ./logs/$host/ 2>/dev/null || echo "$host [SCP ] FAIL"
  sshpass -p "abcdef" scp -r -o StrictHostKeyChecking=no root@$host:/root/629-24975-0000-FLD-42872/dgx/logs*/run* ./logs/$host/ 2>/dev/null || echo "$host [SCP L10] FAIL"
  echo "========"
done
