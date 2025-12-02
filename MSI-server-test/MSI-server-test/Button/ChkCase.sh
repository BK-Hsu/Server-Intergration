#!/bin/bash
#FileName : ChkCase.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-09"
	local UpdatedDate="2019-07-04"
	local Description="Chassis case switch functional test"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet )
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"	
		let ErrorFlag++
	else
		chmod 777 ${_ExtCmmd}
	fi
	done
	[ ${ErrorFlag} != 0 ] && exit 127
}

ShowMsg ()
{
	local LineId=$1
	local TextMsg=${@:2:70}
	TextMsg=${TextMsg:0:60}

	echo $LineId | grep -iEq  "[1-9BbEe]"
	if [ $? -ne 0 ] ; then
		echo " Usage: ShowMsg --[n|[B|b][E|e]] TextMessage"
		echo "        n=1,2,3,...,9"
		exit 3
	fi

	#---> Show Message
	case $LineId in
		--1)	
			printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
			printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "${TextMsg}"  "** "
			printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
		;;

		--[Bb])
			printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
			printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "${TextMsg}"  "** "
		;;
		
		--[2-9])
			printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "${TextMsg}"  "** "
		;;
		
		--[Ee])
			printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "${TextMsg}"  "** "
			printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
		;;
		esac
}

#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` -x lConfig.xml [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Chassis case switch test pass
		1 : Chassis case switch test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Button>	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXT20|BUTTON FAIL</ErrorCode>
			
			<!--ChkCase.sh-->
			<Tool>Case</Tool>
			<!-- pcb marking -->
			<Location>JCI1</Location>
		</TestCase>		
	</Button>
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

#--->Get the parameters from the XML config file
GetParametersFrXML ()
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
	Location=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	CaseTool=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/Tool" -n "${XmlConfigFile}" 2>/dev/null)
	TestStatus=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/Status" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#CaseTool} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

CheckCaseTest ()
{
	local CaseStatus=0

	if [ -f "${CaseTool}" ] ; then
		chmod 777 ${CaseTool}
		md5sum ${CaseTool}
	else
		Process 1 "No such tool: ${CaseTool}"
		exit 2
	fi

	ShowMsg --b "Please pay attention to the ${Location} switch."
	ShowMsg --e "Follow the instruction to operate ... "

	# load pc speaker driver
	BeepRemind 0

	for ((p=15;p>0;p--))
	do
		if [ "${CaseStatus}" == "0" ] ; then
			# Short test
			printf "\rTime remaining %02d seconds, please \e[1;31m[ press $Location ]\e[0m 2-pin switch." "${p}"
			./${CaseTool} 5 >/dev/null 2>&1
			if [ "$?" == "0" ]; then
				CaseStatus=1
			else
				sleep 1
			fi
		else
			# Open test
			#echo -ne '\a' > /dev/console 2>/dev/null
			printf "\rTime remaining %02d seconds, please \e[1;32m[ release ${Location} ]\e[0m 2-pin switch." "${p}"  
			./${CaseTool} 5 >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				break
			else
				sleep 1
			fi
		fi
	done
	echo

	if [ ${p} -le 0 ] ; then
		echoFail "Time out, ${Location} chassis case switch test"
		GenerateErrorCode
		BeepRemind 1
		exit 1
	else
		echoPass "${Location} chassis case switch test"
	fi
}

Checkjumper()
{
	local status=$1
	if [ $status == "open" ] ; then
		ipmitool raw 0x38 0x06 0x00 | grep -iwq "00"
		if [ $? != 0 ] ; then
			echoFail "The ${Location} jumper is wrong"
			GenerateErrorCode
			BeepRemind 1
			exit 1
		fi
		for((t=1;t<10000;t++))
		do	
		for ((p=15;p>=0;p--))
		do   
			printf "\rPress the \e[1;33m${Location}\e[0m switch, time remained %02d seconds ..." "${p}"
			ipmitool raw 0x38 0x06 0x00 | grep -iwq "01"
			if [ $? == 0 ]; then
				echo 
				Process 0 "${Location} switch short test"
				break 2
			fi
			
			read -t 1
		done
		
		if [ ${t} -ge 3 ] ; then
			echo
			echoFail "${Location} switch test"
			GenerateErrorCode
			break
		fi
		
		echo -e "\nTime out, try again ..."
		done
		[ ${t} -ge 3 ] && exit 1
		sleep 1
		for((t=1;t<10000;t++))
		do	
		for ((p=15;p>=0;p--))
		do 
			printf "\rRemove the \e[1;33m${Location}\e[0m switch, time remained %02d seconds ..." "${p}"
			ipmitool raw 0x38 0x06 0x01 | grep -iwq "00"
			if [ $? != 0 ]; then
				Process 1 "clear instrusion Status"
				read -t 1
				continue
			fi

			ipmitool raw 0x38 0x06 0x00 | grep -iwq "00"
			if [ $? == 0 ]; then
				echo
				echoPass "${Location} switch test"
				break 2
			fi
			read -t 1
		done
		if [ ${t} -ge 3 ] ; then
			echo
			echoFail "${Location} switch test"
			GenerateErrorCode
			break
		fi
		echo -e "\nTime out, try again ..."
		done
		[ ${t} -ge 3 ] && exit 1
		exit 0
	fi

	if [ $status == "short" ] ; then
		ipmitool raw 0x38 0x06 0x00 | grep -iwq "00"
		if [ $? == 0 ]; then
				echo 
				echoPass "${Location} switch is in short status"
				exit 0
		else
			echo
			echoFail "${Location} switch test"
			GenerateErrorCode
			exit 1
		fi
	fi

	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile Location CaseTool ApVersion TestStatus
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
			printf "%-s\n" "SerialTest,CheckChassisButton"
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

#echo "$TestStatus" | grep -iwq "Short"
#if [ $? == 0 ];then
Checkjumper "open"
#else
#	CheckCaseTest
#fi

if [ $? != 0 ];then
	eixt 1
fi
	
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
