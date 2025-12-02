#!/bin/bash
#FileName : Stream.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-30"
	local UpdatedDate="2019-07-03"
	local Description="stream test"
	
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
	#printf "%16s%-s\n" "" "xx,xxxxx"
	echo
	exit 1
}

echoPass()
 { 	local String=$@ 
	echo -en "\e[1;32m ${String}\e[0m"
	[ ${#String} -gt 60 ] && pnt=70 || pnt=60
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;32m  PASS  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;32m${str// /-}\e[0m"
 }
 
echoFail()
 { 	local String=$@ 
	echo -en "\e[1;31m $String\e[0m"
	[ ${#String} -gt 60 ] && pnt=70 || pnt=60
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;31m  FAIL  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;31m${str// /-}\e[0m"
	BeepRemind 1 2>/dev/null
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

GenerateErrorCode()
{
	[ "${#pcb}" == "0" ] && return 0

	cd ${WorkPath} >/dev/null 2>&1 
	local ErrorCodeFile='../PPID/ErrorCode.TXT'
	local ErrorCode=$(xmlstarlet sel -t -v "//Stream/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
	if [ "${#ErrorCode}" != 0 ] ; then
		grep -iwq "${ErrorCode}" ${ErrorCodeFile} 2>/dev/null || echo "${ErrorCode}|${ShellFile}" >> ${ErrorCodeFile}
	else
		echo "NULL|NULL|${ShellFile}" >> ${ErrorCodeFile}
	fi
	sync;sync;sync
	return 0
}

ChkExternalCommands ()
{
	ExtCmmds=(xmlstarlet numactl)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			numactl)printf "%10s%s\n" "" "Please install: numactl-2.0.9-7.el7.x86_64.rpm";;
		esac
		
		let ErrorFlag++
	else
		chmod 777 ${_ExtCmmd}
	fi
	done
	[ ${ErrorFlag} != 0 ] && exit 127
}

ShowTitle()
{
	local BlankCnt=0
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                             ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}
 
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config StreamTool,format as: *.xml
	-V : Display version number and exit(1)
		
	return code:
		0 : Stream test pass
		1 : Stream test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Stream>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode></ErrorCode>		
			<!--stream.sh: Performance測試，注意內存和CPU會影響到-->
			<!--MinBaseRate:最低分值；MaxBaseRate:最高分值-->
			<MinBaseRate>80000</MinBaseRate>
			<MaxBaseRate>168000</MaxBaseRate>
		</TestCase>
	</Stream>
	Sample
	sync;sync;sync

	xmlstarlet val "${BaseName}.xml" >/dev/null 2>&1
	if [ $? != 0 ] ; then
		Process 1 "Invalid XML file: ${BaseName}.xml"
		xmlstarlet fo ${BaseName}.xml
		exit 3
	else
		Process 0 "Created the XML file: ${BaseName}.xml"
		exit 0
	fi
}

#--->Get the parameters from the config file
GetParametersFrXML  ()
{
	xmlstarlet val "${XmlConfigFile}" >/dev/null 2>&1
	if [ $? != 0 ] ; then
		xmlstarlet fo ${XmlConfigFile}
		Process 1 "Invalid XML file: ${XmlConfigFile}"
		exit 3
	fi  
	
	xmlstarlet sel -t -v "//ProgramName" -n "${XmlConfigFile}" 2>/dev/null | grep -iwq "${BaseName}"
	if [ $? != 0 ] ; then
		Process 1 "Thers's no configuration information for ${ShellFile}"
		exit 3
	fi
		 
	# Get the information from the config file(*.xml)
	MinBaseRate=$(xmlstarlet sel -t -v "//Stream/TestCase[ProgramName=\"${BaseName}\"]/MinBaseRate" -n "${XmlConfigFile}" 2>/dev/null)
	MaxBaseRate=$(xmlstarlet sel -t -v "//Stream/TestCase[ProgramName=\"${BaseName}\"]/MaxBaseRate" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#MinBaseRate} == 0 ] || [ ${#MaxBaseRate} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi

	return 0
}

main()
{
	BaseRate=($(echo "${MinBaseRate} ${MaxBaseRate}" | tr ' ' '\n' | sort -n))
	MinBaseRate=${BaseRate[0]}
	MaxBaseRate=${BaseRate[1]}

	if [ ! -f "${StreamTool}" ] ; then
		Process 1 "No such tool: ${StreamTool}"
		exit 2
	else
		chmod 777 "${StreamTool}" 2>/dev/null
		md5sum "${StreamTool}" 2>/dev/null
	fi

	# Begin testing
	export KMP_AFFINITY=compact

	# No    Triad      Score1        Score2        Score3        Score              
	#---------------------------------------------------------------------- 
	# 01    Triad      0.012956      0.007984      0.026659      60119.0 
	# 02    Triad      0.014973      0.009669      0.020277      49644.1 
	#----------------------------------------------------------------------	
	ShowTitle "The performance of memory test"
	printf "\e[1m%-7s%-12s%-13s%-14s%-14s%-10s\n\e[0m"  "No" "Triad" "Score1" " Score2" " Score3" " Score"  
	echo "----------------------------------------------------------------------"

	for((j=1;j<=${TestCnt};j++))
	do
		TriadInfo=()
		TriadInfo=($(numactl -l ./"${StreamTool}" 2>/dev/null | grep "Triad" | head -n1 | tr -d ':'))
		TriadInfo[0]=${TriadInfo[0]:-"Triad"}
		TriadInfo[1]=${TriadInfo[1]:-"0"}
		TriadInfo[2]=${TriadInfo[2]:-"-----"}
		TriadInfo[3]=${TriadInfo[3]:-"-----"}
		TriadInfo[4]=${TriadInfo[4]:-"-----"}

		Gap=$(echo "ibase=10;obase=10; ${TriadInfo[1]}-${MinBaseRate} " 2>/dev/null | bc)

		if [ $(echo ${Gap} | grep -c '-') == 1 ] ; then
			printf "\e[31m%-1s%02d%4s%-11s%-14s%-14s%-14s%-10s\n\e[0m" " " "${j}" "" "${TriadInfo[0]}" "${TriadInfo[2]}" "${TriadInfo[3]}" "${TriadInfo[4]}" "${TriadInfo[1]}" 
		else
			printf "%-1s%02d%4s%-11s%-14s%-14s%-14s%-10s\n"            " " "${j}" "" "${TriadInfo[0]}" "${TriadInfo[2]}" "${TriadInfo[3]}" "${TriadInfo[4]}" "${TriadInfo[1]}" 
		fi
		
		echo ${TriadInfo[1]} | grep -Eq "[0-9]" || continue
		TriadSummary=$(echo "ibase=10;obase=10; ${TriadSummary}+${TriadInfo[1]}" 2>/dev/null | bc)
		
	done
	echo "----------------------------------------------------------------------"

	# Calculate the average
	TriadAverage=$(echo "ibase=10;obase=10; ${TriadSummary}/${TestCnt}" | bc | tr -d ' ' | cut -b 1-8 )
	TriadAverage=${TriadAverage:-'0'}

	echo 
	echo "    Min Base Rate: ${MinBaseRate}"
	echo "    Max Base Rate: ${MaxBaseRate}"
	echo "Average Base Rate: ${TriadAverage}"
	echo

	if [ $TriadAverage -lt ${MinBaseRate} ] ; then
		echoFail "Average base rate is less than min base Rate, stream test"
		GenerateErrorCode
		exit 1
	fi

	if [ $TriadAverage -gt ${MaxBaseRate} ] ; then
		echoFail "$TriadAverage, out of upper limit: ${MaxBaseRate}"
		GenerateErrorCode
		exit 3
	fi

	echoPass "Stream test"
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -a TriadInfo=()
declare StreamTool='stream.20M'
declare -i TestCnt=20
declare TriadSummary=0
declare TriadAverage=0
declare XmlConfigFile MinBaseRate MaxBaseRate BaseRate ApVersion 
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:VDx: argv
do
	 case ${argv} in
		x)
			XmlConfigFile=${OPTARG}
			GetParametersFrXML
			break
		;;

		D)
			DumpXML
			break
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,StreamTest"
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
