i=1
for ip in $(cat ~/os_ip.txt); do
  ssh -o StrictHostKeyChecking=no root@$ip "hostnamectl set-hostname tray$(printf '%02d' $i)"
  echo "$ip set to tray$(printf '%02d' $i)"
  ((i++))
done
