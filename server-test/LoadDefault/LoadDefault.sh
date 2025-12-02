#!/bin/bash
#FileName : LoadDefault.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.1"
	local CreatedDate="2018-06-27"
	local UpdatedDate="2020-12-30"
	local Description="Set CMOS and OS setting as default"
	
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
	printf "%16s%-s\n" "" "2020-12-30,更新適用範圍"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//LoadDefault/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet LoadDefault)
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
	
	-D : Dump the xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Load default pass
		1 : Load default fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<LoadDefault>
		<TestCase>			
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode></ErrorCode>
			<!--LoadDefault.sh: CMOS和OS 初始化程式，不含日期時間在內的其他選項均會初始化 -->	
			<!--系統的時區和UTC狀態初始化-->
			<!-- # The time zone of the system is defined by the contents of /etc/localtime. -->
			<!-- # This file is only for evaluation by system-config-date, do not rely on its -->
			<!-- # contents elsewhere. -->
			<!-- ZONE="Asia/Taipei" -->
			<!-- UTC=false -->
			<ClockZone>Asia/Taipei</ClockZone>
			<UTC>false</UTC>
		</TestCase>					
	</LoadDefault>
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
	ClockZone=$(xmlstarlet sel -t -v "//LoadDefault/TestCase[ProgramName=\"${BaseName}\"]/ClockZone" -n "${XmlConfigFile}" 2>/dev/null)
	UTCStatus=$(xmlstarlet sel -t -v "//LoadDefault/TestCase[ProgramName=\"${BaseName}\"]/UTC" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#ClockZone} == 0 ] || [ ${#UTCStatus} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

LoadDefaultCMOS()
{
	${LoadDefaultTool} 2>/dev/null
	if [ "$?" == "0" ]; then
		Process 0 "Load default CMOS"
	else
		Process 1 "Load default CMOS"
		exit 1
	fi
}

LoadDefaultOS ()
{
	ClockZone=$(echo ${ClockZone} | tr -d '"' | tr -d "'" )
	ClockZone=${ClockZone:-"Asia/Taipei"}

	UTCStatus=$(echo ${UTCStatus} | tr -d '[[:punct:]]')
	UTCStatus=${UTCStatus:-"false"}
	OriginalUTCStatus=${UTCStatus}

	# Check System Clock uses UTC or not
	UTCStatus=$(echo ${UTCStatus} | tr [A-Z] [a-z] |grep -w "false\|true")
	if [ $? != 0 ] ; then
		Process 1 "Invalid UTC status: $OriginalUTCStatus"
		exit 1
	fi

	case ${UTCStatus} in
		'false')
			while :
			do
				grep -iwq "UTC" /etc/adjtime 2>/dev/null 
				if [ "$?" == 0 ] ; then
					Process 1 "UTC on, verify the UTC status fail ..."
					printf "%-10s%-60s\n" "" "Begin to turn off UTC ..."
					hwclock --systohc --localtime
					continue
				else
					Process 0 "UTC off, verify the UTC status ... "
					break
				fi
			done   
			;;

		'true')
			while :
			do
				grep  -iwq  "UTC" /etc/adjtime 2>/dev/null 
				if [ "$?" != 0 ] ; then
					Process 1 "UTC off, verify the UTC status fail ..."
					printf "%-10s%-60s\n" "" "Begin to turn on UTC ..."
					hwclock --systohc --utc
					continue
				else
					Process 0 "UTC on, verify the UTC status pass ..."
					break
				fi
			done   
		;;
		esac

	# Set Time Zone
	ls /usr/share/zoneinfo/${ClockZone} >/dev/null 2>&1
	if [ $? != 0 ] ; then
		Process 1 "No found time zone: /usr/share/zoneinfo/${ClockZone}"
		exit 2
	fi

	rm -rf /etc/localtime 2>/dev/null
	cp -rf /usr/share/zoneinfo/${ClockZone} /etc/localtime
	if [ $? == 0 ] ; then
		sync;sync;sync
		Process 0 "Set localtime Zone as ${ClockZone}"
	else
		Process 1 "Set localtime Zone as ${ClockZone}"
		exit 1
	fi

	# Change the clock setting, OS version Linux 7.x: 3; Linux 6.x: 2
	if [ "$OsVersion" -lt 3 ] ; then
		rm -rf /etc/sysconfig/clock
		cat<<-ClockZONE >>/etc/sysconfig/clock
		# The time zone of the system is defined by the contents of /etc/localtime.
		# This file is only for evaluation by system-config-date, do not rely on its
		# contents elsewhere.
		ZONE=${ClockZone}
		UTC=${UTCStatus}
		ClockZONE
		
		sync;sync;sync
	fi
}

