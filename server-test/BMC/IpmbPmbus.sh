#!/bin/bash
#FileName : IpmbPmbus.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-12-25"
	local UpdatedDate="2021-01-07"
	local Description="IPMB/PMBus function test"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet ipmitool)
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
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
		
	return code:
	   0 : IPMB or PMBus test pass
	   1 : IPMB or PMBus test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail
	
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<BMC>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NULL</ErrorCode>

			<Location>
				<!-- bus一般由BMC RD提供此參數,以下哪個位置不為空就測試那一項-->
				<PMBus bus="d">JPMBUS1</PMBus>
				<IPMB bus="0">JIPMB1</IPMB>		
			</Location>
		</TestCase>
	</BMC>
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
	PMBusLocation=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Location/PMBus" -n "${XmlConfigFile}" 2>/dev/null)
	PMBus_bus=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Location/PMBus/@bus" -n "${XmlConfigFile}" 2>/dev/null)
	IPMBLocation=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Location/IPMB" -n "${XmlConfigFile}" 2>/dev/null)
	IPMB_bus=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Location/IPMB/@bus" -n "${XmlConfigFile}" 2>/dev/null)
	#echo "${PMBus_bus}" | grep -iwEq "[0-9A-F]{1,2}"
	#if [ $? != 0 ] ; then
	#	Process 1 "${PMBusLocation} bus address is invalid ..."
	#	let ErrorFlag++
	#fi

	echo "${IPMB_bus}" | grep -iwEq "[0-9A-F]{1,2}"
	if [ $? != 0 ] ; then
		Process 1 "${IPMBLocation} bus address is invalid ..."
		let ErrorFlag++
	fi
	[ ${ErrorFlag} != 0 ]  && exit 3
	return 0			
}

main()
{
	for i in {1..2}
	do
		if [ "$i" -eq 1 ]; then
			Location=${PMBusLocation}
			#bus=$(echo "obase=16; ibase=10; ${PMBUS}*2+1" | bc)
			bus=${PMBus_bus}
			if [ "${PMBus_bus}x" == " "x ] ; then
				continue
			fi
		else
			Location=${IPMBLocation}
			#bus=0
			bus=${IPMB_bus}
		fi
		
		echo "${Location}" | grep -iEq "[0-9A-Z]" || continue
		
		data=''
		for j in {1..16}
		do
			tmp=$(printf "%02X" $((RANDOM % 256)))
			data="${data} 0x${tmp}"
		done

		eepaddr="0x"$(printf "%02X" $((RANDOM % 16 * 16)))

		ipmitool raw 0x06 0x52 0x"${bus}" 0xa0 0x00 "${eepaddr}" 0x00 ${data} > /dev/null 2>&1
		if [ "$?" -eq 0 ]; then
			sleep 1
			readdata=$(ipmitool raw 0x06 0x52 0x"${bus}" 0xa0 0x10 "${eepaddr}" 0x00 2> /dev/null | tr a-z A-Z | sed -e "s/ / 0x/g")
			echo "Write data: " $(echo "${data}" | sed -e "s/0x//g")
			echo "Read  data: " $(echo "${readdata}" | sed -e "s/0x//g")

			if [ "${data}" == "${readdata}" ]; then
				Process 0 "Check the ${Location} function pass"
			else
				Process 1 "Check the ${Location} function fail."
				printf "%10s\e[0;31m%s\e[0m\n" "" "The data read is inconsistent with the data written"
				let ErrorFlag++
			fi
		else
			Process 1 "Check ${Location} function fail"
			printf "\e[0;31m%s\e[0m\n" "This function requires plugging in the fixture: LD01-105001966 IPMB/PMBus."
			let ErrorFlag++
		fi
		sleep 1
		echo
	done

	if [ ${ErrorFlag} == 0 ]; then
		echoPass "${PMBusLocation} ${IPMBLocation} function test"
	else
		echoFail "${PMBusLocation} ${IPMBLocation} function test"
		let ErrorFlag++
		exit 1
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile PMBUS PMBusLocation IPMBLocation
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
			printf "%-s\n" "SerialTest,IpmbTest"
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
