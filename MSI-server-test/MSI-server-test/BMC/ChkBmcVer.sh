#!/bin/bash
#FileName : ChkBmcVer.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.2"
	local CreatedDate="2018-06-14"
	local UpdatedDate="2023-07-27"
	local Description="Compare the BMC firmware version"
	
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
	printf "%16s%-s\n" "" "2020-12-10,新增限制條件,讀出的版本與配置檔的關係: Newer/Older/Match"
	printf "%16s%-s\n" "" "           部分小卡的測試需要BMC版本高於(Newer)指定版本才能測試"
	printf "%16s%-s\n" "" "2023-07-27,增加Dual BMC check for Dual BMC Model."
	printf "%16s%-s\n" "" "           增加BMC mc selftest check，system_fw_version check"
	printf "%16s%-s\n" "" "           目前针对FRU 只是进行读取并记录，后续根据实际状况check Fru信息"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet ipmitool)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			ipmitool)printf "%10s%s\n" "" "ipmitool-1.8.18-7.el7.x86_64.rpm";;
		esac
		
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
		0 : Compare the BMC version pass
		1 : Compare the BMC version fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP

exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<BMC>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NULL</ErrorCode>	
			<!-- ClrBmcMac.sh: for Clear BMC MAC -->
			<File>S212K103.ima</File>				
			<!--ChkBmcVer.sh: BMC Firmware version -->
			<!--PassCriterion: Newer(更新於)/Older(更舊於)/Match(完全配備),如果版本號不是有理數則需要完全Match -->
			<Version PassCriterion="Match">1.03</Version>
			<ReadVersionTool>ipmitool</ReadVersionTool>
			<SaveData>/TestAP/PPID/BMCVER.TXT"</SaveData>
		</TestCase>
	</BMC>
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
	FirmwareFile=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/File" -n "${XmlConfigFile}" 2>/dev/null)
	FirmwareVersion=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Version" -n "${XmlConfigFile}" 2>/dev/null)
	PassCriterion=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Version/@PassCriterion" -n "${XmlConfigFile}" 2>/dev/null)
	ReadVersionTool=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/ReadVersionTool" -n "${XmlConfigFile}" 2>/dev/null)
	SaveData=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/SaveData" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#PassCriterion} == 0 ] ; then
		PassCriterion='Match'
	fi

	echo "${PassCriterion}" | grep -iwq "newer\|older\|match"
	if [ $? != 0 ] ; then
		Process 1 "Invalid Pass Criterion: ${PassCriterion}"
		let ErrorFlag++
	fi
	
	if [ ${#FirmwareVersion} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi
	
	if [ ${#SaveData} == 0 ] ; then
		Process 1 "Invalid SaveData ..."
		let ErrorFlag++
	else
		if [ -d "${SaveData}" ] ; then
			Process 1 "${SaveData} is a directory ..."
			let ErrorFlag++
		fi
	fi
	
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0
}

CheckEnvironment ()
{
	if [ $(echo ${ReadVersionTool} | grep -ic 'ipmitool') -gt 0 ] ; then
		yum -q ${ReadVersionTool} 2>&1 | grep -iwq "not" 2>/dev/null
		if [ $? == 0 ] ; then
			Process 1 "${ReadVersionTool} is not installed yet"
			exit 4
		fi
	else
		if [ ! -f "${ReadVersionTool}" ] ; then
			Process 1 "No such file: ${ReadVersionTool}"
			exit 2
		else
			chmod 777 ${ReadVersionTool} 2>/dev/null
		fi
	fi
 } 
 
main()
{

	if [ $(echo ${ReadVersionTool} | grep -ic 'ipmitool') -gt 0 ] ; then
		#Load IPMI Driver,or: 	modprobe ipmi_si
		modprobe ipmi_devintf 2>/dev/null
		if [ "$?" != "0" ]; then
			Process 1 "Load IPMI Driver"
			exit 1
		fi
		ipmitool mc info
		CurFirmwareVersion=$(ipmitool mc info 2>/dev/null1 | grep "Firmware Revision" | cut -c 29-| head -n1 | tr -d ' ')
	else
		CurFirmwareVersion=$(./${ReadVersionTool} | cut -d ":" -f2 | tr -d ' ' | head -n1)
	fi
	
	#不是一個實數,則Pass的標準必須為完全匹配
	echo "${FirmwareVersion}" | grep -wEq "[0-9]{1,4}.[0-9]{1,4}"
	if [ $? !=  0 ] ; then
		PassCriterion='Match'
	fi
	
	PassCriterion=$(echo "${PassCriterion}" | tr '[A-Z]' '[a-z]')
	case ${PassCriterion} in
		"older")printf "%s\n" "${CurFirmwareVersion}-${FirmwareVersion}<0" | bc | grep -wq "1";;
		"newer")printf "%s\n" "${CurFirmwareVersion}-${FirmwareVersion}>0" | bc | grep -wq "1";;
		"match")printf "%s\n" "${CurFirmwareVersion}-${FirmwareVersion}==0" | bc | grep -wq "1";;
		esac

	if [ "$?" == "0" ] ; then
		echoPass "Current BMC FW version(${CurFirmwareVersion}) is ${PassCriterion}, verify"
		rm -rf "${SaveData}" 2>/dev/null
		if [ ${#FirmwareFile} != 0 ]; then
			# BMCVER.TXT = S165K131.ima
			# 需要确认维护的BMC 信息与实际读出来的版本匹配，才拷贝此信息作为BMCVER
			tempversion =$(echo $CurFirmwareVersion | tr -d ".")
			echo "${FirmwareFile}" |grep  -q $tempversion
			if [ $? == 0 ];then
				echo "${FirmwareFile}" > ${SaveData}
			else
				echo "${CurFirmwareVersion}" > ${SaveData}
			fi
		else
			# BMCVER.TXT = 1.31
			echo "${CurFirmwareVersion}" > ${SaveData}
		fi
		sync;sync;sync
		
		BmcString=$(cat ${SaveData} | head -n 1)
		if [ ${#BmcString} -lt 2 ] ; then
			Process 1 "Check length of ${SaveData}"
			let ErrorFlag++
		fi
	else
		echoFail "BMC FW version verify"
		echo "Current BMC firmware Version is: ${CurFirmwareVersion}"
		echo " BMC firmware Version should be: ${FirmwareVersion}"
		let ErrorFlag++
		GenerateErrorCode
		echo
		
		#if [ ${ErrorFlag} -ne 0 ] && [ -f "FlashBmcFW.sh" ]; then
		#	chmod 777 FlashBmcFW.sh 
		#	sh FlashBmcFW.sh -x ${ConfigFile}
		#	if [ $? != 0 ] ; then
		#		exit 1
		#	else
		#		# If pass , FlashBmcFW.sh will send shutdown command to OS
		#		init 0
		#		sleep 9999
		#	fi
		#fi

	fi
	[ ${ErrorFlag} != 0 ] && exit 1
}

ChkBmcInfo()
{
	#检查mc selftest结果是否PASS
	ipmitool mc selftest | grep -iwq "passed"
	if [ $? == 0 ];then
		Process 0 "mc selftest"
	else
		Process 1 "mc selftest"
		let ErrorFlag++
	fi

	#检查fw_version与BIOS 版本是否一致
	StdVersion=($(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"ChkBios\"]/Version" -n "${XmlConfigFile}" 2>/dev/null))
	CurSystemFwVersion=$(ipmitool mc getsysinfo system_fw_version 2>/dev/null | tr -d  ' ')
	echo ${CurSystemFwVersion} |grep -iwq ${StdVersion}
	if [ $? == 0 ];then
		echoPass "Current system_fw_version(${CurSystemFwVersion}) is match, verify"
	else
		echoFail "BMC system_fw_version verify"
		echo "Current system_fw_versione is: ${CurSystemFwVersion}"
		echo "BMC CurSystemFwVersion should be: ${StdVersion}"
		let ErrorFlag++
		echo
	fi

	#打印FRU信息，但是目前不进行测试
	ipmitool fru print 2>/dev/null

	if [ ${ErrorFlag} != 0 ];then
		GenerateErrorCode
		exit 1
	fi

}

ChkDualBMC ()
{
	local Dualnum=(1 2)
	for ((h=0;h<${#Dualnum[@]};h++))
	do
		version1=$(ipmitool raw 0x32 0x8f 0x08 0x0${Dualnum[h]} | awk -F " " '{print $1}')
		version2=$(ipmitool raw 0x32 0x8f 0x08 0x0${Dualnum[h]} | awk -F " " '{print $2}')
		version1=$(printf %d 0x${version1})
		version2=$(printf %02d 0x${version2})
		Curversion="${version1}.${version2}"
		
	if [ "${Curversion}"x == "${FirmwareVersion}"x ] ; then
		echoPass "JBMC${Dualnum[h]} FW version verify(Version: ${Curversion})"
		
	else
		echoFail "JBMC${Dualnum[h]} FW version verify"
		echo "Current JBMC${Dualnum[h]} firmware Version is: ${Curversion}"
		echo " BMC firmware Version should be: ${FirmwareVersion}"
		let ErrorFlag++
		GenerateErrorCode
		echo
		


	fi
	done
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare OsCmd=$(uname -m | cut -c 1-6)
declare XmlConfigFile   
declare FirmwareFile FirmwareVersion ReadVersionTool ApVersion PassCriterion
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
			printf "%-s\n" "SerialTest,CheckBmcVersion"
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
ChkBmcInfo
# ChkDualBMC
[ ${ErrorFlag} != 0 ] && exit 1
exit 0

