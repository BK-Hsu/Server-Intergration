#!/bin/bash
GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457

	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" |awk '{print $1}'| sed -n 1p | awk '{print $1}' | tr -d ': ')
	#BootDiskVolume=$( echo $BootDiskVolume | cut -c 1-$((${#BootDiskVolume}-1))) 
	BootDiskVolume=$(lsblk | grep -wB30 "`basename ${BootDiskVolume}`" | grep -iw "disk" | tail -n1 | awk '{print $1}')
	BootDiskVolume=$(echo "/dev/${BootDiskVolume}" )
	
	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $NF}')
}
