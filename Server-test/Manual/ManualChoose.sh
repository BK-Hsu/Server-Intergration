#!/bin/bash
#FileName : ManualYesNo.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2020-09-22"
	local UpdatedDate="2020-09-22"
	local Description="Random test uncontrollable Jumpers one by one by manual"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
	if [ "${#ErrorCode}" != 0 ] ; then
		grep -iwq "${ErrorCode}" ${ErrorCodeFile} 2>/dev/null || echo "${ErrorCode}|${ShellFile}" >> ${ErrorCodeFile}
	else
		echo "NULL|NULL|${ShellFile}" >> ${ErrorCodeFile}
	fi
	sync;sync;sync
	return 0
}

ShowTitle()
{
	local Title="$@"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                                  ' | cut -c 1-${BlankCnt})
	echo -e "\e[1;33m${BlankCnt}${Title}\e[0m"
}

ChkExternalCommands ()
{
	ExtCmmds=(xmlstarlet tput $@)
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
	return 0
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
	<Manual>
		<TestCase>
			<!--只限于console/命令行模式-->
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXVC1|Cap Pin insert error location</ErrorCode>
			
			<!--Box: 交互式,更直觀,但是需要輸入更多, CommandLine：命令行,輸入較少-->
			<DisplayMode>box</DisplayMode>
			
			<!--Option描述應該控制在50字內; index必須從1開始的連續自然數-->
			<Member>
				<Location>JECO_SW1</Location>
				<Question>Which side is the switch on?</Question>
				<CorrectlyOptionIndex>2</CorrectlyOptionIndex>
				<Option index="1">ON side</Option>
				<Option index="2">OFF side</Option>
			</Member>

			<Member>
				<Location>JPW_ATX24</Location>
				<Question>Which PIN is the jumping cap on?</Question>
				<CorrectlyOptionIndex>2</CorrectlyOptionIndex>
				<Option index="1">Pin1-2</Option>
				<Option index="2">Pin2-3</Option>
			</Member>			
		</TestCase>
	</Manual>
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
	DisplayMode=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/DisplayMode" -n ${XmlConfigFile} 2>/dev/null | tr '[A-Z]' '[a-z]')
	JumperTotalAmount=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member/Location" -n ${XmlConfigFile} 2>/dev/null | grep -iEc "[0-9A-Z]")
	for((J=1;J<=${JumperTotalAmount};J++))
	do
		JumperOptionIndex=($(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[${J}]/Option/@index" -n ${XmlConfigFile} 2>/dev/null | sort -u | sort -ns ))
		if [ ${#JumperOptionIndex[@]} != ${JumperOptionIndex[-1]} ] ; then
			Process 1 "Invalid setting //Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[${J}]/Option/@index"
			let ErrorFlag++
		fi
		
		if [ "${DisplayMode}" == "box" ] ; then
			if [ ${JumperOptionIndex[-1]} -ge 3 ] ; then
				Process 1 "对话框模式只能显示2个选项,但是配置档超过3个选项了!"
				let ErrorFlag++
			fi
		fi
	
	done
	

	
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

RandomShowOptionWhiptail()
{
	local Location=$1
	local Question=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/Question" ${XmlConfigFile} 2>/dev/null)
	local CorrectlyOptionIndex=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/CorrectlyOptionIndex" ${XmlConfigFile} 2>/dev/null)
	local TotalOption=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/Option" ${XmlConfigFile} 2>/dev/null | grep -iEc "[0-9A-Z]")
	local RandomOption=($(RandomNoRepetition ${TotalOption}))
	local String=""
	ChkExternalCommands "whiptail"
	echo
	echo "**********************************************************************"
	ShowTitle "${Location} status test"
	echo "----------------------------------------------------------------------"
	printf "\e[1;33m%-s\e[0m\n\n" " ${Question}"
	
	for((r=0;r<${#RandomOption[@]};r++))
	do
		OptionContent=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/Option[@index=\"${RandomOption[r]}\"]" -n ${XmlConfigFile} 2>/dev/null )
		String[$r]=$(echo "${OptionContent}")
		printf "%-5s\e[1m%-30s\e[0m" " [$((r+1))]" "${OptionContent}" 
		if [ ${RandomOption[r]} == ${CorrectlyOptionIndex} ] ; then
			StdAnswer="${OptionContent}"
		fi
		[ $((r%2)) == 1 ] && echo
	done
	echo
	echo "**********************************************************************"

	rm -rf msg ${BaseName}_ans.log 2>/dev/null
	cat <<-Msg >msg
	#!/bin/bash
	if (whiptail --title "${Location} status test" --yes-button "${String[0]}" --no-button "${String[1]}"  --yesno "${Question}" 10 60) then
		printf "%s" "${String[0]}" > ${BaseName}_ans.log
	else
		printf "%s" "${String[1]}" > ${BaseName}_ans.log
	fi
	Msg
	
	sync;sync;sync
	chmod 777 msg
	./msg
	JumperStatus=$(cat ${BaseName}_ans.log) 
	echo "The operator chooses: ${JumperStatus}"
	echo "${JumperStatus}" | grep -iwq "${StdAnswer}"
	if [ $? == 0 ]; then
		rm -rf msg ${BaseName}_ans.log 2>/dev/null
		return 0
	else
		return 1
	fi
}

RandomShowOption()
{
	clear
	local Location=$1
	local StdAnswer=99
	local Question=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/Question" ${XmlConfigFile} 2>/dev/null)
	local CorrectlyOptionIndex=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/CorrectlyOptionIndex" ${XmlConfigFile} 2>/dev/null)
	local TotalOption=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/Option" ${XmlConfigFile} 2>/dev/null | grep -iEc "[0-9A-Z]")
	local RandomOption=($(RandomNoRepetition ${TotalOption}))
	
	# ****************************************************************
	#                      JECO_SW1 status test
	# ----------------------------------------------------------------
	#  Which PIN is the jumping cap on?
	#
	#  [1] Pin1-2                        [2] Pin2-3
	#
	# ****************************************************************
	
	echo "**********************************************************************"
	ShowTitle "${Location} status test"
	echo "----------------------------------------------------------------------"
	printf "\e[1;33m%-s\e[0m\n\n" " ${Question}"
	for((r=0;r<${#RandomOption[@]};r++))
	do
		OptionContent=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[Location=\"${Location}\"]/Option[@index=\"${RandomOption[r]}\"]" -n ${XmlConfigFile} 2>/dev/null )
		printf "%-5s\e[1m%-30s\e[0m" " [$((r+1))]" "${OptionContent}"
		if [ ${RandomOption[r]} == ${CorrectlyOptionIndex} ] ; then
			StdAnswer=$((r+1))
		fi
		[ $((r%2)) == 1 ] && echo
	done
	echo -e "\n"
	echo "**********************************************************************"
	return ${StdAnswer}
}

main()
{
	local RandomJumper=($(RandomNoRepetition ${JumperTotalAmount}))
	for((j=0;j<${#RandomJumper[@]};j++))
	do
		local JumperLocation=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[${RandomJumper[j]}]/Location" -n ${XmlConfigFile} 2>/dev/null )
		local Question=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[${RandomJumper[j]}]/Question" ${XmlConfigFile} 2>/dev/null)
		local OptionCount=$(xmlstarlet sel -t -v "//Manual/TestCase[ProgramName=\"${BaseName}\"]/Member[${RandomJumper[j]}]/Option" -n ${XmlConfigFile} 2>/dev/null | grep -iEc "[0-9A-Z]" )
		local ShowOption=$(seq 1 ${OptionCount} | tr '\n' ' ')
		#Chance=1则一次就fail退出
		for((Chance=1;Chance>0;Chance--))
		do
			if [ ${DisplayMode} == "box" ] ; then
				RandomShowOptionWhiptail ${JumperLocation}
				if [ $? == 0 ] ; then
					echoPass "Check ${JumperLocation}"
					continue 2
				else
					echoFail "Check ${JumperLocation}"	
				fi
			else
				RandomShowOption ${JumperLocation}
				local StandardAnswer=$?
				
				BeepRemind 0
				numlockx on 2>/dev/null
				[ ${Debug} == 'enable' ] && echo "For debug only, the answer is: ${StandardAnswer}"
				echo -e "\e[0;33mIt's only 15 seconds to answer ... \e[0m"
				tput sc;tput rc;tput ed	
				printf "%-s%-s" "${Question}" " Input < ${ShowOption}>: "
				read -t 15 -n1 Answer
				echo -e "\b${Answer}"
				Answer=${Answer:-99}
				echo ${Answer} |  grep -wq "${StandardAnswer}"
				if [ $? == 0 ] ; then
					echo
					echoPass "Check ${JumperLocation}"
					echo
					continue 2
				else
					echo
					if [ ${Answer} == 99 ]; then
						echo -e "\e[1;31m Time out ...\e[0m"
					fi
					
					echoFail "Check ${JumperLocation}"
					if [ ${Chance} -gt 1 ] ; then
						echo -e "\e[1;33m [ $((Chance-1))/3 ] Try again ...\e[0m"
						sleep 1
					fi
					echo
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
declare XmlConfigFile JumperTotalAmount Location
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
			printf "%-s\n" "SerialTest,ManualTest"
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
