#!/bin/bash
#FileName : SwitchDP.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-11-05"
	local UpdatedDate="2019-07-04"
	local Description="Check the function of display port"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet xrandr)
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
	local Title="$@"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
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
	local second=$1
	local DPPort=$2
	# Wait for OP n secondes,and auto to run
	for ((p=${second};p>=0;p--))
	do
		if [ ${#DPPort} -gt 0 ] ; then
			xrandr | grep -w "${DPPort}" | grep -iw "connected" | grep -iwEq "[0-9]{3,4}x[0-9]{3,4}" && break	
		fi
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			break
		else
			continue
		fi
	done
	echo '' 
}

Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [-x lConfig.xml] [-DVd]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -d
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-d : Debug and get the disport	
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)	
		
	return code:
		0 : Check the dispay pass
		1 : Check the dispay fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}
DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<SwitchDP>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXLAQ|Not Displayed</ErrorCode>
			<!--For DisplaySW.sh-->
			
			<!--測試模式，Auto：自動切換，Manual:手動一拔一插切換，EdidOnly：只讀EDID-->
			<TestMode>Auto</TestMode>
			
			<!--讀取顯示器的EDID，Enable / disable-->
			<EdidTest>enable</EdidTest>
			
			<!--四則運算，Enable / disable-->
			<ArithmeticTest>enable</ArithmeticTest>
			

			<!--Port address | PCB marking -->
			<DPPort>eDP-1|JVGA1</DPPort>
			<DPPort>HDMI-1|HDMI1</DPPort>
			<DPPort>HDMI-2|DP1</DPPort>
		</TestCase>
	</SwitchDP>
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
	TestMode=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/TestMode" -n "${XmlConfigFile}" 2>/dev/null)
	EdidTest=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/EdidTest" -n "${XmlConfigFile}" 2>/dev/null)
	ArithmeticTest=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/ArithmeticTest" -n "${XmlConfigFile}" 2>/dev/null)
	PortSet=($(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/DPPort" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $1}'))
	PcbMarkingSet=($(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/DPPort" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $2}'))
	if [ ${#TestMode} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

ShowConnectDP ()
{
	rm -rf ${BaseName}.log 2>/dev/null
	xrandr > ${BaseName}.log 2>/dev/null
	<<-DisplayInfo
	 Screen 0: minimum 320 x 200, current 1920 x 1080, maximum 8192 x 8192
	eDP-1 connected primary 1280x1024+0+0 (normal left inverted right x axis y axis) 338mm x 270mm
	   1280x1024     60.02*+  75.02  
	   1280x960      75.04    60.00  
	   1152x864      75.00    75.00    70.00    60.00  
	   1024x768      60.04    75.03    70.07    60.00  
	   960x720       60.00  
	   928x696       75.00    60.05  
	   896x672       75.05    60.01  
	 
	   ......
	   
	HDMI-1 connected 1920x1080+0+0 (normal left inverted right x axis y axis) 477mm x 268mm
	   1920x1080     60.00*+  50.00    59.94  
	   1920x1080i    60.00    50.00    59.94  
	   1600x1200     60.00  
	   1680x1050     59.88  
	   1400x1050     59.95  
	   1600x900      60.00  
	   1280x1024     75.02    60.02  
	   ......
	   
	HDMI-2 connected 1366x768+0+0 (normal left inverted right x axis y axis) 344mm x 194mm
	   1366x768      59.79*+
	   1024x768      60.00  
	   800x600       60.32  
	   640x480       59.94  
	   720x400       70.08  
	DisplayInfo

	#  Display Port             Connected?                   Resolution
	#----------------------------------------------------------------------
	#   eDP-1                     Yes                      1920x1080+0+0   
	#   HDMI-1                    Yes                      1920x1080+0+0
	#   DVI                       No                            ---   
	#---------------------------------------------------------------------- 

	local DisplayPort=($(cat -v ${BaseName}.log | grep -iw "connected" | awk '{print $1}'  ))
	sync;sync;sync

	ShowTitle "Display port connected for debugging"

	printf "%-27s%-29s%-14s\n"  "Display Port"  "Connected?"     "Resolution"
	echo "----------------------------------------------------------------------"
	for ((d=0;d<${#DisplayPort[@]};d++))
	do
		printf "%-29s" "${DisplayPort[$d]}"
		cat -v ${BaseName}.log | grep -w "${DisplayPort[$d]}" | grep -iw "connected" | grep -iwEq "[0-9]{3,4}x[0-9]{3,4}" 
		if [ $? == 0 ] ; then
			Resolution=$(cat -v ${BaseName}.log | grep -w "${DisplayPort[$d]}" | sed 's/primary//g' | awk '{print $3}')
			printf "\e[1;32m%-25s\e[0m%-16s\n" "Yes" "${Resolution}"
		else
			printf "\e[1;31m%-25s\e[0m%-16s\n" "No"  "     ---"
			let ErrorFlag++
		fi	
	done
	echo "----------------------------------------------------------------------"
	[ ${ErrorFlag} != 0 ] && return 1
}

EdidTestFunc ()
{
	local DisplayPort=$1
	local DisplayName=$2
	# Usage: EdidTestFunc Port VGA

	#Get the EDID
	EDIDValue=$(xrandr --verbose | grep -iwA30 "$DisplayPort"  | grep -iA8 "EDID" | grep -v "EDID" | tail -n8 | tr -d "\t\n ")
	if [ $(echo "${EdidTest}" | grep -ic "enable") -ge 1 ]; then
		if [ ${#EDIDValue} -le 7 ]; then
			Process 1 "Fail to get the EDID of $DisplayName ..."
			exit 1	
		fi
	else
		return 0
	fi

	<<-EDIDString
		EDID: 
			00ffffffffffff0038a3146701010101
			0f14010308221b78eaf0c5a753469e24
			175054bfef80714f814f010101010101
			010101010101302a009851002a403070
			1300520e1100001e000000fd00384b1f
			510e000a202020202020000000fc004c
			434431373056580a20202020000000ff
			0030343330373838374e430a202000cd
	EDIDString
			
	if [ ${#EDIDValue} -gt 7 ] ; then
		echo "Get the EDID of ${DisplayName}:"
		rm -rf ${DisplayName}.edid 2>/dev/null
		echo "----------------------------------------------------------------------"	
		xrandr --verbose | grep -iwA30 "$DisplayPort"  | grep -A8 "EDID" | grep -v "EDID" | tail -n8 | tee ${DisplayName}.edid
		echo "----------------------------------------------------------------------" 
	fi
}

ArithmeticTestProgram ()
{
	if [ $(echo "${ArithmeticTest}" | grep -ic "enable") == 0 ]; then
		#ArithmeticTest=disable,does not need test
		# Usage: ArithmeticTestProgram VGA
		return 0
	fi

	local DisplayName=$1
	local Addend1=$(($RANDOM%6))
	local Addend2=$(($RANDOM%5))
	local AddendTTL='999'
	let AddendTTL=${Addend1}+${Addend2}
	echo -e "\e[0;30;43m ******************************************************************** \e[0m"
	echo -e "\e[0;30;43m *****       What is the result of the arithmetic:  ${Addend1}+${Addend2}=?       ***** \e[0m"
	echo -e "\e[0;30;43m ******************************************************************** \e[0m"
	BeepRemind 0
	read -p "Enter the result:  ${Addend1}+${Addend2}=" -n1 Answer
	Answer=${Answer:-"888"}
	if [ $(echo "${Answer}" | grep -wc "${AddendTTL}") == 1 ] ; then
		echo	
		Process 0 "${DisplayName} test"
		return 0
	else
		echo	
		echoFail "${DisplayName} test"
		GenerateErrorCode
		return 1
	fi
}

TurnOnAllDP()
{
	for((p=0;p<${#PortSet[@]};p++))
	do
		# Turn the 1st port on and other port off
		xrandr --output ${PortSet[$p]} --auto 2>/dev/null
	done
}

TurnOffAllDP()
{
	for((p=0;p<${#PortSet[@]};p++))
	do
		#Turn the 1st port on and other port off 
		xrandr --output ${PortSet[$p]} --off 2>/dev/null
	done
}

CompareEDID()
{
	local EDIDSet=($@)
	if [ $(echo "${EdidTest}" | grep -ic "enable") == 0 ]; then
		#EdidTest=disable,does not need test
		return 0
	fi

	for((e=0,f=1;f<${#EDIDSet[@]};e++,f++))
	do
		EDIDSetCode=$(diff ${EDIDSet[$e]} ${EDIDSet[$f]} 2>/dev/null)
		if [ "${#EDIDSetCode}" -le 2 ] ; then
			Monitor=$(echo ${EDIDSet[$e]} ${EDIDSet[$f]} | tr ' ' '\n' | awk -F'.' '{print $1}' | tr '\n' ' ')
			Process 1 "$Monitor are the same monitors. Display test"
			let ErrorFlag++
		fi
	done
	if [ ${ErrorFlag} != 0 ] ; then
		exit 1
	else
		echoPass "All EDIDs check"
	fi
}

# Turn the Primary port on and other port off
TurnOnPrimaryPort()
{
	for((p=0;p<${#PortSet[@]};p++))
	do
		if [  "${PortSet[$p]}"x == "${PrimaryPort}"x ]; then
			xrandr --output ${PortSet[$p]} --auto 2>/dev/null
		else
			xrandr --output ${PortSet[$p]} --off 2>/dev/null
		fi
	done
}

AutoSwitch()
{
	TurnOnPrimaryPort
	for ((d=0,e=1;d<${#PortSet[@]};d++,e++))
	do
		# Check Display
		xrandr | grep -w "${PortSet[$d]}" | grep -iw "connected" | grep -iwEq "[0-9]{3,4}x[0-9]{3,4}" 
		if [ $? != 0 ] ; then
			Process 1 "No found any ${PcbMarkingSet[$d]}"
			TurnOnPrimaryPort
			#TurnOnAllDP
			let ErrorFlag++
			continue
		fi
		
		EdidTestFunc "${PortSet[$d]}" "${PcbMarkingSet[$d]}"
		ArithmeticTestProgram "${PcbMarkingSet[$d]}"
		if [ $? == 0 ] ; then
			if [ $e -lt ${#PortSet[@]}  ] ; then
			# Turn on next and turn off the last dispay
			xrandr | grep -w "${PortSet[$e]}" | grep -iwq "connected"  2>/dev/null
			if [ $? != 0 ] ; then
				Process 1 "Check the connection of ${PcbMarkingSet[$e]}"
				let ErrorFlag++
				continue
			fi
			# Suit for S1901,CentOS7.x
			TurnOnPrimaryPort
			echo "xrandr --output ${PortSet[$e]} --auto --same-as ${PrimaryPort} "
			echo "xrandr --output ${PrimaryPort} --auto --left-of ${PortSet[$e]} "

			xrandr --output ${PortSet[$e]} --auto --same-as ${PrimaryPort} 
			sleep 2
			xrandr --output ${PrimaryPort} --auto --left-of ${PortSet[$e]} 
			if [ $? != 0 ] ; then
				Process 1 "Turn on the port of ${PcbMarkingSet[$e]}"
				let ErrorFlag++
			fi
			fi
		else
			TurnOnPrimaryPort
			#TurnOnAllDP
			exit 1
		fi
	done
}

OneByOneSwitch()
{
	TurnOnPrimaryPort
	# Turn the Primary port on and other port off 

	for ((d=0;d<${#PortSet[@]};d++))
	do
		echo
		ShowMsg --1 "Connect the monitor on the port of ${PcbMarkingSet[$d]} "
		Wait4nSeconds 15 "${PortSet[$d]}"
		# Check Display
		xrandr | grep -w "${PortSet[$d]}" | grep -iw "connected" | grep -iwEq "[0-9]{3,4}x[0-9]{3,4}" 
		if [ $? != 0 ] ; then
			Process 1 "No found any ${PcbMarkingSet[$d]}"
			TurnOnAllDP
			let ErrorFlag++
			continue
		fi
		
		EdidTestFunc "${PortSet[$d]}" "${PcbMarkingSet[$d]}"
		ArithmeticTestProgram "${PcbMarkingSet[$d]}"
		if [ $? != 0 ] ; then
			TurnOnPrimaryPort
			TurnOnAllDP
			exit 1
		fi
		
			xrandr --output ${PortSet[$e]} --auto --same-as ${PrimaryPort} 
			xrandr --output ${PrimaryPort} --auto --left-of ${PortSet[$e]} 
		if [ $? != 0 ] ; then
			Process 1 "Turn on the port of ${PcbMarkingSet[$d+1]}"
			let ErrorFlag++
		fi
	done
}

ReadEDIDOnly()
{
	for ((d=0;d<${#PortSet[@]};d++))
	do
		# Check Display
		xrandr | grep -w "${PortSet[$d]}" | grep -iw "connected" | grep -iwEq "[0-9]{3,4}x[0-9]{3,4}" 
		if [ $? != 0 ] ; then
			Process 1 "No found any ${PcbMarkingSet[$d]}"
			TurnOnPrimaryPort
			#TurnOnAllDP
			let ErrorFlag++
			continue
		fi
		
		EdidTestFunc "${PortSet[$d]}" "${PcbMarkingSet[$d]}"
	done
}

main()
{
	PrimaryPort=$(xrandr | grep -iw "primary" | grep -iw "connected" | grep -iwE "[0-9]{3,4}x[0-9]{3,4}" | awk '{print $1}' )
	ExcludePrimaryPortSet=($(echo ${PortSet[@]} | tr ' ' '\n' | grep -v "${PrimaryPort}" ))
	PortSet=($(echo "${PrimaryPort} ${ExcludePrimaryPortSet[@]}" ))

	<<-Msg
	xrandr常用命令（这里的VGA与LVDS分别换成第1步中的设备名，如VGA1、LVDS1）：
	xrandr --output VGA --same-as LVDS --auto
	打开外接显示器(--auto:最高分辨率)，与笔记本液晶屏幕显示同样内容（克隆）
	xrandr --output VGA --same-as LVDS --mode 1280x1024
	打开外接显示器(分辨率为1280x1024)，与笔记本液晶屏幕显示同样内容（克隆）
	xrandr --output VGA --right-of LVDS --auto
	打开外接显示器(--auto:最高分辨率)，设置为右侧扩展屏幕
	xrandr --output VGA --off
	关闭外接显示器
	xrandr --output VGA --auto --output LVDS --off
	打开外接显示器，同时关闭笔记本液晶屏幕（只用外接显示器工作）
	xrandr --output VGA --off --output LVDS --auto
	关闭外接显示器，同时打开笔记本液晶屏幕 （只用笔记本液晶屏）
	--------------------- 
	作者：二进制程序猿 
	来源：CSDN 
	原文：https://blog.csdn.net/syh_486_007/article/details/71158022?utm_source=copy 
	版权声明：本文为博主原创文章，转载请附上博文链接！
	Msg
	rm -rf *.edid 2>/dev/null
	case ${TestMode} in
		auto) AutoSwitch;;
		manual) OneByOneSwitch;;
		*) ReadEDIDOnly;;
		esac

	CompareEDID `ls *.edid 2>/dev/null`
	#TurnOnPrimaryPort
	TurnOnAllDP
	[ ${ErrorFlag} != 0 ] && exit 1
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile
declare PortSet PcbMarkingSet EdidTest TestMode ArithmeticTest
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:VdDx: argv
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
		
		d)
			ShowConnectDP
			exit 20
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,SwitchDisplay"
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
#TurnOnPrimaryPort
TurnOnAllDP
[ ${ErrorFlag} != 0 ] && exit 1
exit 0


