#!/bin/bash
declare Status=$1
declare BootDiskVolume
#------------------------------------------------------------------
if [ ${#Status} == 0 ] ; then
	echo "Usage: "
	echo " $0 [0|1]"
	exit 1
fi

GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457
	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" |awk '{print $1}'| sed -n 1p |cut -c 1-8)

	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $3}')
}

case ${Status} in
	1)
		#GetBootDisk
		for((i=1;i<=2;i++))
		do
			hdparm -t /dev/nvme0n1 >/dev/null 2>&1 
		done
	;;
	
	0)
		exit 0
	;;
	
	*)
		printf "%s\n" "Invalid parameter!"
		exit 1	
	;;
	esac
	
exit 0


