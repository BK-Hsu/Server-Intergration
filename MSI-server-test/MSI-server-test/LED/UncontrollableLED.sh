#!/bin/bash
#FileName : UncontrollableLED.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.1"
	local CreatedDate="2018-07-06"
	local UpdatedDate="2020-09-21"
	local Description="Random test uncontrollable LEDs one by one by manual"
	
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
	printf "%16s%-s\n" "" "2020-06-11,BMC LED/Power LED and so on"
	printf "%16s%-s\n" "" "2020-09-21,優化代碼"
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
	ExtCmmds=(xmlstarlet tput)
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
cat <<HELP | more | more
Usage: 
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file		
	-x : config file,format as: *.xml
	-d : For debug only,show the answer code
	-V : Display version number and exit(1)
	
	return code:
		0 : Test pass
		1 : Test fail
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
			<ErrorCode>NXRD4|LED fail</ErrorCode>
			<!--該範圍內的不受控的LED將隨機測試: 顏色、順序隨機測試-->
			<!--UncontrollableLED.sh-->	
			<!-- UncontrollableLed: the LED can not be controllable by command不受控的LED測試-->
			<!-- PTE/PE can define the lable name under "UncontrollableLed" -->
			<!-- LEDRandomTest.sh will random test all below LEDs one by one by manual -->
			<!--Color code不能缺省,多個顏色的使用逗號間隔 -->
			<Member>
				<Location>LED5</Location>
				<Color>1</Color>		
			</Member>
			
			<Member>
				<Location>LED1</Location>
				<Color>2</Color>
			</Member>
			
			<Member>
				<Location>LED-A</Location>
				<Color>3</Color>
			</Member>
			
			<Member>
				<Location>LED-N</Location>
				<Color>4</Color>
			</Member>
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
	
	# Get the parameters information from the config file(*.xml)
	LedTotalAmount=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Member/Location" -n ${XmlConfigFile} 2>/dev/null | grep -iEc "[0-9A-Z]")
	ColorTotalAmount=($(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Member/Color" -n ${XmlConfigFile} 2>/dev/null ))
	if [ ${LedTotalAmount} != ${#ColorTotalAmount[@]} ] ; then
		Process 1 "Invalid Location or Color setting in XML ..."
		let ErrorFlag++
	fi
	echo ${ColorTotalAmount[@]} | tr '[[:punct:]]' ' ' | tr ' ' '\n' | grep -iEq "[5-9A-Z]"
	if [ $? == 0 ] ; then
		Process 1 "Invalid Color setting in XML ..."
		let ErrorFlag++
	fi
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0
}


Random()
{
    local min=$1
	local max=$(($2-$1))
    local num=$(date +%s+%N | bc)
    echo $((num%max+min))     
}

RandomNoRepetition()
{
	local num="$1"
	#獲取1~num個隨機不重複的數
	while :
	do
		for((i=0;i<${num};i++))
		do 
			local arrary[i]=$(Random 1 $((num+1)))
		done
		
		echo "${arrary[@]}" | tr ' ' '\n' | sort -u | wc -l | grep -iwq "${num}" 
		if [ $? == 0 ]; then
			echo "${arrary[@]}" | tr ' ' '\n'
			break
		fi
	done
}

RandomShowOption()
{	
	clear
	local Location="$1"
	local LedColor="$2"
	local RandomCode=($(RandomNoRepetition 4))
	StandardAnswer=""
	echo "**********************************************************************"
	printf "%-s\e[1;33m%-s\e[0m%-s\n" " Which color best fits " "\"${Location}\"" " ?"
	echo "----------------------------------------------------------------------"
	for((r=0;r<${#RandomCode[@]};r++))
	do
		[ ${RandomCode[r]} == 1 ] && printf "%-3s\e[1;41m%-30s\e[0m%-22s%-10s\n" "" "[    Red/紅色                ]" " -------------------- " "press [$((r+1))]"
		[ ${RandomCode[r]} == 2 ] && printf "%-3s\e[1;42m%-30s\e[0m%-22s%-10s\n" "" "[    Green/綠色/青色         ]" " -------------------- " "press [$((r+1))]"
		[ ${RandomCode[r]} == 3 ] && printf "%-3s\e[1;43m%-30s\e[0m%-22s%-10s\n" "" "[  Orange/橘色/Amber/琥珀色  ]" " -------------------- " "press [$((r+1))]"
		[ ${RandomCode[r]} == 4 ] && printf "%-3s\e[1;44m%-30s\e[0m%-22s%-10s\n" "" "[    Blue/藍色               ]" " -------------------- " "press [$((r+1))]"
		echo ${LedColor} | grep -wq "${RandomCode[r]}" && StandardAnswer=$(echo ${StandardAnswer},$((r+1)))
	done
	echo "----------------------------------------------------------------------"
}

main()
{
	local RandomLed=($(RandomNoRepetition ${LedTotalAmount}))
	for((j=0;j<${#RandomLed[@]};j++))
	do
		local LedLocation=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Member[${RandomLed[j]}]/Location" -n ${XmlConfigFile} 2>/dev/null )
		local LedColor=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Member[${RandomLed[j]}]/Color" -n ${XmlConfigFile} 2>/dev/null )
		
		for((Chance=3;Chance>0;Chance--))
		do
			RandomShowOption "${LedLocation}" "${LedColor}"
			
			BeepRemind 0
			numlockx on 2>/dev/null
			[ ${Debug} == 'enable' ] && echo "For debug only, the answer is: ${StandardAnswer}"
			echo -e "\e[0;33mIt's only 15 seconds to answer ... \e[0m"
			tput sc;tput rc;tput ed	
			printf "%-s\e[1;33m%-s\e[0m%-s" "Which color best fits " "${LedLocation}" "? Input < 1 2 3 4 >: "
			read -t 15 -n1 Answer
			echo -e "\b${Answer}"
			Answer=${Answer:-99}
			echo ${StandardAnswer} |  grep -wq "${Answer:-99}"
			if [ $? == 0 ] ; then
				echo
				echoPass "Check the color of ${LedLocation}"
				continue 2
			else
				echo
				if [ ${Answer} == 99 ]; then
					echo -e "\e[1;31m Time out ...\e[0m"
				fi
				
				echoFail "Check the color of ${LedLocation}"
				if [ ${Chance} -gt 1 ] ; then
					echo -e "\e[1;33m [ $((Chance-1))/3 ] Try again ...\e[0m"
					sleep 1
				fi
			fi
		done
		
		if [ ${Chance} -le 0 ] ; then
			let ErrorFlag++
			GenerateErrorCode
			exit 1
		fi
	done
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare Debug='disable'
declare XmlConfigFile StandardAnswer
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
			printf "%-s\n" "SerialTest,LEDTest"
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
