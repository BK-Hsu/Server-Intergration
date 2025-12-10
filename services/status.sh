#!/usr/bin/env bash
set -euo pipefail

SERVICES=(
  isc-dhcp-server
  nginx
  vsftpd
  nfs-server
  nfs-kernel-server
  smbd
)

echo "=== Service Status Summary ==="
for s in "${SERVICES[@]}"; do
  if systemctl list-unit-files | grep -q "^$s"; then
    if systemctl is-active --quiet "$s"; then
      state="active"
    else
      state="inactive"
    fi
    printf "%-20s : %s\n" "$s" "$state"
  fi
done
