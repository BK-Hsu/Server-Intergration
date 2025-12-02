#!/bin/bash
#FileName : ChkMEVer.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-02"
	local UpdatedDate="2020-08-21"
	local Description="ME version verify"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Firmware/ME/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` -t DumpTool -v Version [ -x lConfig.xml ] [-DV]
	eg.: `basename $0` -v ES165IMS.10H -r 07/31/2017 -d 2
	eg.: `basename $0` -x lConfig.xml

	-D : Dump the sample xml config file	
	-t : Dump ME version tool
	-v : ME version 
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Compare ME version pass
		1 : Compare ME version fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Firmware>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXP15|PSU FIRMWARE CHECK NG</ErrorCode>
			<!-- ChkMEVer.sh: ME firmware -->
			<Tool>spsManufLinux64</Tool>
			<Version>3.1.30.18</Version>
		</TestCase>
	</Firmware>
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
	
	# Get the BIOS information from the config file(*.xml)
	METool=$(xmlstarlet sel -t -v "//Firmware/ME/TestCase[ProgramName=\"${BaseName}\"]/Tool" -n "${XmlConfigFile}" 2>/dev/null)
	Version=$(xmlstarlet sel -t -v "//Firmware/ME/TestCase[ProgramName=\"${BaseName}\"]/Version" -n "${XmlConfigFile}" 2>/dev/null)
	RegisterValue=$(xmlstarlet sel -t -v "//Firmware/ME/TestCase[ProgramName=\"${BaseName}\"]/Register1" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#Version} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

main()
{
	if [ -f "${METool}" ] ; then
		md5sum ${METool}
		chmod 777 ${METool}
	else
		Process 1 "No such tool: ${METool}"
		exit 2
	fi


	# Run program
	rm -rf ${BaseName}.log
	./${METool} | tee ${BaseName}.log
	CurVersion=$(cat ${BaseName}.log 2>/dev/null | awk '/FW version/{print $5}')
	cat ${BaseName}.log 2>/dev/null | grep -iw "FW version" | grep -iwq "${Version}"
	if [ $? -ne 0 ]; then
		echoFail "ME version verify"
		echo "   Current ME version is: ${CurVersion:-null}"
		echo "The ME version should be: ${Version}"
		GenerateErrorCode
		exit 1
	else
		echoPass "ME version(${Version}) verify"
		printf "%s" "MEVER: ${Version}" > ../../PPID/MEVER.TXT
		sync;sync;sync
	fi
	
	if [ ${#RegisterValue} == 0 ];then
		break
	else
		cat ${BaseName}.log 2>/dev/null | grep -iE "FW Status Register 1" | grep -iEq "${RegisterValue}"
		if [ $? -ne 0 ] ; then
			echoFail "ME FW Status Register 1 Check"
			CurrentValue=$(cat ${BaseName}.log 2>/dev/null |awk '/FW Status Register 1/{print $5}')
			echo "Current FW Register 1 is ${CurrentValue:-null}"
			echo "The FW Register 1 should be ${RegisterValue}"
			GenerateErrorCode
			exit 1
		else
			echoPass "ME FW Register 1(${RegisterValue}) check"
		fi
	fi

}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)/ME
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare BinFile='vsccommn.bin'
declare XmlConfigFile MEConfigFile METool Version RegisterValue ApVersion
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:t:v:VDx: argv
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
		
		t)
			METool=${OPTARG}
		;;
		
		v)
			Version=${OPTARG}
		;;
		
		V)
			VersionInfo
			exit 1
		;;

		P)
			printf "%-s\n" "SerialTest,CheckMEVersion"
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
