#!/bin/bash

SESSION_NAME="fw_update"

# Prompt user for update type: BIOS or NVFW
echo "Select firmware type to update:"
echo "1) NVFW"
echo "2) BIOS"
read -p "Enter choice [1 or 2]: " CHOICE

case "$CHOICE" in
  1)
    FILENAME="nvfw_GB300-P4059-0301_0041_250719.1.1_custom_nosbios_prod-signed.fwpkg"
    FILEURL="http://192.168.0.1/image/fwpkg/GB300/NVFW/08_QA/tray/\${FILENAME}"
    ;;
  2)
    FILENAME="XA-GB721-E2-ASUS-0101.fwpkg"
    FILEURL="http://192.168.0.1/image/fwpkg/GB300/BIOS/0805_release/\${FILENAME}"
    ;;
  *)
    echo "Invalid selection. Exiting."
    exit 1
    ;;
esac

REDFISH_URI="/redfish/v1/UpdateService/update-multipart"
HMC="172.31.13.251"
USERNAMEBMC="sysadmin"
PASSWORDBMC="superuser"
CREDENTIALS="root:openBmc"

# Prompt user for number of panes per window
read -p "Enter number of panes per window (e.g. 4, 9): " MAX_PANES
if ! [[ "$MAX_PANES" =~ ^[0-9]+$ ]] || (( MAX_PANES <= 0 )); then
  echo "Invalid number. Exiting."
  exit 1
fi

# Read IP list
if [[ ! -f bmc_ip.txt ]]; then
  echo "Error: bmc_ip.txt not found!"
  exit 1
fi
readarray -t hosts < bmc_ip.txt
if [[ ${#hosts[@]} -eq 0 ]]; then
  echo "Error: No IPs found in bmc_ip.txt"
  exit 1
fi

# Cleanup old session
tmux kill-session -t $SESSION_NAME 2>/dev/null || true
tmux new-session -d -s $SESSION_NAME

# Generate BMC command with monitoring loop
generate_tmux_command() {
  local ip=$1
  cat <<EOF
sshpass -p "$PASSWORDBMC" ssh -o StrictHostKeyChecking=no $USERNAMEBMC@$ip '
cd /tmp && \
rm -f "$FILENAME" && \
wget "$FILEURL" && \
fw="/tmp/$FILENAME" && \
curl -k -u $CREDENTIALS -H "Expect:" --location --request POST http://$HMC$REDFISH_URI \
  -F "UpdateParameters={\"Targets\":[],\"ForceUpdate\":true};type=application/json" \
  -F "UpdateFile=@\\$fw" > /tmp/task_response.json && \
TASK_ID=\\$(grep -o 'Tasks/[0-9]*' /tmp/task_response.json | cut -d'/' -f2) && \
echo ==== Started Task \\$TASK_ID on $ip ==== && \
while true; do \
  curl -k -u $CREDENTIALS -H "Expect:" GET http://$HMC/redfish/v1/TaskService/Tasks/\\$TASK_ID 2>/dev/null | \
  grep -i "PercentComplete\\|TaskState\\|TaskStatus"; \
sleep 10; \
done'
EOF
}

# Create and assign panes
i=0
current_window=0
current_pane=0

for ip in "${hosts[@]}"; do
  pane_cmd=$(generate_tmux_command "$ip")

  if (( current_pane == 0 && current_window == 0 )); then
    tmux send-keys -t ${SESSION_NAME}:$current_window "$pane_cmd" C-m
  elif (( current_pane == 0 )); then
    tmux new-window -t $SESSION_NAME -n "win_$current_window"
    tmux send-keys -t ${SESSION_NAME}:$current_window "$pane_cmd" C-m
  else
    tmux split-window -t ${SESSION_NAME}:$current_window -h
    tmux select-layout -t ${SESSION_NAME}:$current_window tiled
    tmux send-keys -t ${SESSION_NAME}:$current_window "$pane_cmd" C-m
  fi

  ((current_pane++))
  if (( current_pane >= MAX_PANES )); then
    current_pane=0
    ((current_window++))
  fi

done

tmux select-layout -t $SESSION_NAME tiled
tmux attach -t $SESSION_NAME
