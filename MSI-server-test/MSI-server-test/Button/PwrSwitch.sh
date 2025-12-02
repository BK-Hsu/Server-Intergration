#!/bin/bash
#FileName : PwrSwitch.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.3"
	local CreatedDate="2018-07-09"
	local UpdatedDate="2020-12-15"
	local Description="Power switch or button test"
	
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
	printf "%16s%-s\n" "" "2020-10-14,將關機鍵按下的事件記錄到PowerButton.log內,以便ChkPwrSwitch.sh檢查 "
	printf "%16s%-s\n" "" "2020-11-02,修正順測時路徑錯誤的問題,修改kill cat的方式 "
	printf "%16s%-s\n" "" "2020-12-15,即时将进程ID传变量sPID "
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
	ExtCmmds=(xmlstarlet acpid)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			acpid)printf "%10s%s\n" "" "Please install: acpid-2.0.19-6.el7.x86_64.rpm";;
		esac
		
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
		0 : Power switch test pass
		1 : Power switch test fail
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
			
			<!--PwrSwitch.sh-->
			<Location>JFP1</Location>
			<!--第幾個關鍵按鍵,缺省則全部應用-->
			<WhichEvent>1</WhichEvent>
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
	WhichEvent=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/WhichEvent" -n "${XmlConfigFile}" 2>/dev/null)
	
	if [ ${#WhichEvent} != 0 ] ; then
		if [ $(echo ${WhichEvent} | grep -iwEc "[1-9]" ) != 1 ] ; then
			Process 1 "Invalid 'WhichEvent': ${WhichEvent}"
			let ErrorFlag++
		fi
	fi
	
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi
	[ ${ErrorFlag} != 0 ] && exit 3
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
	local KeyBoardID=()
	local KeyBoardMode=($(cat /proc/bus/input/devices | grep -i "keyboard" | awk -F'=' '{print $2}'))
	SoleKeyBoardMode=($(echo ${KeyBoardMode[@]} | tr ' ' '\n' | sort -u ))
	SoleKeyBoardMode=$(echo ${SoleKeyBoardMode[@]} | sed 's/ /\\|/g')

	KeyBoardID=($(xinput list 2>/dev/null | grep -i "Keyboard" | grep -i "${SoleKeyBoardMode}"| awk -F'id=' '{print $2}' | awk '{print $1}'))
	  
	case $Switch in
		off)
			for ikey in ${KeyBoardID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 0 2>/dev/null
			done
			printf "\e[1;33m%s\e[0m\n" "The Keyboard has been disable ..."
		;;

		on)
			for ikey in ${KeyBoardID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 1 2>/dev/null 
			done
			printf "\e[1;32m%s\e[0m\n" "The Keyboard has been enable ..."
		;;

		*)
			printf "\e[1;31m%s\e[0m\n" "Usage: KeyBoardOnOff on|off ..."
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
			printf "\e[1;33m%s\e[0m\n" "The Mouse has been disable ..."
		;;

		on)
			for ikey in ${MouseID[@]}
			do
				xinput set-prop "$ikey" "Device Enabled" 1 2>/dev/null 
			done
			printf "\e[1;32m%s\e[0m\n" "The Mouse has been enable ..."
		;;

		*)
			printf "\e[1;31m%s\e[0m\n" "Usage: MouseOnOff on|off ..."
			exit 3
		;;
		esac
}

