#!/bin/bash
#FileName : ChkPwrSwitch.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-08-25"
	local UpdatedDate="2020-09-15"
	local Description="Check the Power switch or the button"
	
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
	printf "%16s%-s\n" "" "2020-09-15,新增Console模式"
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
	ExtCmmds=(xmlstarlet md5sum)
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
`basename $0` -x lConfig.xml [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml		
	-V : Display version number and exit(1)
	
	return code:
		0 : Power switch check pass
		1 : Power switch check fail
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
	#TestMode=$(xmlstarlet sel -t -v "//Button/TestCase[ProgramName=\"${BaseName}\"]/TestMode" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

main()
{
	history | tail -n 4 | grep -iwq "poweroff\|shutdown\|init 0"
	if [ $? == 0 ] ; then
		history | tail -n 4 | grep -iw "poweroff\|shutdown\|init 0"
		Process 1 "Invalid system down mode ..."
		exit 1
	fi
	
	local OsVersion=$(uname -r)
	if [ "${OsVersion:0:1}" -lt "3" ] ; then 
		grep -iq "id:5:" /etc/inittab >/dev/null 2>&1
	else
		systemctl get-default | grep -iq "graphical" >/dev/null 2>&1
	fi

	if [ "$?" == 0 ] ; then
	#if [ $(echo ${TestMode} | grep -iwc "console") == 0 ] ; then
		printf "\e[0;30;43m%-70s\e[0m\n" "**********************************************************************"
		printf "\e[0;30;43m%-70s\e[0m\n" "*****                   關機鍵測試結果確認程式                   *****"
		printf "\e[0;30;43m%-70s\e[0m\n" "**********************************************************************"
		echo
		#if [ -s ${BaseName:3:50}.log ] && [ -s ${BaseName:3:50}.md5 ]; then
		if [ -s ${BaseName:3:50}.log ] ; then
			#if [ $(cat ${BaseName:3:50}.log | grep -iE "[0-9A-Z]" 2>&1 | grep -wc "Binary") == 1 ] && [ $(md5sum -c ${BaseName:3:50}.md5 2>&1 | grep -iwc "ok" ) != 0 ] ; then
			if [ $(cat ${BaseName:3:50}.log | grep -iE "[0-9A-Z]" 2>&1 | grep -wc "Binary") == 1 ] ; then
				Process 0 "檢查到上次關機是按關機鍵關機的..."
			else
				Process 1 "您可能不是按正確的流程關機..."
				let ErrorFlag++
			fi
		else
			Process 1 "您可能不是按WI或屏幕提示的流程進行正確的關機..."
			printf "%10s\e[1m%s\e[0m\n" "" "本程式需要配合${BaseName:3:50}.sh使用 ...."
			let ErrorFlag++
		fi
	else
		printf "\e[0;30;43m%-70s\e[0m\n" "**********************************************************************"
		printf "\e[0;30;43m%-70s\e[0m\n" "*****                   Check the power button                   *****"
		printf "\e[0;30;43m%-70s\e[0m\n" "**********************************************************************"
		echo
		if [ -s ${BaseName:3:50}.log ] && [ $(cat ${BaseName:3:50}.log | grep -iE "[0-9A-Z]" 2>&1 | grep -iwc "Binary") == 1 ]; then
			Process 0 "Power button is pressed at last shutdown..."
		else
			Process 1 "You may not be shutting down in the correct process..."
			printf "%10s\e[1m%s\e[0m\n" "" "Run ${BaseName:3:50}.sh at first ...."
			let ErrorFlag++
		fi
	fi
	
	
	if [ ${ErrorFlag} == 0 ] ; then
		rm -rf ${BaseName:3:50}.log ${BaseName:3:50}.md5 >/dev/null 2>&1
		echoPass "Verify the test record of button \"${Location}\" "
	else
		echoFail "Verify the test record of button \"${Location}\" "
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
declare -i ErrorFlag=0
declare XmlConfigFile Location TestMode ApVersion
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
			printf "%-s\n" "SerialTest,CheckPowerButton"
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
