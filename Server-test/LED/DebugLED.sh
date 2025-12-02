#!/bin/bash
#FileName : DebugLED.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.3"
	local CreatedDate="2018-07-05"
	local UpdatedDate="2020-12-24"
	local Description="Debug LED or debug header test"
	
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
	printf "%16s%-s\n" "" "2018-12-20,Suitable for S0961;random show 88,80,08,AA,A8,8A,xx"
	printf "%16s%-s\n" "" "2020-08-11, 修改了DEBUGLED 在tee下不顯示提示"
	printf "%16s%-s\n" "" "2020-12-24, 加入高位上的LED確認判定(不防呆)"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet)
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
	-d : For debug only,show the answer
	-V : Display version number and exit(1)
	
	return code:
		0 : Debug LED or debug header test pass
		1 : Debug LED or debug header test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
		
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<LED>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXLE9|Status LED NO Function</ErrorCode>
			<!--DebugLED.sh-->
			<Tool>DEBUGLED</Tool>
			<Location>LED2</Location>
			<HighOrder>
				<!--高位LED顯示可能顯示的16進制如下-->
				<Code>A5</Code>
				<Code>AA</Code>
			</HighOrder>
		</TestCase>
	</LED>
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
	HighOrderCode=($(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/HighOrder/Code" -n "${XmlConfigFile}" 2>/dev/null))
	DebugTool=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Tool" -n "${XmlConfigFile}" 2>/dev/null)
	Location=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	Location=${Location:-'Debug'}
	if [ ${#DebugTool} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
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

main ()
{
	TestTool=$(which ${DebugTool} | head -n 1)
	if [ ${#TestTool} != 0 ] && [ -f "${TestTool}" ] ; then 
		md5sum ${TestTool}
		chmod 777 ${TestTool}
	else
		Process 1 "No such debug tool: ${DebugTool}"
		exit 2
	fi

	ShowMsg --b "${Location} test program is runing ..."
	ShowMsg --2 "Observe the LEDs which number it shows."
	ShowMsg --e "Please install TL-404 card if necessary."

	while :
	do
		numlockx on 2>/dev/null
		ErrorFlag=0
		if [ ${ErrorFlag} -gt 3 ] ; then
			echo "Failures too many times,exiting ..."
			exit 1
		fi

		RandomNumber=$(echo "$RANDOM % 8 "| bc )
		DecNumber_1=$(echo "$RANDOM % 256 "| bc )
		DecNumber_2=$(echo "$RANDOM % 256 "| bc )
		case $RandomNumber in
			0)ShowText=(168 136 ${DecNumber_1} ${DecNumber_2});;
			1)ShowText=(${DecNumber_1} 138 136 ${DecNumber_2});;
			2)ShowText=(08 ${DecNumber_1} 136 ${DecNumber_2});;
			3)ShowText=(136 ${DecNumber_1} 128 ${DecNumber_2});;
			4)ShowText=(136 ${DecNumber_1} 08 ${DecNumber_2});;
			5)ShowText=(170 ${DecNumber_1} 136 ${DecNumber_2});;
			6)ShowText=(136 ${DecNumber_1} ${DecNumber_2} 170);;
			7)ShowText=(${DecNumber_1} 128 ${DecNumber_2} 136);;		
			esac

		for i in ${ShowText[@]}
		do
			(${TestTool} ${i}  >/dev/null 2>&1) &
			local PID=$!

			printf "%s" "Please input the hexadecimal number,which show on Debug LED:"
			if [ ${#HighOrderCode[@]} == 0 ] ; then
				read -t15 -n2 OpReply
			else
				read -t15 -n4 OpReply
			fi
			kill -9 ${PID} >/dev/null 2>&1
			echo
			local StandardCode=''
			if [ ${i} -le 15 ] ; then
				StandardCode=$(printf "%2s\n" "0`echo "ibase=10;obase=16;${i}"|bc`")
			else
				StandardCode=$(printf "%2s\n" "`echo "ibase=10;obase=16;${i}"|bc`")
			fi
			
			local SubErrorFlag=1
			if [ ${#HighOrderCode[@]} == 0 ] ; then
				echo "${OpReply}" | grep -iwq "${StandardCode}"
				if [ $? == 0 ] ; then
					SubErrorFlag=0
				fi
			else
				for((h=0;h<${#HighOrderCode[@]};h++))
				do
					echo "${OpReply}" | grep -iwq "${HighOrderCode[h]}${StandardCode}"
					if [ $? == 0 ] ; then
						SubErrorFlag=0
						StandardCode=$(echo "${HighOrderCode[h]}${StandardCode}")
						break
					fi
				done
			fi
			
			printf "%s\n" "The standard hexadecimal number is: ${StandardCode}, OP input is: ${OpReply}"
			if [ "${SubErrorFlag}" != "0"  ] ; then
				let ErrorFlag++
				BeepRemind 1
				echo "Please try again ..."
				continue 2
			fi
			echo
			sleep 1			
		done

		if [ ${ErrorFlag}x == "0"x ] ; then
			echoPass "Check Debug LED ( ${Location} ) function"
			ErrorFlag=0
			break
		else
			echoFail "Check Debug LED ( ${Location} ) function "
			echo "Please try again ..."
			let ErrorFlag++
			GenerateErrorCode
		fi
	done
	[ ${ErrorFlag} != 0 ] && exit 1
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -a HighOrderCode=()
declare Debug='disable'
declare XmlConfigFile DebugTool Location 
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:VDdc:x: argv
do
	 case ${argv} in
	 	d)
			Debug='enable'
		;;
		
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
			printf "%-s\n" "SerialTest,DebugLEDTest"
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
