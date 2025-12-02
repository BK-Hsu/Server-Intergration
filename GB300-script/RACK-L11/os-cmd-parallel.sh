#!/bin/bash

echo "===== Run: $1 ====="
#readarray -t hosts < os_ip.txt
readarray -t hosts < os_ip.txt; for host in "${hosts[@]}"; do echo "Login $host"; ssh-keygen -f "/root/.ssh/known_hosts" -R $host; done

for host in "${hosts[@]}"; do
  {
    echo ">> $host"
    sshpass -p "abcdef" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$host" "$1"
    echo "======== [$host] Done ========"
  } &
done

wait
echo "===== All parallel commands finished. ====="
