#!/bin/bash
printf "%-15s %-25s %-25s\n" "Host" "Firmware ID" "Version"
while IFS= read -r host; do
  for ep in $(curl -sk -u admin:adminadmin "https://${host}/redfish/v1/UpdateService/FirmwareInventory" | jq -r '.Members[]."@odata.id"'); do
    firmware_json=$(curl -sk -u admin:adminadmin "https://${host}${ep}")
    printf "%-15s %-25s %-25s\n" \
           "$host" \
           "$(echo "$firmware_json" | jq -r '.Id')" \
           "$(echo "$firmware_json" | jq -r '.Version')"
  done
  echo "---"
done < bmc_ip.txt
