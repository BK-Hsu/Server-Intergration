#!/bin/bash

echo "===== BMC SSH Check ===="
## BMC SSH Check
while IFS= read -r host; do
  nc -z -w 2 "$host" 22 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$host SSH is active"
  else
    echo "$host SSH is not active"
  fi
done < bmc_ip.txt

echo "===== OS SSH Check ====="
## OS SSH Check
while IFS= read -r host; do
  nc -z -w 2 "$host" 22 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$host SSH is active"
  else
    echo "$host SSH is not active"
  fi
done < os_ip.txt

echo "===== NVOS SSH Check ====="
## NVOS SSH Check
while IFS= read -r host; do
  nc -z -w 2 "$host" 22 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$host SSH is active"
  else
    echo "$host SSH is not active"
  fi
done < nvos_ip.txt

echo "===== Power-Shelf Service Check ====="
while IFS= read -r host; do
  # 1. 先檢查 SSH (port 22)
  if nc -z -w 2 "$host" 22 >/dev/null 2>&1; then
    echo "$host SSH is active"
    continue
  fi

  # 2. 再檢查 HTTPS (port 443)
  if nc -z -w 2 "$host" 443 >/dev/null 2>&1; then
    # 3. 試 Redfish API
    if curl -sk --max-time 3 "https://$host/redfish/v1/" | grep -q "RedfishVersion"; then
      echo "$host HTTPS Redfish is active"
    else
      echo "$host HTTPS is active (no Redfish)"
    fi
    continue
  fi

  # 4. 全部都不通
  echo "$host No SSH/HTTPS service detected"
done < power_ip.txt


read -r -p " NVSwitch / NVSSVT check ? [y/N]: " _ans
case "${_ans:-N}" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Only check ip status"; exit 0 ;;
esac

echo "####Only L11 NVSwitch ####"
export cmd_sn="nv show platform chassis-location ; nv show system image ; nv show platform firmware"
export cmd_nmx="nv show cluster apps running"
export cmd_acp="nv show interface link-diagnostics"

# 用 readarray 一次讀入，for 直接走陣列（不要再 'done < file'）
readarray -t hosts < nvos_ip.txt
for host in "${hosts[@]}"; do
  [[ -z "$host" || "$host" =~ ^# ]] && continue
  echo "$host"
  echo "-----Localtion & SN Check-----"
  sshpass -p "Admin1@admin" ssh -o StrictHostKeyChecking=no admin@"$host" "$cmd_sn"
  echo "-----NMX Services Check-----"
  sshpass -p "Admin1@admin" ssh -o StrictHostKeyChecking=no admin@"$host" "$cmd_nmx"
  sshpass -p "Admin1@admin" ssh -o StrictHostKeyChecking=no admin@"$host" "$cmd_acp" | grep -v No
  echo "========"
done

echo "####Only L11 NVSSVT####"
readarray -t hosts < os_ip.txt
for host in "${hosts[@]}"; do
  [[ -z "$host" || "$host" =~ ^# ]] && continue
  echo "$host"
  echo "-----DCGM Services Check-----"
  sshpass -p abcdef ssh -o StrictHostKeyChecking=no root@"$host" systemctl status dcgm.service | grep "Active:" | sed 's/^/DCGM /'
  echo "-----FWTS Services Check-----"
  sshpass -p abcdef ssh -o StrictHostKeyChecking=no root@"$host" 'command -v fwts || { apt update && apt install -y fwts; }'
  echo "========"
done

exit 0
