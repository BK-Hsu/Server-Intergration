#!/bin/bash
declare Status=$1
#------------------------------------------------------------------
if [ ${#Status} == 0 ] ; then
	echo "Usage: "
	echo " $0 [0|1]"
	exit 1
fi

modprobe ipmi_devintf
if [ $? -ne 0 ]; then
	Process 1 "Load IPMI Driver"
	exit 5
fi

modprobe ipmi_si > /dev/null 2>&1
sleep 1

	
case ${Status} in
	0)
		ipmitool raw 0x28 0x1 0 116 1 1 > /dev/null 2>&1
		sleep 1
		
	;;
	
	1)
		ipmitool raw 0x28 0x1 0 116 1 0 > /dev/null 2>&1
		sleep 1
		
	;;
	
	*)
		printf "%s\n" "Invalid parameter!"
		exit 1	
	;;
	esac
	
exit 0


