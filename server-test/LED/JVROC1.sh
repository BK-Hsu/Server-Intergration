#!/bin/bash
declare Status=$1
#------------------------------------------------------------------
if [ ${#Status} == 0 ] ; then
	echo "Usage: "
	echo " $0 [0|1]"
	exit 1
fi

case ${Status} in
	0)
		JVROC 0 > /dev/null 2>&1
	;;
	
	1)
		JVROC 1 > /dev/null 2>&1
	;;
	
	*)
		printf "%s\n" "Invalid parameter!"
		exit 1	
	;;
	esac
	
exit 0


