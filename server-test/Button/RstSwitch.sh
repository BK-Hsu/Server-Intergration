#!/bin/bash
#FileName : RstSwitch.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-09"
	local UpdatedDate="2020-10-30"
	local Description="Reset switch or button test"
	
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
	printf "%16s%-s\n" "" "2020-10-30,修改cd ../../PPID为cd ../PPID"
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
	
	-D : Dump the xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Reset switch test pass
		1 : Reset switch test fail
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
			
			<!--RstSwitch.sh-->
			<Location>JFP1</Location>
			<MouseStatus>enable</MouseStatus>
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
	Mouse=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/MouseStatus" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

KeyBoardOnOff ()
{
	local Switch=$1

	if [ $# -eq 0 ] ; then
		echo -e "\e[1;31m Usage : KeyBoardOnOff on|off \e[0m "
		exit 3
	fi

	# Model of Keyboard
	KeyBoardID=()
	KeyBoardMode=($(cat /proc/bus/input/devices | grep -i "keyboard" | awk -F'=' '{print $2}'))
	SoleKeyBoardMode=($(echo ${KeyBoardMode[@]} | tr ' ' '\n' | sort -u ))
	SoleKeyBoardMode=$(echo ${SoleKeyBoardMode[@]} | sed 's/ /\\|/g')

	KeyBoardID=($(xinput list 2>/dev/null | grep -i "Keyboard" | grep -i "${SoleKeyBoardMode}"| awk -F'id=' '{print $2}' | awk '{print $1}'))
	  
	case $Switch in
		off)
			for ikey in ${KeyBoardID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 0 2>/dev/null
			done
			echo -e "\e[1;33m The Keyboard has been disable \e[0m "
		;;

		on)
			for ikey in ${KeyBoardID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 1 2>/dev/null 
			done
			echo -e "\e[1;32m The Keyboard has been enable  \e[0m "
		;;

		*)
			echo -e "\e[1;31m Usage: KeyBoardOnOff on|off \e[0m "
			exit 3
		;;
		esac
}

MouseOnOff ()
{
	local Switch=$1

	if [ $# -eq 0 ] ; then
		echo -e "\e[1;31m Usage: MouseOnOff on|off \e[0m "
		exit 3
	fi

	# Model of Mouse 
	MouseID=()
	MouseMode=($(cat /proc/bus/input/devices |grep -i "Mouse"|awk -F'=' '{print $2}'))
	SoleMouseMode=($(echo ${MouseMode[@]} | tr ' ' '\n' | sort -u ))
	SoleMouseMode=$(echo ${SoleMouseMode[@]} | sed 's/ /\\|/g')
	MouseID=($(xinput list 2>/dev/null | grep -i "Mouse" | grep -i "$SoleMouseMode" | awk -F'id=' '{print $2}' | awk '{print $1}'))


	case $Switch in
		off)
			for ikey in ${MouseID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 0 2>/dev/null
			done
			echo -e "\e[1;33m The Mouse has been disable \e[0m "
		;;

		on)
			for ikey in ${MouseID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 1 2>/dev/null 
			done
			echo -e "\e[1;32m The Mouse has been enable  \e[0m "
		;;

		*)
			echo -e "\e[1;31m Usage: MouseOnOff on|off \e[0m "
			exit 3
		;;
		esac
}

main()
{
	ShowMsg --1 "Press [ $Location Reset ] button/swicth to reset system."

	# load pc speaker driver
	modprobe pcspkr

	trap '' INT QUIT TSTP HUP 
	KeyBoardOnOff off
	if [ ${Mouse}x == 'disable'x ] ; then
		MouseOnOff off
	fi

	if [ ${#pcb} -ge 6 ] && [ ${EditProcFile} == 'enable' ]; then
		EditProcFile='disable'
		cd ../PPID
		echo "${ProcID}" > ${pcb}.proc
		md5sum ${pcb}.proc > .procMD5
		ProcID=$(($ProcID+1))
		echo "`basename $0` Test Pass In:`date "+%Y-%m-%d %a %H:%M:%S"` `date +%Z`,UTC/GMT`date +%z`" >> ${pcb}.log
		sync;sync;sync
		echo 
	fi

	local OsVersion=$(uname -r)
	while :
	do
		if [ "${OsVersion:0:1}" -lt "3" ] ; then 
			grep -iq "id:5:" /etc/inittab >/dev/null 2>&1
		else
			systemctl get-default | grep -iq "graphical" >/dev/null 2>&1
		fi

		if [ "$?" == 0 ] && [ -s "${WorkPath}/JFP/RST.jpg" ] ; then
			eog -f ${WorkPath}/JFP/RST.jpg 2>/dev/null &
		fi
		
		for ((i=10;i>=0;i--))
		do
			#echo -ne '\a' > /dev/console 2>/dev/null
			BeepRemind 1
			sleep 3
			
		done
		read
		echo
	done
	if [ ${ErrorFlag} != 0 ] ; then
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
declare Mouse='enable'
declare EditProcFile='enable'
declare XmlConfigFile Location
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
			printf "%-s\n" "SerialTest,ResetButtonTest"
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