LoadDefaultTestEnvironment ()
{
	# Define the config file ~/.bash_profile
	if [ $(grep -iw "PATH=\$PATH:\$HOME\/bin" ~/.bash_profile 2>/dev/null | wc -c) -lt 22 ] ; then
		sed -i "s/PATH=\$PATH:\$HOME\/bin/PATH=\$PATH:\$HOME\/bin:\/TestAP\/utility/g" ~/.bash_profile 2>/dev/null
		source ~/.bash_profile 2>/dev/null
	fi

	# Define the config file /etc/bashrc
	if [ $(grep -iwc "PATH=\$PATH:\$HOME\/bin:/TestAP/utility" /etc/bashrc 2>/dev/null ) == 0 ] ; then
		printf "%s\n" "PATH=\$PATH:\$HOME/bin:/TestAP/utility" >>/etc/bashrc 2>/dev/null
		source /etc/profile 2>/dev/null
	fi
	
	# Check current mode is graph mode and set graph mode,OS version Linux 7.x: 3; Linux 6.x: 2
	if [ ${OsVersion} -lt 3 ] ; then 
		# Linux 6.x
		GraphMode=$(cat /etc/inittab | grep "id:5:" 2>/dev/null)
	else
		# Linux 7.x
		GraphMode=$(systemctl get-default | grep "graphical" 2>/dev/null)
	fi

	case ${OsVersion} in
		[3-9])
			if [ ${#GraphMode} != 0 ] ; then
				TerminalFlag=$(grep -c "gnome-terminal" "/root/.bash_profile" 2>/dev/null)
				if [ -f /root/.bash_profile ] && [ ${TerminalFlag}x == "0"x ] ; then
					echo 'gnome-terminal --full-screen --zoom=1.3 -x bash -c "if [ -f /TestAP/TestAP.sh ] ; then /TestAP/TestAP.sh ; else /TestAP/TestAP ; fi ;exec bash"' >> /root/.bash_profile
				else
					[ ! -f /root/.bash_profile ] &&	echo 'gnome-terminal --geometry="85"x"25" --hide-menubar --zoom=1.3 -x bash -c "if [ -f /TestAP/TestAP.sh ] ; then /TestAP/TestAP.sh ; else /TestAP/TestAP ; fi ;exec bash"' > /root/.bash_profile
				fi
			fi
			sync;sync;sync
			;;

		2)
			#Do nothing
			：
		;;
		esac
		
	rm -rf /etc/udev/rules.d/70-persistent-net.rules
	rm -rf /etc/sysconfig/network-scripts/ifcfg-eth[0-99] 2>/dev/null
}

main()	
{
	LoadDefaultCMOS
	LoadDefaultOS
	LoadDefaultTestEnvironment

	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Load default CMOS and OS setting"
		GenerateErrorCode
		exit 1
	else
		echoPass "Load default CMOS and OS setting"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare OsVersion=$(uname -r | cut -c 1 )
declare XmlConfigFile ClockZone UTCStatus LoadDefaultTool GraphMode
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi

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
			printf "%-s\n" "SerialTest,SetCMOSDefault"
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
