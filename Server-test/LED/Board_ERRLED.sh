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

CpuTemp=$(ipmitool sensor | awk '/degrees C/&&/(TEMP_CPU)/{print $0}' | head -n 1)
	if [ ${#CpuTemp} == 0 ]; then
		echo "Get the CPU tempurature address"
		exit 4
	fi

sensor=$(echo "${CpuTemp}" | awk '{print $1}')
unc=$(echo "${CpuTemp}" | awk '{print $16}')
uc=$(echo "${CpuTemp}" | awk '{print $18}')
if [ $uc == "0.000" ];then
	uc=$(cat -v cputemp_stand.txt)
else
	echo $uc > cputemp_stand.txt
fi
unr=$(echo "${CpuTemp}" | awk '{print $20}')

case ${Status} in
	0)
		ipmitool sensor thresh "${sensor}" upper "${unc}" "${uc}" "${unr}" > /dev/null 2>&1
		sleep 1
		
	;;
	
	1)
		ipmitool sensor thresh "${sensor}" upper "${unc}" 0 "${unr}" > /dev/null 2>&1
		sleep 1
		
	;;
	
	*)
		printf "%s\n" "Invalid parameter!"
		exit 1	
	;;
	esac
	
exit 0


