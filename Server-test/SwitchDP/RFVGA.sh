#!/bin/bash
#FileName : RFVGA.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-08-20"
	local UpdatedDate="2020-08-26"
	local Description="通過在指定時間內獲取顯示器的規格區分前/後置顯示器是否正常顯示"
	
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
	printf "%16s%-s\n" "" "2020-08-26,增加隨機算式"
	printf "%16s%-s\n" "" "2023-02-23,随机算术暂时未打开"
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
	ExtCmmds=(xmlstarlet edid-decode)
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
	   0 : Check Rear and Front VAG pass
	   1 : Check Rear and Front VAG fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

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
			<!--同時接Rear和Front顯示接口的時候只有一個可以顯示,程式提示移除其中的一個顯示器-->
			<!--再次讀到顯示器的相關規格的時間間隔不超過以下設定的時間則PASS-->
			<!--測試過程需使用不同規格的顯示器-->
			<TimeInterval>0.5</TimeInterval>
			<!--enable/Disable校驗/不校驗顯示器的EDID，讀出EDID版本不為0.0即PASS-->
			<VerifyEDID>enable</VerifyEDID>
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
	TimeInterval=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/TimeInterval" -n "${XmlConfigFile}" 2>/dev/null)
	VerifyEDID=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/VerifyEDID" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#TimeInterval} == 0 ] || [ $(echo ${TimeInterval} | grep -iEc "[0-9]" ) != 1 ] || [ ${TimeInterval} == 0 ] ; then
		Process 1 "Invalid config file: ${XmlConfigFile} ..."
		exit 3
	fi
	return 0			
}

GetEDID ()
{
	local EDIDInfoLog=$1
	xrandr --verbose >/dev/null 2>&1
	local EdidFilesList="${BaseName}_EDID.log"
	rm -rf ${EdidFilesList} 2>/dev/null
	find /sys/devices -iname "edid" | grep -v "^$" > ${EdidFilesList} 2>/dev/null 
	sync;sync;sync
	
	local MonitorAmount=$(grep -iwc "/sys/devices" ${EdidFilesList} 2>/dev/null )	
	for((i=1;i<=${MonitorAmount};i++))
	do
		local EdidInfo=$(sed -n ${i}p ${EdidFilesList} 2>/dev/null)
		cat "${EdidInfo}" 2>/dev/null | edid-decode > ${EDIDInfoLog}
		sync;sync;sync		
	done
}

