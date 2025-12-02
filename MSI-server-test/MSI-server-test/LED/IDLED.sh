#!/bin/bash
#FileName : IDLED.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-06"
	local UpdatedDate="2019-07-04"
	local Description="ID LED function test"
	
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
	ExtCmmds=(xmlstarlet ipmitool tput)
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
`basename $0` [-x lConfig.xml] [-DVd]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-d : For debug only,show the answer code
	-V : Display version number and exit(1)
	
	return code:
		0 : ID test pass
		1 : ID test fail
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
			<!--IDLED.sh-->				
			<Location>LED7</Location>
			<Color>4</Color>
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
	ColorCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Color" -n "${XmlConfigFile}" 2>/dev/null)
	Location=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	Location=${Location:-'ID-LED'}
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

echo_star ()
{
	echo "**********************************************************************"
}

echo_line ()
{
	echo "----------------------------------------------------------------------"
}

echo_red ()
{
	printf "%-3s\e[1;41m%-30s\e[0m%-22s%-10s\n" "" "[    Red/紅色                ]" " -------------------- " "press [$1]"
}

echo_green ()
{
	printf "%-3s\e[1;42m%-30s\e[0m%-22s%-10s\n" "" "[    Green/綠色/青色         ]" " -------------------- " "press [$1]"
}

echo_orange ()
{
	printf "%-3s\e[1;43m%-30s\e[0m%-22s%-10s\n" "" "[  Orange/橘色/Amber/琥珀色  ]" " -------------------- " "press [$1]"
}

echo_blue ()
{
	printf "%-3s\e[1;44m%-30s\e[0m%-22s%-10s\n" "" "[    Blue/藍色               ]" " -------------------- " "press [$1]"
}

Wait4OPInput ()
{
	WaitTime=$1
	StdAns=$2
	numlockx on 2>/dev/null
	for ((p=$WaitTime;p>=0;p--))
	do  
		tput sc;tput rc;tput ed	
		printf "\r\e[1;33mTime remainning: %02d seconds, input[3~6]: \e[0m" "${p}"
		read -t1 -n1 Ans
		[ ${#Ans} == 0 ] && continue
		echo -e "\b${Ans}"
		
		echo "$Ans" | grep -iq "${StdAns}"
		if [ $? == 0 ]; then
			echo
			echoPass "Check $Location "
			return 0
			break
		else
			echo
			echoFail "Check $Location "
			echo "Lighting on times should be: $StdAns"
			return 1
		fi
	done
	echo

	if [ $p -le 0 ] ; then
		echo -e "\e[1;31m Time out, try again ... \e[0m"
		exit 5
	fi
}

load_ipmi_driver ()
{
	modprobe ipmi_devintf
	if [ $? -ne 0 ]; then
		Process 1 "Load IPMI Driver"
		exit 5
	fi

	modprobe ipmi_si > /dev/null 2>&1
	sleep 1

	return 0
}

IDLEDLightOnTest ()
{
	load_ipmi_driver
	#Check Fault LED by Manaul.
	#Load IPMI Driver

	# Check ID LED
	ShowMsg --b "ID LED( $Location ) test program is runing ..."
	ShowMsg --2 "Observe the LED lighting on how many times ..."
	ShowMsg --e "Comfirm the color and input the color code to test ..."
	echo -e "\e[33m Lighting on ID led, pay attention please ...\e[0m"

	RandomNumber=$(echo $((RANDOM%4+3)))
	SleepTime=$(echo "obase=10; ibase=10; (6-${RandomNumber})*1.9" | bc)

	#Turn off ID LED
	ipmitool chassis identify 0 > /dev/null 2>&1
	sleep 2

	for (( i=0;i<${RandomNumber};i++ ))
	do
		#Turn on ID LED
		ipmitool chassis identify 1 > /dev/null 2>&1
		sleep 2
		#Turn off ID LED
		ipmitool chassis identify 0 > /dev/null 2>&1
	   sleep 1
	  
	done

	sleep ${SleepTime}

	modprobe pcspkr
	#echo -e '\a' > /dev/console 2>/dev/null
	BeepRemind 0
	echo 'End lighting ...'
	[ $Debug == "enable" ] && echo "For debug only, the answer is: $RandomNumber"

	Wait4OPInput 15 ${RandomNumber}
	if [ $? != 0 ] ; then
		let ErrorFlag++
		BeepRemind ${ErrorFlag}
		exit 1
	fi
}

IDLEDColorTest ()
{
	echo "${ColorCode}" | grep -iwEq "[1-4]" || return 0

	StandardColor="$ColorCode"
	RandomColorCode=(1234 4321 2143 3412 4213 2431)
	Chance=3
	while :
	do 
		#Color test
		echo_star  
		echo -e "  Check the \e[4mcolor\e[0m of \e[1;31m[\e[0m $Location \e[1;31m]\e[0m ..."
		echo_line  

		RandomVal=$(($RANDOM%6))
		for((j=1;j<=4;j++))
		do
			iColor=$(echo ${RandomColorCode[$RandomVal]} | cut -c $j)
			case $iColor in
			 1)
				echo_red $j
				echo "$StandardColor" | grep -wq "1"  && StdAns[0]=$j
			 ;;

			 2)
				echo_green $j
				echo "$StandardColor" | grep -wq "2" && StdAns[1]=$j
			 ;;

			 3)
				echo_orange $j
				echo "$StandardColor" | grep -wq "3" && StdAns[2]=$j
			 ;;

			 4)
				echo_blue $j
				echo "$StandardColor" | grep -wq "4" && StdAns[3]=$j
			 ;;   
			 esac
		done
		echo_star
		
		[ $Debug == 'enable' ] && echo  -n "For debug only, the answer is: "
		SoleStdAns="debug"
		for ((h=0;h<4;h++)) 
		do
			if [ ${#StdAns[$h]} != 0 ] ; then
				[ $Debug == 'enable' ] && echo -n "${StdAns[$h]}, "
				SoleStdAns="${SoleStdAns}\|${StdAns[$h]}"
			fi
		done
		echo 
		
		BeepRemind 0
		numlockx on 2>/dev/null
		echo -e "\e[0;33m It's only 15 seconds to answer ... \e[0m"
		tput sc;tput rc;tput ed	
		read -p "What the color do you see? press the right color code: 1,2,3 or 4: " -t 15 -n1 COLOR
		COLOR=${COLOR:-5}
		echo -e "\b${COLOR}"
		echo ${COLOR} |  grep -wq "${SoleStdAns}"
		if [ $? == 0 ] ; then
			echo
			echoPass "$Location color test"
			ErrorFlag=0
			break
		else
			echo
			if [ $COLOR == 5 ]; then
				echo -e "\e[1;31m Time out ...\e[0m"
			fi
			
			echoFail "$Location color test"
			let ErrorFlag++
			BeepRemind ${ErrorFlag}
			if [ $Chance == 0 ] ; then
				break
			fi
			let Chance--
		fi
	done
}

main()
{
	IDLEDLightOnTest
	IDLEDColorTest
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
declare Debug='disable'
declare XmlConfigFile ColorCode Location
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:VDdx: argv
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
			printf "%-s\n" "SerialTest,IDLEDTest"
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