GetPowerButtonEvent()
{
	if [ ${#WhichEvent} == 0 ] ; then
		PowerButtonEvent=($(cat /proc/bus/input/devices 2>/dev/null | grep -iw -A8 "Power Button" | grep -iwE "event[0-9]" | tr ' ' '\n' | grep -iwE "event[0-9]" ))
	else
		PowerButtonEvent=($(cat /proc/bus/input/devices 2>/dev/null | grep -iw -A8 "Power Button" | grep -iwE "event[0-9]" | tr ' ' '\n' | grep -iwE "event[0-9]" | sed -n ${WhichEvent}p ))
	fi
	# I: Bus=0019 Vendor=0000 Product=0001 Version=0000
	# N: Name="Power Button"
	# P: Phys=LNXPWRBN/button/input0
	# S: Sysfs=/devices/LNXSYSTM:00/LNXPWRBN:00/input/input0
	# U: Uniq=
	# H: Handlers=kbd event0 
	# B: PROP=0
	# B: EV=3
	# B: KEY=10000000000000 0
	if [ ${#PowerButtonEvent[@]} == 0 ] ; then 
		cat /proc/bus/input/devices 2>/dev/null
		Process 1 "No found Handlers about Power Button ..."
		exit 2
	else
		for((p=0;p<${#PowerButtonEvent[@]};p++))
		do
			if [ $(ls /dev/input/ 2>/dev/null | grep -iwc "${PowerButtonEvent[p]}") == 0 ]; then				
				Process 1 "No found event about Power Button: ${PowerButtonEvent[p]} ..."
				let ErrorFlag++
			else
				Process 0 "Found event about Power Button: /dev/input/${PowerButtonEvent[p]} ..."
			fi
		done
		if [ ${ErrorFlag} != 0 ] ; then
			ls /dev/input/  2>/dev/null
			exit 2
		fi
	fi

}

KillPID()
{
	ps ax | awk '/cat \/dev\/input/{print $1}' | while read PID
	do
		kill -9 "${PID}" >& /dev/null
	done
}

PowerSwitchTest()
{ 
	#service acpid start
	#chkconfig acpid on
	ShowMsg --1 "Press [ $Location POWER ] button/swicth to shutdown system."
	# other setting
	#service acpid stop  
	#chkconfig acpid off 

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

	cd ${WorkPath} >/dev/null 2>&1 
	rm -rf ${BaseName}.log ${BaseName}.md5 2>/dev/null
		
	local OsVersion=$(uname -r)
	while :
	do
		if [ "${OsVersion:0:1}" -lt "3" ] ; then 
			grep -iq "id:5:" /etc/inittab >/dev/null 2>&1
		else
			systemctl get-default | grep -iq "graphical" >/dev/null 2>&1
		fi
		if [ "$?" == 0 ] ; then
			echo $Mouse | grep -iq 'disable'
			if [ $? == 0 ]; then
				cat /proc/version |grep -iw "Ubuntu" >/dev/null 2>&1
				if [ $? == 0 ]; then
					[ -s "${WorkPath}/JFP/PWR_KBMS.jpg" ] && xdg-open ${WorkPath}/JFP/PWR_KBMS.jpg 2>/dev/null &
				else
					[ -s "${WorkPath}/JFP/PWR_KBMS.jpg" ] && eog -f ${WorkPath}/JFP/PWR_KBMS.jpg 2>/dev/null &
				fi										
				
			else
				cat /proc/version |grep -iw "Ubuntu" >/dev/null 2>&1
				if [ $? == 0 ]; then
					[ -s "${WorkPath}/JFP/PWR_KB.jpg" ] && xdg-open ${WorkPath}/JFP/PWR_KB.jpg 2>/dev/null &	
				else
					[ -s "${WorkPath}/JFP/PWR_KB.jpg" ] && eog -f ${WorkPath}/JFP/PWR_KB.jpg 2>/dev/null &
				fi
			fi
		fi
		trap "echo OS shutdowning ... ; sleep 3; init 0" TERM
		BeepRemind 1
		cd ${WorkPath} >/dev/null 2>&1
		sPID=''
		for((p=0;p<${#PowerButtonEvent[@]};p++))
		do
			`cat /dev/input/${PowerButtonEvent[p]} 2>&1 >> ${WorkPath}/${BaseName}.log` &
			sPID=$(echo "${sPID} $!")
		done
		while :
		do
			if [ -s ${WorkPath}/${BaseName}.log ] ; then
				#kill -9 $(pgrep -P ${PIDKILL} cat)
				#KillPID
				# 2020/12/15更新
				kill -9 ${sPID} >/dev/null 2>&1
				md5sum ${WorkPath}/${BaseName}.log | tee ${WorkPath}/${BaseName}.md5
				
				# if [ ${#pcb} -ge 6 ] && [ ${EditProcFile} == 'enable' ]; then
				# 	EditProcFile='disable'
				# 	cd ../PPID
				# 	echo "${ProcID}" > ${pcb}.proc
				# 	md5sum ${pcb}.proc > .procMD5
				# 	echo "`basename $0` Test Pass In:`date "+%Y-%m-%d %a %H:%M:%S"` `date +%Z`,UTC/GMT`date +%z`" >> ${pcb}.log
				# 	echo 
				# fi
	
				sync;sync;sync
				trap : TERM
				break
			fi
		done
		BeepRemind 1
		sleep 3
		read
		echo
	done

	# For Check Logic
	init 0
	sleep 20
}

main()
{
	#GetPowerButtonEvent
	PowerSwitchTest
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
declare PATH=${PATH}:${UtilityPath}:`pwd`
declare PIDKILL=$$
declare -i ErrorFlag=0
declare Mouse='enable'
declare EditProcFile='enable'
declare XmlConfigFile Location PowerButtonEvent WhichEvent ApVersion
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
			printf "%-s\n" "SerialTest,PowerButtonTest"
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
