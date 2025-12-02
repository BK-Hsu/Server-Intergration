#!/bin/bash
#FileName : BmcReset.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.1"
	local CreatedDate="2019-01-16"
	local UpdatedDate="2020-08-25"
	local Description="BMC reset button test"
	
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
	printf "%16s%-s\n" "" "2020-08-25, 自定義復位最短耗時"
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
		
		case ${ExtCmmds[$c]} in
			ipmitool)printf "%10s%s\n" "" "ipmitool-1.8.18-7.el7.x86_64.rpm";;
		esac
		
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
		0 : BMC Reset button test pass
		1 : BMC Reset button test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
		
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<BMC>
		<TestCase>
			<!--BMC 復位按鈕測試程式-->
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXT20|BUTTON FAIL</ErrorCode>
			
			<BmcRest>
				<Location>JID_BMC</Location>
				<!--復位最短用時，單位：秒；復位用時越久越容易PASS-->
				<MinResetTime>2</MinResetTime>
			</BmcRest>
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
	Location=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/BmcRest/Location" -n "${XmlConfigFile}" 2>/dev/null)
	MinResetTime=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/BmcRest/MinResetTime" -n "${XmlConfigFile}" 2>/dev/null)
	MinResetTime=${MinResetTime:-"2"}
	Location=${Location:-"BMC_RESET"}
	return 0
}

main()
{
	modprobe ipmi_devintf
	if [ "$?" != "0" ]; then
		#Load IPMI Driver
		Process 1 "Load IPMI Driver ..."
		exit 1
	fi

	#Before BMC reset
	while :
	do
		rm -rf ${BaseName}_B.log 2>/dev/null
		(time ipmitool mc info ) > ${BaseName}_B.log 2>&1
		sync;sync;sync
		#real	0m11.769s
		cat -v ${BaseName}_B.log | grep -iwq "^real	0m0"
		if [ $? == 0 ]; then
			rm -rf ${BaseName}_B.log 2>/dev/null
			echo -e "\e[0;30;43m ******************************************************************** \e[0m"
			echo -e "\e[0;30;43m ***********       Press the BMC Reset button in 15s      *********** \e[0m"
			echo -e "\e[0;30;43m ***********       在倒計時的15秒鐘內按下BMC復位按鍵      *********** \e[0m"
			echo -e "\e[0;30;43m ******************************************************************** \e[0m"
			break
		else
			echo -e "\e[0;30;41m ******************************************************************** \e[0m"
			echo -e "\e[0;30;41m *********** BMC Reseting, do not interrupt this process! *********** \e[0m"
			echo -e "\e[0;30;41m ***********    BMC正在復位中，請不要中斷此程式           *********** \e[0m"
			echo -e "\e[0;30;41m ******************************************************************** \e[0m"	
		fi
	done

	#Wait for BMC reseting
	for((t=1;t<10000;t++))
	do	
		rm -rf ${BaseName}_R.log 2>/dev/null
		for ((p=15;p>=0;p--))
		do   
			(time ipmitool mc info ) > ${BaseName}_R.log 2>&1
			echo -ne "\e[1;33m`printf "\rPress the ${Location} button, time remained %02d seconds ...\n" "${p}"`\e[0m"
			#real	0m11.769s
			local RealTime=($(cat -v ${BaseName}_R.log 2>/dev/null | grep -iw "^real" | awk '{print $NF}' | awk -F'.' '{print $1}' | tr '[a-z]' " " ))
			local RealTimeSec=$(echo "obase=10;${RealTime[0]}*60+${RealTime[1]}+0" | bc )
			if [ ${RealTimeSec} -ge ${MinResetTime} ] && [ $(grep -ic "version" ${BaseName}_R.log 2>/dev/null) -ge 1 ]; then
				rm -rf ${BaseName}_R.log 2>/dev/null
				echo 
				echoPass "${Location} button test"
				break 2
			fi
			
			read -t 1
		done
		
		if [ ${t} -ge 3 ] ; then
			echo
			echoFail "${Location} button test"
			GenerateErrorCode
			break
		fi
		
		echo -e "\nTime out, try again ..."
	done

	[ ${ErrorFlag} != 0 ] && exit 1
	[ ${t} -ge 3 ] && exit 1
	exit 0
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare RealTime=0
declare XmlConfigFile Location BmcConfigFile MinResetTime
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
			printf "%-s\n" "SerialTest,ResetBMC"
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
