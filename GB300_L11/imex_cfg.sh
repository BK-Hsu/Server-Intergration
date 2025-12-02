#!/bin/bash
#2025/1/9
#Rex_Zh
#IMEX Configuration
Service_content="
192.168.2.48
192.168.2.47
192.168.2.46
192.168.2.45
192.168.2.44
192.168.2.43
192.168.2.42
192.168.2.41
192.168.12.118
192.168.2.39
192.168.2.37
192.168.2.38
192.168.2.36
192.168.2.35
192.168.2.34
192.168.2.33
192.168.2.32
192.168.2.31
"
SSH_content="
MaxSessions 550
MaxStartups 10:30:100
"


echo "$Service_content" | sudo tee /etc/nvidia-imex/nodes_config.cfg > /dev/null
sleep 1s

systemctl start nvidia-imex.service
systemctl enable nvidia-imex.service

check_service() {
    systemctl is-enabled --quiet nvidia-imex && systemctl is-active --quiet nvidia-imex
}

# Ensure the nvidia-imex service is enabled and active
if check_service; then
    echo "nvidia-imex service is enabled and running."

    # Extract the major number
    major_number=$(cat /proc/devices | grep -i nvidia-caps-imex-channels | awk '{print $1}')

    if [ -z "$major_number" ]; then
        echo "Error: Could not extract major number."
        exit 1
    fi

    # Create the necessary directories and device nodes
    sudo mkdir -p /dev/nvidia-caps-imex-channels/
    sudo mknod /dev/nvidia-caps-imex-channels/channel0 c $major_number 0

# Configuring the SSH Server
echo "$SSH_content" | sudo tee /etc/ssh/sshd_config.d/mpi.conf > /dev/null
sleep 1s
#systemctl restart sshd
fi
