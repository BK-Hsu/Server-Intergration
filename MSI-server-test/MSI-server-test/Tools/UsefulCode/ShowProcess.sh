#!/bin/bash

BeepRemind()
{
#Usage: BeepRemind Arg1
local Status=$1
Status=${Status:-"0"}

# load pc speaker driver
lsmod | grep -iq "pcspkr" || modprobe pcspkr

which beep > /dev/null 2>&1
if [ $? != 0 ] ; then
	return 0
fi

case ${Status} in
	0)
		#Pass/Remind
		beep -f 1800 > /dev/null 2>&1
	;;
	
	*)
		#Fail
		beep -f 800 -l 800 > /dev/null 2>&1
	;;
	esac
}

ShowProcess()
{
# printf "%-10s%-60s\n" ""  	
 local Status=$1
 local String="$2"
 case $Status in
	0)
		#[  OK  ]  Download the S1151030.tar.gz 
		printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "${String}"
	;;
	
	*)
		#[  NG  ]  Download the S1151030.tar.gz 
		printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "${String}"
		BeepRemind 1 2>/dev/null
		return 1
	;;
	esac
}
