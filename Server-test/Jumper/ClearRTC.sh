#!/bin/bash
#FileName : ClearRTC.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2020-09-22"
	local UpdatedDate="2020-09-22"
	local Description="Clear CMOS or RTC function test"
	
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
	ExtCmmds=(xmlstarlet hwclock)
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
	   0 : Clear CMOS/RTC test pass
	   1 : Clear CMOS/RTC test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Jumper>
		<TestCase>
			<!--不能修改程式名稱-->
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS46|CMOS time fail</ErrorCode>
			
			<!--此條碼禁止在開機的時候跳到非默認位置-->
			<!--條碼位置-->
			<Location>JCMOS1</Location>
			<!-- DefaultDate為Clear CMOS或RTC後的默認日期--> 
			<DefaultDate>2020/01/01</DefaultDate>
			
			<!--SetDate設置測試pass後設置的日期，必須大於DefaultDate的日期-->
			<SetDate>2020/09/01</SetDate>
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
	DefaultDate=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/DefaultDate" -n "${XmlConfigFile}" 2>/dev/null)
	SetDate=$(xmlstarlet sel -t -v "//Jumper/TestCase[ProgramName=\"${BaseName}\"]/SetDate" -n "${XmlConfigFile}" 2>/dev/null)
	TestAPReleaseDate=$(xmlstarlet sel -t -v "//ReleaseInfo/Update" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#Location} == 0 ] || [ ${#DefaultDate} == 0 ] || [ ${#SetDate} == 0 ] ; then
		Process 1 "Location, DefaultDate or SetDate is null ... "
		exit 3
	fi
	
	if [ ${#TestAPReleaseDate} == 0 ] ; then
		TestAPReleaseDate=${SetDate}
	fi
	
	return 0			
}

ResetDate()
{
	local SetDateVal=$(date -d "${SetDate}" +%s 2>/dev/null)
	local SetDateFmt=$(date -d @${SetDateVal} +"%Y-%m-%d %H:%M:%S %A")
	for((t=0;t<3;t++))
	do
		echo -e "Set the OS local date as: ${SetDateFmt}"
		date -s "${SetDate}" >/dev/null 2>&1
		hwclock --systohc 2>/dev/null
		if [ "$?" -eq 0 ]; then
			Process 0 "Synchronizing OS time to CMOS time"
		else
			Process 1 "Synchronizing OS time to CMOS time"
			printf "%10s%-s\n" "" "Try again ..."
		fi
		sleep 2
		local CmosDT=$(hwclock -r 2>/dev/null)
		local CmosDTVal=$(date -d "$CmosDT" +%s)
		
		echo "${CmosDTVal}-${SetDateVal}>0" | bc | grep -iwq "1"
		if [ $? == 0 ] ; then
			break
		fi
		
	done
	[ ${t} -ge 3 ] && exit 1
	return 0
	
}

main()
{
	echo ${BaseName} | grep -iwq "ClearRTC"
	if [ $? != 0 ];then
		Process 1 "Invalid shell name \"${BaseName}.sh\""
		printf "%10s%-s\n" "" "Valid name should be: ClearRTC.sh"
		exit 1	
	fi
	
	history -r >/dev/null 2>&1
	local dateSetCmd=$(history 30 | grep -iwc "date -s")
	if [ ${dateSetCmd} != 0 ] ; then
		Process 1 "Manual setting date and time ..."
		exit 1
	fi
	printf "\e[0;30;43m%-70s\e[0m\n" "**********************************************************************"
	printf "\e[0;30;43m%-70s\e[0m\n" "*****                  Clear RTC function test                   *****"
	printf "\e[0;30;43m%-70s\e[0m\n" "**********************************************************************"
	
	local DefaultDateVal=$(date -d "${DefaultDate}" +%s 2>/dev/null)
	local SetDateVal=$(date -d "${SetDate}" +%s 2>/dev/null)
	local TestAPReleaseDateVal=$(date -d "${TestAPReleaseDate}" +%s 2>/dev/null)
	if [ ${TestAPReleaseDateVal} -gt ${SetDateVal} ]; then
		SetDateVal=${TestAPReleaseDateVal}
	fi
	
	if [ ${#DefaultDateVal} == 0 ] ; then
		Process 1 "Invalid \"DefaultDate\" in ${XmlConfigFile} "
		let ErrorFlag++
	fi
	
	if [ ${#SetDateVal} == 0 ] ; then
		Process 1 "Invalid \"SetDate\" in ${XmlConfigFile} "
		let ErrorFlag++
	fi	
	[ ${ErrorFlag} != 0 ] && exit 1
	
	if [ ${DefaultDateVal} -ge ${SetDateVal} ] ; then
		Process 1 "Error setting: ${DefaultDate} >= ${SetDate} "
		exit 1
	fi
	
	local CmosDT=`hwclock -r 2>/dev/null`
	local CmosDTVal=$(date -d "$CmosDT" +%s)
	local CmosDateTime=$(date -d @${CmosDTVal} +"%Y-%m-%d %H:%M:%S %A")
	local DefaultDateFmt=$(date -d @${DefaultDateVal} +"%Y-%m-%d %H:%M:%S %A")
	echo 
	printf "%14s%3s%s\n" "Default Date" ": " "${DefaultDateFmt}"
	printf "%14s%3s%s\n" "CMOS Date" ": " "${CmosDateTime}"
	echo 
	echo "${CmosDTVal}-${DefaultDateVal}>0" | bc | grep -iwq "1"
	if [ $? == 0 ] && [ $(echo "${CmosDTVal}-${DefaultDateVal}<86400" | bc | grep -iwc "1") == 1 ] ; then
		ResetDate
		echoPass "Real time clock(RTC) loaded default test... "
	else
		printf "%-s\n" "Try clear RTC with \"${Location}\" again ..."
		echoFail "Real time clock(RTC) loaded default test ... "
		GenerateErrorCode
		exit 1
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile Location DefaultDate SetDate TestAPReleaseDate
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
			printf "%-s\n" "SerialTest,JumperTest"
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
