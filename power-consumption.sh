#!/bin/bash
echo "===== [$(date '+%Y-%m-%d  %H:%M:%S')] ====="
while IFS= read -r host; do echo "Power_Shelf:$host"; curl -ks -u root:0penBmc -X GET https://$host/redfish/v1/Chassis/chassis/Sensors/total_power_in | grep -m 1 -i '"Reading"'; done < power_ip.txt | tee /dev/tty | awk '{print $2}' | tr -d ',' | awk '{sum += $1} END {print "Total Reading Sum:", sum}'
