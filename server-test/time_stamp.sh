#!/bin/bash
#------------------------------------------------------------------------
#- File Name:Time_stamp.sh
#- Author: Kingsley
#- mail: kingsleywang@msi.com Ext:2250
#- Created Time:2022.01.30
#- Version: 0.0.0.1
#------------------------------------------------------------------------
#ps -ax | awk '/time_stamp/{print $1}' #"time_stamp" 
#if [ $? == 0 ] ; then
#	echo "It's process"
#	exit 0
#fi


# echo pid:$$
ps -ax | grep -v grep | grep ${BASH_SOURCE[0]} | grep -v $$ | grep ${BASH_SOURCE[0]} >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		#echo 'some thing'
		exit 0
	fi

#echo 'start timer...'
declare time_record_file='/TestAP/time_record.log'
if [ ! -f ${time_record_file} ] ; then
	echo 1 > ${time_record_file}
fi
time_stamp=$(cat ${time_record_file})	
while :
do
	sleep 1
	let time_stamp++
	echo ${time_stamp} > ${time_record_file} 2>/dev/null
done
