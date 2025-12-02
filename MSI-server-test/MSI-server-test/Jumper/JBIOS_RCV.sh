#!/bin/bash
#FileName : JBIOS_RCV.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-06-29"
	local UpdatedDate="2019-07-04"
	local Description="BIOS recovery jumper status test"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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

Wait4nSeconds()
 {
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do   
		printf "\r\e[1;33mPlease wait about %02d seconds, press [Y/y] test at once ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ ${Ans}x == 'Yx' ] || [ ${Ans}x == 'y'x ] ; then
			break
		fi
	done
	echo
} 
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
Usage: 
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : BIOS recovery jumper status test pass
		1 : BIOS recovery jumper status test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Jumper>	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXVC1|Cap Pin insert error location</ErrorCode>
			
			<!--JBIOS_RCV.sh-->
			<!--Location is the marking of the jumper -->
			<Location>JBIOS_RVC</Location>
			
			<!--Command is command get the status of the jumper -->
			<Command>getRecovery</Command>
			
			<!--Normal/Short is command execute result code -->
			<NormalCode>1</NormalCode>
			<ShortCode>0</ShortCode>
			
			<!--TestMode is test mode, it should be NormalCode or 'NormalCode,ShortCode'  -->
			<TestMode>1,0</TestMode>
		</TestCase>
	</Jumper>
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
	Location=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	Command=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/Command" -n "${XmlConfigFile}" 2>/dev/null)
	NormalCode=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/NormalCode" -n "${XmlConfigFile}" 2>/dev/null)
	ShortCode=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/ShortCode" -n "${XmlConfigFile}" 2>/dev/null)
	TestMode=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/TestMode" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#TestMode} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

NormalStatus()
{
	CurStatus=$(./${Command} 2>/dev/null)
	if [ "${CurStatus}" == "${NormalCode}" ]; then
		Process 0 "${Location} Jumper is normal"
	else
		Process 1 "${Location} Jumper is short"
		return 1
	fi
	echo
}

ShortStatus ()
{
	CurStatus=$(./${Command} 2>/dev/null)
	if [ "${CurStatus}" == "${ShortCode}" ]; then
		Process 0 "${Location} Jumper is short"
	else
		Process 1 "${Location} Jumper is normal"
		return 1
	fi
	echo
}

main ()
{
	Tool=$(echo ${Command} | awk '{print $1}')
	if [ -f "$Tool" ] ; then
		md5sum $Tool
		chmod 777 $Tool
	else
		Process 1 "No such tool: ${Tool}"
		exit 2
	fi

	echo $TestMode | grep -iwq $NormalCode
	if [ $? != 0 ] ; then
		Process 1 "Invalid test mode code: $TestMode"
		echo "The test mode should include the code: $NormalCode"
		exit 4
	fi

	echo $TestMode | grep -iw $NormalCode | grep  -iwq $ShortCode 
	if [ $? == 0 ] ; then
		# Check normal and short status
		NormalStatus || exit 1
		ShowMsg --1 "Please install Jumpers in other pin(Short it)"
		Wait4nSeconds 15
		ShortStatus || exit 1
		ShowMsg --1 "Please uninstall Jumpers in RECOVERY(Normal)"
		Wait4nSeconds 15
		NormalStatus || exit 1
	else
		NormalStatus || exit 1
	fi
		
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "${Location} Jumper test"
		GenerateErrorCode
		exit 1
	else
		echoPass "${Location} Jumper test"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile Location Command NormalCode ShortCode TestMode
#Change the directory
cd ${WorkPath}/JBIOS >/dev/null 2>&1 
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

		P)
			printf "%-s\n" "SerialTest,JumperTest"
			exit 1
		;;		

		V)
			VersionInfo
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
