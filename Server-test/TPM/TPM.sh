#!/bin/bash
#FileName : TPM.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-06-26"
	local UpdatedDate="2019-07-03"
	local Description="TPM function test"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//TPM/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	
	ExtCmmds=(xmlstarlet eltt2) # tpm_selftest for TPM2.0以下
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		case ${ExtCmmds[$c]} in
			tpm_selftest)
				printf "%10s%s\n" "" "Please install: tpm-tools-1.3.9-2.el7.x86_64.rpm"
			;;
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
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the xml config file
	-x : config file,format as: *.xml	
	-V : Display version number and exit(1)

	return code:
		0 : TPM function test pass
		1 : TPM function test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<TPM>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS37|TPM test fail</ErrorCode>
			<!-- TPM.sh -->
			<!-- Version 1.0,1.2,or 2.0,S165F-->
			<!-- If the version of TPM is newer than 2.0, the OS should newer than Linux 7.3-->
			<Version>1.0</Version>
			
			<!--If the version of TPM is lower than 2.0, then set the TestTool null -->
			<TestTool>eltt2</TestTool>
		</TestCase>
	</TPM>		
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
	TpmVersion=$(xmlstarlet sel -t -v "//TPM/TestCase[ProgramName=\"${BaseName}\"]/Version" -n "${XmlConfigFile}" 2>/dev/null)
	TestTool=$(xmlstarlet sel -t -v "//TPM/TestCase[ProgramName=\"${BaseName}\"]/TestTool" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#TpmVersion} == 0 ]; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

CheckEnvironment ()
{
	OsVersion=$(cat /etc/redhat-release 2>/dev/null | awk -F'release' '{print $2}'| awk '{print $1}' | tr -d '. ' | cut -c 1-2)
	if [ "$(echo $TpmVersion | grep -ic '1.[0-9]')" == 0 ] ; then
		if [ ${OsVersion} -lt 73 ]; then
			ShowMsg --1 "For Linux/CentOS 7.3 or newer than 7.3 only"
			echo "Current OS version: `cat /etc/redhat-release`"
			exit 4
		fi
	fi
}

TpmFunctionTest()
{
	case ${TpmVersion} in
		1.[0-9])
			#Load TPM Driver
			modprobe tpm_infineon
			if [ $? -ne 0 ]; then
				Process 1 "Load TPM Driver"
				exit 4
			fi

			#Start tcsd daemon
			if [ ${OsVersion} -lt 70 ]; then
				# Linux 6.x
				/etc/init.d/tcsd start 2>/dev/null
			else
				# Linux 7.x
				systemctl start tcsd 2>/dev/null
			fi

			if [ $? != 0 ]; then
				Process 1 "Start tcsd daemon"
				exit 4
			fi

			#Run tpm_selftest
			tpm_selftest -l debug 2>/dev/null
			tpm_selftest -l debug 2>/dev/null | grep -iwq "bfbff5bf ff8f"
			if [ $? == 0 ]; then
				echoPass "TPM function test"
			else
				echoFail "TPM function test"
				GenerateErrorCode
				exit 1
			fi
		;;

		2.[0-9]|[Ss]165[Ff])
			# Designed by ianyeh
			if [ ${#TestTool} != 0 ] ; then		
				# Define the log
				LOG=${BaseName}.log
				rm -rf ${LOG} 2>/dev/null

				# Check the version
				$TestTool -gc 2>/dev/null | tee "${LOG}" 
				sync;sync;sync
				if [ "$(awk '/^TPM_PT_FAMILY_INDICATOR:/{print $NF}' "${LOG}" | grep -iwc "$TpmVersion" )" -lt 1 ]; then
					Process 1 "Verify the TPM version ..."
					printf "%-10s%-60s\n" "" "   Current TPM card version is: `awk '/^TPM_PT_FAMILY_INDICATOR:/{print $NF}' "${LOG}" | grep [0-9] || echo "NULL"`"
					printf "%-10s%-60s\n" "" "The TPM card version should be: $TpmVersion"
					exit 1
				fi

				# TPM Self Test
				$TestTool -Tt 2>/dev/null | tee -a "${LOG}" 
				if [ -n "$(grep -a '^Successfully tested. Works as expected.$' "${LOG}")" ]; then
					echoPass "TPM function test"
				else
				
					# Try the other way again
					if [ $(dmesg | grep ACPI | grep -c TPM2) -ne 0 ] && [  $(dmesg | grep tpm_tis | grep -c '2.0 TPM') -ne 0 ]; then
						if [ $(lsmod | grep -c tpm_crb) -ne 0 ]; then
							echo
							dmesg | grep ACPI | grep  TPM2
							dmesg | grep tpm_tis | grep '2.0 TPM'
							lsmod | grep tpm_crb
							echo
							Process 0 "Detect TPM card ..."
						else
							Process 1 "Detect TPM card ..."
							exit 1
						fi
					fi
					
					echoFail "TPM function test"
					GenerateErrorCode
					exit 1
				fi
			else
				if [ $(dmesg | grep ACPI | grep -c TPM2) -ne 0 ] && [  $(dmesg | grep tpm_tis | grep -c '2.0 TPM') -ne 0 ]; then
					if [ $(lsmod | grep -c tpm_crb) -ne 0 ]; then
						echo
						dmesg | grep ACPI | grep  TPM2
						dmesg | grep tpm_tis | grep '2.0 TPM'
						lsmod | grep tpm_crb
						echo
						Process 0 "Detect TPM card ..."
					else
						Process 1 "Detect TPM card ..."
						exit 1
					fi
				else
					Process 1 "Detect TPM card ..."
					exit 1
				fi
			fi
		;;
		
		*)
			Process 1 "Invalid TPM version: ${TpmVersion}"
			exit 3
		;;
		esac	
}

main()
{
	#CheckEnvironment
	TpmFunctionTest
	[ ${ErrorFlag} != 0 ] && exit 1	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile TpmConfigFile TpmVersion TestTool OsVersion
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
			printf "%-s\n" "SerialTest,CheckTPM"
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
