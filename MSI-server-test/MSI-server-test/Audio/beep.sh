#!/bin/bash
#FileName : Buzzer.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-09"
	local UpdatedDate="2019-07-04"
	local Description="Buzzer functional test"
	
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
	printf "%16s%-s\n" "" "2019-07-04,add 100/200/400Hz,800/1600/3200Hz test"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet BEEP beep)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			beep)printf "%10s%s\n" "" "Please install: beep-1.3-1.el7.rf.x86_64.rpm";;
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
	eg.: `basename $0` [-d] -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-d : For debug only, show the answer code
	-V : Display version number and exit(1)
	
	return code:
		0 : Buzzer functional test pass
		1 : Buzzer functional test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Audio>	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXA29|beep test fail</ErrorCode>
			<!--beep.sh: 蜂鳴器測試；Enable: 100/200/400Hz各測試一次，800/1600/3200Hz抽測1~3次; Disable: 僅默認頻率測試-->
			<CoverFrequency>Enable</CoverFrequency>
			<!-- pcb marking -->
			<Location>JSPK1</Location>
			<!--機台自動測試，響5秒 -->			
			<AutoTest>Enable</AutoTest>
		</TestCase>	
	</Audio>
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
	Location=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	AutoTest=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/AutoTest" -n "${XmlConfigFile}" 2>/dev/null)
	CoverFrequency=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/CoverFrequency" -n "${XmlConfigFile}" 2>/dev/null)
	FanControl=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/FanControl" -n "${XmlConfigFile}" 2>/dev/null)
	ManulFanCommand=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/ManulFanCommand" -n "${XmlConfigFile}" 2>/dev/null)
	LowSpeed=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/LowSpeed" -n "${XmlConfigFile}" 2>/dev/null)
	AutoFanCommand=$(xmlstarlet sel -t -v "//Audio/TestCase[ProgramName=\"${BaseName}\"]/AutoFanCommand" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

Wait4OPInput ()
{
	WaitTime=$1
	StdAns=$2
	numlockx on 2>/dev/null
	for ((p=$WaitTime;p>=0;p--))
	do   
		printf "\r\e[1;33mTime remainning: %02d seconds, input[3~6]: \e[0m" "${p}"
		read -t1 -n1 Ans
		[ ${#Ans} == "0" ] && continue
		
		echo "$Ans" | grep -iq "${StdAns}"
		if [ $? == 0 ]; then
			echo
			echoPass "Check Beep on ${Location} "
			return 0
			#break
		else
			echo
			echoFail "Check Beep on ${Location} "
			echo "Beeping times should be: $StdAns"
			GenerateErrorCode
			return 1
		fi
	done
	echo

	if [ $p -le 0 ] ; then
		echo -e "\e[1;31m Time out, try again ... \e[0m"
		exit 5
	fi
}

Wait4nSeconds()
{
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do   
		printf "\r\e[1;33mAfter %02d seconds will auto continue ... \e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			break
		else
			continue
		fi
	done
	echo '' 
}

Permutation_Combination ()
{
	for Argument in ${1} ${2}
	do
		# Usage: Permutation_Combination 6 3 p 
		echo $Argument | grep -iq [1-9]
		if [ $? != 0  ]; then
			Process 1 "Invalid parameter: ${Argument}"
			let ErrorFlag++
		else
			if [ ${Argument} -ge 6 ] ; then
				echo "Attention: ${Argument} is great than 5, it will cost too much time!"
			fi
		fi
	done

	if [ ${1} -lt ${2} ] ; then
		Process 1 "Invalid parameter: ${1} < ${2}"
		exit 1
	fi

	arg0=-1
	number=${2}
	eval ary=({1..${1}})
	length=${#ary[@]}
	output(){ echo -n ${ary[${!i}]}; }
	prtcom(){ nsloop i 0 number+1 output ${@}; echo; }
	percom(){ nsloop i ${1} number${2} ${3} ${4} ${5}; }
	detect(){ (( ${!p} == ${!q} )) && argc=1; }
	invoke(){ echo $(percom ${argu} nsloop -1) ${para} $(percom ${argu}); }
	permut(){ echo -n "${1} arg${i} ${2} "; (( ${#} != 0 )) && echo -n " length "; }
	nsloop(){ for((${1}=${2}+1; ${1}<${3}; ++${1})); do eval eval \\\$\{{4..${#}}\}; done; }
	combin(){ (( ${#} != 0 )) && echo -n "${1} arg$((i+1)) arg${i} length " || echo -n "arg$((i+1)) "; }
	prtper(){ argc=0; nsloop p 0 number+1 nsloop q p number+1 detect ${@}; (( argc == 1 )) && return; prtcom ${@}; }

	case ${3} in
		p|P)para=prtper
		  argu="-0 +1 permut" ;;
		c|C)para=prtcom
		  argu="-1 +0 combin" ;; 
		*)
			Process 1 "Invalid parameter: ${3}"
			exit 3
		;;
	esac

	$(invoke)

}

BeepFrequencyTest ()
{
	ShowMsg --b "Pay attention to the ${Location} beep please:"
	ShowMsg --e "Record and input the number that the Beeping times"
	# Record the beep sound times

	Wait4nSeconds 5
	echo -e "\e[1;33mListen carefully ... \e[0m"

	LowSeq=($(Permutation_Combination 3 3 p ))

	HighSeq_A31=$(Permutation_Combination 3 1 p )
	HighSeq_A32=$(Permutation_Combination 3 2 p )
	HighSeq_A33=$(Permutation_Combination 3 3 p )
	HighSeq=($(echo "${HighSeq_A33} ${HighSeq_A32} ${HighSeq_A31}"))

	# load pc speaker driver
	modprobe pcspkr

	# beep continually till i=0
	RandomLowSeq=$(echo $((RANDOM%${#LowSeq[@]})))
	RandomHighSeq=$(echo $((RANDOM%${#HighSeq[@]})))

	RandomCount=$(echo -n "${LowSeq[$RandomLowSeq]}${HighSeq[$RandomHighSeq]}" | wc -c)
	SleepTime=$(echo "obase=10; ibase=10; (6-${RandomCount})*1.2" | bc | tr -d "-")


	# Beeping in low frequency
	for i in `echo ${LowSeq[$RandomLowSeq]} | grep -o '[0-9]'`
	do
		which beep >/dev/null 2>&1
		if [ $? == 0 ] ; then
			beep -f ${Low_Frequency[$i-1]} -l 325
		else
			BEEP /dev/console ${Low_Frequency[$i-1]} 325
		fi
		sleep 1.2
	done

	# Beeping in high frequency
	for j in `echo ${HighSeq[$RandomHighSeq]} | grep -o '[0-9]'`
	do
		which beep >/dev/null 2>&1
		if [ $? == 0 ] ; then
			beep -f ${High_Frequency[$j-1]} -l 325
		else
			BEEP /dev/console ${High_Frequency[$j-1]} 325
		fi
		sleep 1.2
	done

	sleep ${SleepTime}

	[ ${Debug} == 'enable' ] && echo "For debug only, answer is: $RandomCount"
	echo -e "\e[0;33mInput a number that Beeper ringing times 3~6 ...\e[0m"
	Wait4OPInput 15 ${RandomCount}
	if [ $? != 0 ] ; then
		let ErrorFlag++
	fi
	if [ ${ErrorFlag} != 0 ];then
		echo "${FanControl}" | grep -iwq "enable"
		if [ "$?" == "0" ] ; then
			#change FAN speed to normal mode
			#ipmitool raw 0x38 0x14 0x0b 0x01
			$AutoFanCommand
			if [ $? != 0 ] ; then
				let ErrorFlag++
			fi
			sleep 2 
		fi 
		exit 1
	fi
}

BeepingTest ()
{
	ShowMsg --b "Pay attention to the ${Location} beep please:"
	ShowMsg --e "Record and input the number that the Beeping times"
	Wait4nSeconds 3
	echo -e "\e[1;33m Listen carefully ... \e[0m"

	# load pc speaker driver
	modprobe pcspkr

	# beep continually till i=0
	RandomCount=$(echo $((RANDOM%4+3)))
	SleepTime=$(echo "obase=10; ibase=10; (6-${RandomCount})*1.5" | bc)
	for ((i=1;i<=$RandomCount;i++))
	do
		# echo -ne '\a' > /dev/console 2>/dev/null
		ipmitool raw 0x38 0x7 0x70 2>&1 >/dev/null
		sleep 1
		ipmitool raw 0x38 0x7 0x00 2>&1 >/dev/null
		sleep 1
	done

    # sleep ${SleepTime}

	[ ${Debug} == 'enable' ] && echo "For debug only, answer is: $RandomCount"
	echo -e "\e[0;33mInput a number that Beeper ringing times 3~6 ...\e[0m"
	Wait4OPInput 15 ${RandomCount}
	if [ $? != 0 ] ; then
		let ErrorFlag++
	fi
	[ ${ErrorFlag} != 0 ] && exit 1
}

AutoTestBeep()
{
	modprobe pcspkr

	echo "Di di keep in 5 secondes ... "
	which beep >/dev/null 2>&1
	if [ $? == 0 ] ; then
		beep -f 1000 -l 6000
	else
		BEEP /dev/console 1000 6000
	fi
	exit 99
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare CoverFrequency
declare Debug='disable'
declare AutoTest='disable'
declare Low_Frequency=(300 400 500)
declare High_Frequency=(800 1600 3200)
declare XmlConfigFile BeepConfigFile Location ApVersion
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:dVDx: argv
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
			printf "%-s\n" "SerialTest,BuzzerTest"
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

echo "${FanControl}" | grep -iwq "enable"
	if [ "$?" == "0" ] ; then
		#change fan control to manul
		#ipmitool raw 0x38 0x14 0x0b 0x00
		$ManulFanCommand 
		#change FAN speed to 30%
		#ipmitool raw 0x38 0x14 0x0a 0x01
		$LowSpeed
	fi


CoverFrequency=$( echo ${CoverFrequency} | tr '[A-Z]' '[a-z]')
echo "${AutoTest}" | grep -iwq "enable"
if [ "$?" == "0" ] ; then
	AutoTestBeep
else
	case ${CoverFrequency} in 
		disable)BeepingTest;;
		enable)BeepFrequencyTest ;;
		*)Process 1 "Invalid agrument: ${CoverFrequency}";exit 3;;
		esac
fi

echo "${FanControl}" | grep -iwq "enable"
	if [ "$?" == "0" ] ; then
		#change FAN speed to normal mode
		#ipmitool raw 0x38 0x14 0x0b 0x01
		$AutoFanCommand
		if [ $? != 0 ] ; then
			let ErrorFlag++
		fi
		sleep 2 
	fi

[ ${ErrorFlag} != 0 ] && exit 1
exit 0