RandomEquation()
{
	local min=$1
	local max=$(($2-$1))
	while :
	do
		local num1=$(date +%s+%N | bc) 
		local num2=$(date +%s-%N | bc)
		num1=$(echo $((num1%max+min)))
		num2=$(echo $((num2%max+min)))
		local Gap=$(echo "${max}-${num2}-${num1}" | bc)
		if [ ${Gap} -ge 0 ]; then
			break
		fi
	done

	numlockx on >/dev/null 2>&1
	local StdAnswer=$((max-Gap))
	printf "\e[1m%s\e[0m\e[1;31m%s\e[0m" "請在15秒鐘內輸入算式的正確答案 " "${num2} + ${num1} = "
	read -n ${#StdAnswer} -t 15 Answer
	echo
	if [ ${#Answer} == 0 ] ; then
		Process 1 "Test fail, time out ..."
		exit 1
	fi
	
	if [ $(echo ${Answer} | grep -iwc "${StdAnswer}" ) != 1 ] ; then
		Process 1 "計算錯誤，請確認顯示器是否正常顯示..."
		exit 1
	else	
		Process 0 "計算正確, ${num2} + ${num1} = ${Answer} "
	fi
	return 0
}

main()
{
	printf "\e[30;43m%s\e[0m\n" "**********************************************************************"
	printf "\e[30;43m%s\e[0m\n" "*****                 前/後置VGA顯示接口功能測試                 *****"
	printf "\e[30;43m%s\e[0m\n" "*****                 必須使用不同規格的顯示器                   *****"
	printf "\e[30;43m%s\e[0m\n" "**********************************************************************"
	echo
	printf "\e[1m%s\e[0m\n" "切換前、後置顯示的時候請確認顯示器是否正常顯示、是否偏色、花屏、抖屏等;"
	printf "\e[1m%s\e[0m\n" "如果有以上不正常的功能顯示請按不良品處理!"
	#RandomEquation 0 9
	rm -rf ${BaseName}.log FrontVGAEDID.log RearVGAEDID.log
	StartTime=$(date "+%s")
	Show='on'
	mod=0
	while :
	do
		printf "%s" "`date "+%s.%N"`  " >> ${BaseName}.log
		xrandr --verbose | grep -iw "axis)" | awk -F'axis)' '{print $NF}' | tr -d ' ' >> ${BaseName}.log
		
		if [ ${Show} == 'on' ] ; then
			LineCount=$(cat ${BaseName}.log | wc -l )
			if [ ${LineCount} == 2 ] ; then
				printf "\e[30;45m%s\e[0m\n" "**********************************************************************"
				printf "\e[30;45m%s\e[0m\n" "*****         請在20秒鐘內移除前置VGA顯示接口上的顯示器          *****"
				printf "\e[30;45m%s\e[0m\n" "**********************************************************************"
				Show='off'
			fi
		fi

		sync;sync;sync
		cat ${BaseName}.log | grep -iE "[a-z]" | grep -vw "0mmx0mm"| tail -n2 | awk '{print $NF}' | sort -u | wc -l | grep -iwq "2" 
		if [ $? == 0 ] ; then
			sleep 3
			GetEDID RearVGAEDID.log 2>/dev/null
			sync;sync;sync
			break
		fi
	
		EndTime=$(date "+%s")
		Interval=$((${EndTime}-${StartTime}))
		if [ ${Interval} -gt 20 ] ; then
			Process 1 "Time out ..."
			let ErrorFlag++
			break
		fi
		mod=$((Interval%5))
		if [ ! -f FrontVGAEDID.log ] && [ ${mod} == 0 ] ; then
			GetEDID FrontVGAEDID.log 2>/dev/null
		fi
	done 

	StartEndTime=($(cat ${BaseName}.log | grep -iE "[a-z]" | grep -vw "0mmx0mm"| tail -n2 | awk '{print $1}' ))
	CurTimeInterval=$(printf "%s\n" "${StartEndTime[1]}-${StartEndTime[0]}" | bc)
	CurTimeInterval=$(printf "%0.2f\n" "${CurTimeInterval}")
	printf "%10s%s\n" "" "Time Interval: ${CurTimeInterval} sec ..."

	md5sum FrontVGAEDID.log RearVGAEDID.log 2>/dev/null | awk '{print $1}' | sort -u | wc -l | grep -iwq "2"
	if [ $? != 0 ] ; then
		Process 1 "偵測到相同的顯示器型號 ..."
		let ErrorFlag++
	else
		Process 0 "偵測到不同型號的顯示器 ..."
	fi

	echo ${VerifyEDID:-"disable"} | grep -iwq "enable"
	if [ $? == 0 ] ; then
		cat FrontVGAEDID.log 2>/dev/null | grep -iw "EDID Version" | awk '{print $NF}' | grep -iwFvq "0.0" 
		Process $? "校驗Front VGA EDID ..." || let ErrorFlag++
		
		cat RearVGAEDID.log 2>/dev/null | grep -iw "EDID Version" | awk '{print $NF}' | grep -iwFvq "0.0" 
		Process $? "校驗Rear VGA EDID ..." || let ErrorFlag++	
	fi
	
	printf "%s\n" "${CurTimeInterval}-${TimeInterval}<=0" | bc | grep -iwq "1"
	if [ $? == 0 ] && [ ${ErrorFlag} == 0 ] ; then
		Process 0 "前/後置VGA確認正常..."
	else
		Process 1 "確認前/後置VGA功能太長,請按WI操作..."
		let ErrorFlag++
	fi
	
	xrandr >/dev/null
	printf "\e[1m%s\e[0m\n" "切換前、後置顯示的時候請確認顯示器是否正常顯示、是否偏色、花屏、抖屏等;"
	printf "\e[1m%s\e[0m\n" "如果有以上不正常的功能顯示請按不良品處理!"
	#RandomEquation 0 9
	if [ ${ErrorFlag} == 0 ] ; then
		echo -e "\nEDID infomation:\n"
		cat FrontVGAEDID.log 2>/dev/null
		echo "----------------------------------------------------------------------"
		cat RearVGAEDID.log 2>/dev/null
		echo
		rm -rf ${BaseName}.log FrontVGAEDID.log RearVGAEDID.log 2>/dev/null
		echoPass "Check the Rear and Front VGA port"
	else
		echoFail "Check the Rear and Front VGA port"
		exit 1
	fi
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile TimeInterval VerifyEDID
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
			printf "%-s\n" "SerialTest,CheckFrontAndRearVGAPortEDID"
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
