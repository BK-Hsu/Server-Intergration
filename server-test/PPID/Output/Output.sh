#!/bin/bash
#FileName : Output.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2018-07-31"
	local UpdatedDate="2019-02-26"
	local Description="Count the function test output"
	
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
	`basename $0` -f CapacityOutputFile [-V]
	eg.: `basename $0` -f cap.out
	eg.: `basename $0` -V

	-f : Capacity output file
		 #Serial number|OPID
		 I716335458,00157193
	-V : Display version number and exit(1)
	
	return code:
		0 : Shell execute pass
		1 : Shell execute fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

main()
{
	PcbSN=$(cat -v PPID.TXT 2>/dev/null | head -n1)
	OpID=$(cat -v  OPID.TXT 2>/dev/null | head -n1)

	# Add current Pcb SN to out put file
	if [ ${#PcbSN} != 0 ] && [ ${#OpID} != 0 ] ; then
		cat -v ${OutputFile} 2>/dev/null | grep -iwq "$PcbSN,$OpID" 
		if [ $? != 0 ] ; then
			echo "$PcbSN,$OpID" >> ${OutputFile} 2>/dev/null
			sync;sync;sync
		fi	
	fi

	#  No.          OperatorID             Capacity            Grade
	#----------------------------------------------------------------------
	#  01            00157193                 168               A++
	#  02            00157194                 110               A+
	#  03            00157194                 98                A
	#  04            00157194                 60                B
	#----------------------------------------------------------------------
	i=1
	ShowTitle "Function test production and ranking"
	printf "%-15s%-23s%-20s%-12s\n" " No."  "OperatorID" "Capacity" "Grade"
	echo "----------------------------------------------------------------------"
	cat -v ${OutputFile} | sort -u | grep -v "#" | grep -v '^$' | awk -F',' '{print $2}' | tr -d ' ' | sort | uniq -c | sort -nr  -k 1 -t ' ' | while read LINE 
	do
		CapacityInfo=($LINE)
		printf "%1s%02d%12s%-25s%3d%-15s" "" "$((i++))" "" "${CapacityInfo[1]}" "${CapacityInfo[0]}" ""
		
		if [ "${CapacityInfo[0]}" -ge 50 ] ; then
			printf "\e[1;32m%-12s\n\e[0m" "A++"
			continue
		fi
		
		if [ "${CapacityInfo[0]}" -ge 40 ] ; then
			printf "\e[1;33m%-12s\n\e[0m" "A+"
			continue
		fi
		
		if [ "${CapacityInfo[0]}" -ge 30 ] ; then
			printf "\e[1;34m%-12s\n\e[0m" "A"
			continue
		fi
		
		if [ "${CapacityInfo[0]}" -ge 20 ] ; then
			printf "%-12s\n" "B"
			continue
		fi
			
		if [ "${CapacityInfo[0]}" -ge 10 ] ; then
			printf "%-12s\n" "C"
			continue
		fi
			
		if [ "${CapacityInfo[0]}" -ge 1 ] ; then
			printf "\e[1;31m%-12s\n\e[0m" "D"
			continue
		fi
	done
	echo "----------------------------------------------------------------------"

	# Add the record to main log
	if [ ${#pcb} != 0 ] ; then
		cat -v ${OutputFile} 2>/dev/null | sort -u  >> ${pcb}.log 2>/dev/null
		sync;sync;sync
	fi
}

#----Main function-----------------------------------------------------------------------------
declare -i ErrorFlag=0
declare OutputFile ApVersion
declare BaseName=$(basename $0 .sh)

if [ $# == 0 ] ; then
	Usage 
fi

#--->Get and process the parameters
while getopts :P:Vf: argv
do
	 case ${argv} in
		f)
			OutputFile=${OPTARG}
			if [ ! -s "${OutputFile}" ] ; then
				Process 1 "No such file or 0 KB size of file: ${OutputFile}"
				exit 2
			fi
			break
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,Capacity"
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
