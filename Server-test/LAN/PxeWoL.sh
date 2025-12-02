#!/bin/bash
#FileName : PxeWoL.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-10-31"
	local UpdatedDate="2020-11-25"
	local Description="Check the PXE and WoL of LAN port"
	
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
	printf "%16s%-s\n" "" "2019-10-25,新增WoL功能測試 "
	printf "%16s%-s\n" "" "2020-11-25,修改条件 "
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
	local ErrorCode=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet bootutil64e)
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

ShowTitle()
{
	echo 
	local BlankCnt=0
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
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
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Check the PXE function pass
		1 : Check the PXE function fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<NetCard>		
		<TestCase>			
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>EXF17|LAN function test fail</ErrorCode>
			<!--範例說明
				<MacAddrFile>/TestAP/Scan/MAC1.TXT</MacAddrFile>
				<PXE>Enable或disable</PXE>
				<WoL>Yes或No</WoL>
			-->
			
			<Card>
				<MacAddrFile>/TestAP/Scan/MAC1.TXT</MacAddrFile>
				<PXE>Enable</PXE>
				<WoL>Yes</WoL>
			</Card>

			<Card>
				<MacAddrFile>/TestAP/Scan/MAC2.TXT</MacAddrFile>
				<PXE>Enable</PXE>
				<WoL>Yes</WoL>
			</Card>	
		</TestCase>
	</NetCard>
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
	MacAddrFiles=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/MacAddrFile" -n "${XmlConfigFile}" 2>/dev/null))
	PxeStatusSet=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/PXE" -n "${XmlConfigFile}" 2>/dev/null))
	WolStatusSet=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/WoL" -n "${XmlConfigFile}" 2>/dev/null))

	if [ ${#MacAddrFiles} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

main ()
{
	for ((m=0;m<${#MacAddrFiles[@]};m++))
	do
		if [ ! -s "${MacAddrFiles[$m]}" ] ; then
			Process 1 "No such MAC address file: ${MacAddrFiles[$m]}"
			let ErrorFlag++
		fi
	done
	[ ${ErrorFlag} != 0 ] && exit 2
	
	rm -rf ${BaseName}.log 2>/dev/null

	echo -e "\e[1;33mDump the information, please wait a moment ...\e[0m"
	<<-Info
	Intel(R) Ethernet Flash Firmware Utility
	BootUtil version 1.6.59.0
	Copyright (C) 2003-2017 Intel Corporation

	Type BootUtil -? for help

	Port Network Address Location Series  WOL Flash Firmware                Version
	==== =============== ======== ======= === ============================= =======
	  1   309C23955733     4:00.0 40GbE   YES UEFI,PXE Enabled              1.0.66
	  2   309C23955734     4:00.1 40GbE   YES UEFI,PXE Enabled              1.0.66
	  3   D8CB8AFADCE1    11:00.0 Gigabit NO  FLASH Not Present
	  4   D8CB8AFADCE2    14:00.0 Gigabit NO  FLASH Not Present
	Info
	(bootutil64e -E | grep -iv "NIC\|^$" | tee  ${BaseName}.log ) &
	for ((i=1;i<71;i++))
	do
		if [ ! -s "${BaseName}.log" ] ; then
			printf "%s" "."
			sleep 1
		else
			echo
			break
		fi
	done

	echo 
	if [ ${i} -gt 69 ] ; then
		ps ax | awk '/bootutil64e/{print $1}' | while read PID
		do
			kill -9 "${PID}" >& /dev/null
		done
		Process 1 "Time out!! Get the infomation of net card(s) ..."
		exit 1
	fi
	wait
	sync;sync;sync

	# Nic    Mac  Address           PXE           WoL           Test Result   
	#----------------------------------------------------------------------
	# 1      309C21477895          Enable         Yes             Pass
	# 2      309C21477895          Enable         No              Pass
	#----------------------------------------------------------------------
	ShowTitle "PXE and WoL function verify program"
	printf "%-8s%-23s%-14s%-14s%-11s\n" " Nic"    "Mac  Address" "PXE" "WoL" "Test Result"
	echo "----------------------------------------------------------------------"
	for ((m=0;m<${#MacAddrFiles[@]};m++))
	do
		local SubErrorFlag=0
		MacAddress=$(cat -v ${MacAddrFiles[$m]} | head -n1 )
		NicIndex=$(cat -v ${BaseName}.log | grep -iw "${MacAddress}" | awk '{print $1}' )
		
		printf "%-8s%-22s"  " ${NicIndex}" "${MacAddress}" 
		
		echo "${PxeStatusSet[$m]}" |  grep -iwq "enable\|Enabled"
		if [ $? == 0 ] ; then
			cat -v "${BaseName}.log" | grep -iw "${MacAddress}" | grep -iv 'disabled\|NOT' | grep -iwq "PXE"
		else
			cat -v "${BaseName}.log" | grep -iw "${MacAddress}" | grep -iwq 'disabled\|NOT\|Unknown'
		fi
		
		if [ $? != 0 ] ; then
			printf "\e[1;31m%-15s\e[0m" "${PxeStatusSet[$m]}" 
			let SubErrorFlag++
		else
			printf "%-15s" "${PxeStatusSet[$m]}" 
		fi
		
		echo "${WolStatusSet[$m]}" |  grep -iwq "Yes"
		if [ $? == 0 ] ; then
			cat -v "${BaseName}.log" | grep -iw "${MacAddress}" | grep -iwq "YES"
		else
			cat -v "${BaseName}.log" | grep -iw "${MacAddress}" | grep -iwq 'NO\|N/A'
		fi
		
		if [ $? != 0 ] ; then
			printf "\e[1;31m%-16s\e[0m" "${WolStatusSet[$m]}"
			let SubErrorFlag++
		else
			printf "%-16s" "${WolStatusSet[$m]}"
		fi
		
		if [ ${SubErrorFlag} == 0 ] ; then
			printf "\e[1;32m%-9s\e[0m\n" "Pass"
		else
			printf "\e[1;31m%-9s\e[0m\n" "Fail"
			let ErrorFlag++
		fi
	done
	echo "----------------------------------------------------------------------"
	echo
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "PXE and WoL function test"
		GenerateErrorCode
		exit 1
	else
		echoPass "PXE and WoL function test"
	fi	
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile
declare MacAddrFiles PxeStatusSet ApVersion
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
			printf "%-s\n" "SerialTest,CheckPXEandWoL"
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
