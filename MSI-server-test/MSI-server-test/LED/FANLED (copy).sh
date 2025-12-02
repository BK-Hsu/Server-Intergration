#!/bin/bash
#============================================================================================
#        File: HDDLED.sh
#    Function: HDD function test
#     Version: 1.1.0
#      Author: Cody,qiutiqin@msi.com
#     Created: 2018-07-05
#     Updated: 2019-07-04
#  Department: Application engineering course
# 		 Note: 
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
	ExtCmmds=(xmlstarlet hdparm)
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
`basename $0` [-x lConfig.xml] [-D|d]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-d : For debug only,show the answer code
	
	return code:
		0 : HDD test pass
		1 : HDD test fail
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
			<ProgramName>HDDLED</ProgramName>
			<ErrorCode>NXRD4|LED fail</ErrorCode>
			<!--HDDLED.sh,多種顏色的時候使用逗號分隔-->	
			<Location>LED4</Location>
			<Color>2,1</Color>
			
			<!-- TestByTimes: enable: Test by lighting on times, or disable: Check it light on only -->
			<TestByTimes>disable</TestByTimes>
			<!--程式負責點亮此LED-->
			<AutoTest>enable</AutoTest>
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

	# Get the information from the config file(*.xml)
	ColorCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Color" -n "${XmlConfigFile}" 2>/dev/null)
	Location=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	Location=${Location:-'FANLed'}
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

echo_star ()
{
	echo "****************************************************************"
}

echo_line ()
{
	echo "----------------------------------------------------------------"
}

echo_red ()
{
	printf "%-3s\e[1;41m%-27s\e[0m%-23s%-10s\n" "" "[           Red           ]" " --------------------- " "`echo "press [$1]"`"
}

echo_green ()
{
	printf "%-3s\e[1;42m%-27s\e[0m%-23s%-10s\n" "" "[          Green          ]" " --------------------- " "`echo "press [$1]"`"
}

echo_orange ()
{
	printf "%-3s\e[1;43m%-27s\e[0m%-23s%-10s\n" "" "[      Orange/Amber       ]" " --------------------- " "`echo "press [$1]"`"
}

echo_blue ()
{
	printf "%-3s\e[1;44m%-27s\e[0m%-23s%-10s\n" "" "[          Blue           ]" " --------------------- " "`echo "press [$1]"`"
}

Wait4OPInput ()
{
	WaitTime=$1
	numlockx on 2>/dev/null
	for ((p=$WaitTime;p>=0;p--))
	do   
		printf "\r\e[1;33mTime remainning: %02d seconds, press Y or N ...  \e[0m" "${p}"	
		# Run ls in background---turn on HDD led
		`ls  -AR /usr > /var/log/test.mesg ` &
		read -t1 -n1 -s Ans
		sync;sync;sync
		killall ls >/dev/null 2>&1 
		echo "$Ans" | grep -iq 'Y'
		if [ $? == 0 ]; then
			echo
			echoPass "Check $Location "
			break
		fi

		echo "$Ans" | grep -iq 'N'
		if [ $? == 0 ]; then
			echo
			Process 1"Check $Location "
			rm -rf test.mesg 2>/dev/null
			let ErrorFlag++
			exit 1
		fi
	done
	echo
}

GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457
	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" |awk '{print $1}'| sed -n 1p |cut -c 1-8)

	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $3}')
}

HddLightOnTest ()
{
	ShowMsg --b "HDD LED( $Location ) test program is runing ..."
	ShowMsg --2 "Observe the LED whether lighting/blinking or not ?"
	ShowMsg --e "Comfirm the color and input the color code to test."
	echo -e "\e[33m Lighting on HDD led please wait ...\e[0m"
	for((i=1;i<=3;i++))
	do	
		# Run ls in background
		`ls  -AR /usr > /var/log/test.mesg` &
		sync;sync;sync
		sleep 0.5
	done

	echo -e "\e[1;33mCheck HDD LED($Location) is blinking/lighting ?\e[0m"

	modprobe pcspkr
	#echo -ne '\a' > /dev/console 2>/dev/null
	BeepRemind 0
	echo
	killall ls >/dev/null 2>&1

	Wait4OPInput 15
	if [ "$p" -le "0" ] ; then
		Process 1 "Time Out, HDD LED( $Location ) test"
		rm -rf /var/log/test.mesg >/dev/null 2>&1
		exit 1
	fi
}

