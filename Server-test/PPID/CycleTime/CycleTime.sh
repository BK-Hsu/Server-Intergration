#!/bin/bash
#FileName : CycleTime.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2018-10-09"
	local UpdatedDate="2018-10-09"
	local Description="Calculate the Cycle Time"
	
	echo "$@" | grep -iq "getVersion" && return 0
	
	#    Linux Functional Test Utility Suites for Enterprise Platform Server
	#  Copyright(c) Micro-Star Int'L Co.,Ltd. 2019 - 2020. All Rights Reserved.
	#           Author：CodyQin, qiutiqin@msi.com
	printf "\n\e[1m%-4s%-s\e[0m\n" "" "Linux Functional Test Utility Suites for Enterprise Platform Server"
	printf "%-1s%-s\n" "" "Copyright(c) Micro-Star Int'L Co.,Ltd. ${CreatedDate%%-*-*} - ${UpdatedDate%%-*-*}. All Rights Reserved."
	printf "%-19s%-s\n\n" "" "Author：CodyQin, qiutiqin@msi.com"
	printf "%2s%-12s%2s%-s\n" "" "File name" ": " "${ShellFile}"
	printf "%2s%-12s%2s%-s\n" "" "Version" ": " "${ApVersion}"
	printf "%2s%-12s%2s%-s\n" "" "Description" ": " "${Description}"
	printf "%2s%-12s%2s%-s\n" "" "Created" ": " "${CreatedDate}"
	printf "%2s%-12s%2s%-s\n" "" "Environment" ": " "Linux and CentOS"
	printf "%2s%-12s%2s%-s\n" "" "History" ": " ""
	# 日期,修改内容
	#printf "%16s%-s\n" "" " , "
	echo
	exit 1
}

Process()
{ 	
	local Status="$1"
	local String="$2"
	case $Status in
		0)
			printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "${String}"
		;;

		*)
			printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "${String}"
			BeepRemind 1 2>/dev/null
			return 1
		;;
		esac
}

BeepRemind()
{
	local Status="$1"
	# load pc speaker driver
	lsmod | grep -iq "pcspkr" || modprobe pcspkr
	which beep >/dev/null 2>&1 || return 0

	case ${Status:-"0"} in
		0)beep -f 1800 > /dev/null 2>&1;;
		*)beep -f 800 -l 800 > /dev/null 2>&1;;
		esac
}

ShowTitle()
{
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
	`basename $0` -l LogFile [-V]
	eg.: `basename $0` -l /TestAP/PPID/H123456789.log
	eg.: `basename $0` -V

	-l : Log File
	-V : Display version number and exit(1)
	
	return code:
		0 : Get cycle time pass
		1 : Get cycle time fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

# Program Time,update in 2019/05/28
main()
{
	rm -rf CT.txt 2>/dev/null
	cat -v ${CTConfigFile} 2>/dev/null | grep -iw  -A1 "Test Pass" | grep -iw "takes time:" | grep -iw "seconds" | awk -v BLK=' ' '{print $2 BLK $5}' > CT.txt 
	sync;sync;sync;

	ProgramCostTimeCnt=($(cat -v CT.txt 2>/dev/null | awk '{print $2}'))
	ProgramCostTimeTTL=0
	for ((t=0;t<${#ProgramCostTimeCnt[@]};t++))
	do
		ProgramCostTimeTTL=$(echo "ibase=10;obase=10; ${ProgramCostTimeCnt[$t]}+${ProgramCostTimeTTL}" | bc)
	done
	  
	ProgramCostTimeTTL_Hour=$(echo "${ProgramCostTimeTTL}/3600" | bc)
	[ ${#ProgramCostTimeTTL_Hour} -eq 1 ] && ProgramCostTimeTTL_Hour=$(echo "0$ProgramCostTimeTTL_Hour")
	echo ${ProgramCostTimeTTL} | grep -q "^\." && ProgramCostTimeTTL=$(echo 0${ProgramCostTimeTTL})
	ProgramCostTimeTTL=$(date -d @$ProgramCostTimeTTL +"${ProgramCostTimeTTL_Hour}:%M:%S")
		

	#Program running start in
	StartTime=$(cat -v ${CTConfigFile} 2>/dev/null  | grep  -iw "Program running start in:" | head -n1 | awk -F'start in: ' '{print $NF}' | sed "s/  / /g" )
	StartTime=${StartTime:-"2020-01-01 00:00:00"}

	#End Time
	EndTime=$(date "+%Y-%m-%d %H:%M:%S %A %Z")

	#Time Span
	StartTimeVal=$(date -d "$StartTime" +%s)
	EndTimeVal=$(date -d  "$EndTime" +%s)
	TimeSpan=$(echo "${EndTimeVal}-${StartTimeVal}" | bc)
	TimeSpan_Hour=$(echo "${TimeSpan}/3600" | bc)
	[ ${#TimeSpan_Hour} -eq 1 ] && TimeSpan_Hour=$(echo "0$TimeSpan_Hour")
	TimeSpan=$(date -d @$TimeSpan +"${TimeSpan_Hour}:%M:%S")
	
	#Time spend from begin to end
	ps -ax |grep -v "awk" | awk '/time_stamp.sh/{print $1}'| while read PID
	do
		kill -9 "$PID" >& /dev/null
	done
	declare time_record_file='/TestAP/time_record.log'
	time_stamp=$(cat ${time_record_file} 2>/dev/null)
	rm -rf ${time_record_file} 2>/dev/null
	

	#                Cycle-Time Statistics for Function Test
	#----------------------------------------------------------------------
	#   Start Time: 2018-04-12 Thu 00:00:02 CST
	#  Finish Time: 2018-04-12 Thu 20:00:02 CST
	#    Span Time: 20:00:02
	# Program Time: 00:25:00
	#----------------------------------------------------------------------
	ShowTitle "Cycle-Time Statistics for Function Test"
	echo "----------------------------------------------------------------------"
	echo "   Start Time: ${StartTime}"
	echo "  Finish Time: ${EndTime}"
	echo "    Span Time: ${TimeSpan}"
	echo " Program Time: ${ProgramCostTimeTTL}"
	echo " Test process totol time cost: ${time_stamp} seconds"
	echo "----------------------------------------------------------------------"
}
#----Main function-----------------------------------------------------------------------------
declare -i ErrorFlag=0
declare CTConfigFile ProgramCostTimeCnt ProgramCostTimeTTL ApVersion
declare BaseName=$(basename $0 .sh)

if [ $# -lt 1 ] ; then
	Usage 
fi

#--->Get and process the parameters
while getopts :P:Vl: argv
do
	 case ${argv} in	
		l)
			CTConfigFile="${OPTARG}"
			if [ ! -s "${CTConfigFile}" ] ; then
				Process 1 "No such file or 0 KB size of file: ${CTConfigFile}"
				exit 2
			fi
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,CycleTime"
			exit 1
		;;		

		:)
			printf "\e[1;33m%-s\n\e[0m" "The option ${OPTARG} requires an argument."
			Usage
			exit 3
		;;
		
		?)
			printf "\e[1;33m%-s\n\n\e[0m" "Invalid option: ${OPTARG}"
			Usage
			exit 3			
		;;
		esac

done
	
main	
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
