#!/bin/bash

# === check ===
if [[ "$1" =~ ^-h$|^--help$|^-help$ || -z "$1" ]]; then
  echo "Usage: $0 [On|ForceOn|ForceOff]"
  echo ""
  echo "Available ResetType:"
  echo "  On        - Open PSU output (1~6)"
  echo "  ForceOn   - Force PSU output on (1~6)"
  echo "  ForceOff  - Force PSU output off (1~6)"
  echo ""
  echo "Note: Edit power_ip.txt to list target BMC IPs (one per line)."
  exit 1
fi

reset_type="$1"
valid_types=("On" "ForceOn" "ForceOff")
if [[ ! " ${valid_types[@]} " =~ " ${reset_type} " ]]; then
  echo "Error: Invalid ResetType: $reset_type"
  echo "Run with -h to view usage."
  exit 1
fi

# === check ===
if [[ ! -f "power_ip.txt" ]]; then
  echo "Error: power_ip.txt not found."
  exit 1
fi

# === action ===
user="root"
pass="0penBmc"

while IFS= read -r host; do
  [[ -z "$host" ]] && continue
  echo "=== Controlling $host ==="
  for i in {1..6}; do
    echo " → PSU $i → $reset_type"
    curl -ks -u $user:$pass -X POST \
      https://$host/redfish/v1/Chassis/PowerShelf_0/PowerSubsystem/PowerSupplies/$i/Actions/PowerSupply.Reset \
      -H "Content-Type: application/json" \
      -d "{\"ResetType\": \"$reset_type\"}"
    echo ""
  done
  echo ""
done < power_ip.txt