FANLingtONTimesTest ()
{
	ShowMsg --b "FAN LED( $Location ) test program is runing ..."
	ShowMsg --2 "Observe the LED lighting on how many times ..."
	ShowMsg --e "Comfirm the color and input the color code to test ..."
	echo -e "\e[33m Lighting on FAN led, pay attention please ...\e[0m"

	RandomNumber=$(echo $((RANDOM%4+3)))
	SleepTime=$(echo "obase=10; ibase=10; (6-${RandomNumber})*1.9" | bc)


	for((i=1;i<=$RandomNumber;i++))
	do	
		ipmitool raw 0x38 0x14 0x08 0x00 >/dev/null 2>&1
		sleep 1
		ipmitool raw 0x38 0x14 0x09 0x00 >/dev/null 2>&1
	done

	sleep ${SleepTime}
	 
	modprobe pcspkr
	#echo -ne '\a' > /dev/console 2>/dev/null
	echo
	BeepRemind 0
	echo 'End lighting ...'
	killall ls >/dev/null 2>&1
	numlockx on 2>/dev/null
	[ $Debug == "enable" ] && echo "For debug only, the answer is: $RandomNumber"
	for ((p=15;p>=0;p--))
	do   
		echo -ne "\e[1;33m`printf "\rTime remainning: %02d seconds, input[3~6]: \n" "${p}"`\e[0m"
		read -t1 -n1 Ans
		echo $Ans |grep [0-9] >/dev/null 2>&1
		if [ "$?" != "0" ] ; then
			continue
		fi

		if [ "$Ans"x == "$RandomNumber"x ]; then
			echo
			echoPass "Check $Location "
			break
		else
			echo
			echoFail "Check $Location "
			BeepRemind 1
			echo "Lighting on times should be: $RandomNumber"
			rm -rf /var/log/test.mesg  >/dev/null 2>&1
			GenerateErrorCode
			exit 1
		fi
	done
	echo

	if [ "$p" -le "0" ] ; then
		Process 1 "Time Out, FAN LED( $Location ) test"
		rm -rf /var/log/test.mesg >/dev/null 2>&1
		exit 1
	fi
}

FANLEDTest ()
{
	Location=${Location:-'FAN-LED'}
	TestByTimes=${TestByTimes:-'disable'}
	TestByTimes=$(echo ${TestByTimes} | tr [A-Z] [a-z])
	case $TestByTimes in
		disable)
			HddLightOnTest
		;;
		
		enable)
			FANLingtONTimesTest
		;;
		
		*)
			Process 1 "Invalid parameter: ${TestByTimes}"
			exit 3
		;;
		esac
}

FANColorTest ()
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
		read -p "What the color do you see? press the right color code: 1,2,3 or 4: " -t 15 -n1 COLOR
		COLOR=${COLOR:-5}
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

AutoTestFunc()
{
	GetBootDisk
	echo "${Location} LED blinking keep in 5 secondes ... "
	for((i=1;i<=2;i++))
	do
		hdparm -t ${BootDiskVolume} >/dev/null 2>&1 
	done
	exit 99
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare Debug='disable'
declare TestByTimes='enable'
declare AutoTestMode='disable'
declare XmlConfigFile ColorCode Location BootDiskVolume
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands
#--->Get and process the parameters
while getopts :Ddx: argv
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

AutoTestMode=$( echo ${AutoTestMode} | tr '[A-Z]' '[a-z]')	
if [ "${AutoTestMode}"x == 'enable'x ] ; then
	AutoTestFunc
else
	FANLEDTest
	FANColorTest
fi

if [ ${ErrorFlag} != 0 ] ; then
	GenerateErrorCode
	exit 1
fi
exit 0
