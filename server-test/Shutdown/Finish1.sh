#!/bin/bash
#============================================================================================
#        File: PwrSwitch.sh
#    Function: Power switch or button test
#     Version: 1.2.0
#      Author: Cody,qiutiqin@msi.com
#     Created: 2018-07-09
#     Updated: 2020-08-25
#  Department: Application engineering course
#        Note: 將關機鍵按下的事件記錄到PowerButton.log內,以便ChkPwrSwitch.sh檢查
# Environment: Linux/CentOS
#============================================================================================
#----Define sub function---------------------------------------------------------------------
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
`basename $0` -x lConfig.xml
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml		
	
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
			<ProgramName>PwrSwitch</ProgramName>
			<ErrorCode>TXT20|BUTTON FAIL</ErrorCode>
			
			<!--PwrSwitch.sh-->
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
	PowerButtonEvent=$(cat /proc/bus/input/devices 2>/dev/null | grep -iw -A8 "Power Button" | grep -iwE "event[0-9]" | tr ' ' '\n' | grep -iwE "event[0-9]")
	# I: Bus=0019 Vendor=0000 Product=0001 Version=0000
	# N: Name="Power Button"
	# P: Phys=LNXPWRBN/button/input0
	# S: Sysfs=/devices/LNXSYSTM:00/LNXPWRBN:00/input/input0
	# U: Uniq=
	# H: Handlers=kbd event0 
	# B: PROP=0
	# B: EV=3
	# B: KEY=10000000000000 0
	if [ ${#PowerButtonEvent} == 0 ] ; then 
		cat /proc/bus/input/devices 2>/dev/null
		Process 1 "No found Handlers about Power Button ..."
		exit 2
	else
		if [ ! -e "/dev/input/${PowerButtonEvent}" ]; then
			ls /dev/input/
			Process 1 "No found event about Power Button ..."
			exit 2
		else
			PowerButtonEvent="/dev/input/${PowerButtonEvent}"
			Process 0 "Found event about Power Button: ${PowerButtonEvent} ..."
		fi
	fi

}

ShutdownOS ()
{
	InitializingNetCard
	echo -e "\033[1;37;42m ******************************************************************** \033[0m"
	echo -e "\033[1;37;42m *          All function test items are tested and passed           * \033[0m"
	echo -e "\033[1;37;42m *          Please press [Y] to shutdown OS                        * \033[0m"
	echo -e "\033[1;37;42m ******************************************************************** \033[0m"

	while :
	do

		for ((p=5;p>=0;p--))
		do   
			printf "\r\e[1;33mOS will shutdown after %02d sec,press [Y] execute at once ...\e[0m" "${p}"
			read -t1 -n1 -s Ans
			if [ $(echo "$Ans" | grep -ic 'q\|y') == 1 ] ;  then
				echo
				break
			fi
		done

		Ans=${Ans:-'y'}
		
		case $Ans in
		Y|y)
			PowerSwitchTest
			;;

		Q|q)
			#Enter debug mode,because of "trap" command
			echo -e "\033[1;37;44m ******************************************************************** \033[0m"
			echo -e "\033[1;37;44m *             Welcome to debug mode, for PTE/PE only !             * \033[0m"
			echo -e "\033[1;37;44m ******************************************************************** \033[0m"
			exit 1
			;;
			
		*)
			ShowMsg --1 "Press the wrong key,Please press Y key "
			sleep 2
			;;
			esac
	done
	sync;sync;sync
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
	#KeyBoardOnOff off
	if [ ${Mouse}x == 'disable'x ] ; then
		MouseOnOff off
	fi

	OsVersion=$(uname -r)
	while :
	do
		if [ "${OsVersion:0:1}"x == "2"x ] ; then 
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
		
		BeepRemind 1
		rm -rf PoweButton.log PoweButton.md5 2>/dev/null
		cat ${PowerButtonEvent} 2>&1 > PoweButton.log &
		while :
		do
			if [ -s PoweButton.log ] ; then
				kill -9 $(pgrep -P ${PIDKILL} cat)
				md5sum PoweButton.log | tee PoweButton.md5
				sync;sync;sync
				break
			fi
		done
		BeepRemind 1
		read
		sleep 10
		echo
	done

	# For Check Logic
	init 0
	sleep 20
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare PATH=${PATH}:${UtilityPath}:`pwd`
declare PIDKILL=$$
declare -i ErrorFlag=0
declare Mouse='disable'
declare EditProcFile='enable'
declare XmlConfigFile Location PowerButtonEvent
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`
Location="JFP1"


#if [ $# -lt 1 ] ; then
#	Usage 
#fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :Dx: argv
do
	 case ${argv} in
		x)
			:
		;;
		
		D)
			DumpXML
			break
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

#GetPowerButtonEvent
ShutdownOS
	
if [ ${ErrorFlag} != 0 ] ; then
	GenerateErrorCode
	exit 1
fi
exit 0
