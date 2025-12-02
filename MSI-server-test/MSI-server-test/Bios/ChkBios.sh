#!/bin/bash
#FileName : ChkBios.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.2"
	local CreatedDate="2018-05-22"
	local UpdatedDate="2020-12-25"
	local Description="BIOS version ,release date and DST status verify"
	
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
	printf "%16s%-s\n" "" "2018-06-26,新增DST可選測試項目"
	printf "%16s%-s\n" "" "2020-12-10,新增限制條件,讀出的版本與配置檔的關係: Newer/Older/Match"
	printf "%16s%-s\n" "" "           部分小卡的測試需要BIOS版本高於(Newer)指定版本才能測試"
	printf "%16s%-s\n" "" "2020-12-25,新增Pretest功能,以用於dual BIOS判定"	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
	if [ "${#ErrorCode}" != 0 ] ; then
		grep -iwq "${ErrorCode}" ${ErrorCodeFile} 2>/dev/null || echo "${ErrorCode}|${ShellFile}" >> ${ErrorCodeFile}
	else
		echo "NULL|NULL|${ShellFile}" >> ${ErrorCodeFile}
	fi
	sync;sync;sync
	return 0
}
 
Usage ()
{
cat <<HELP | more
Usage:
`basename $0` -v BiosVersion -r ReleaseDate [-d [2|3]] [-x lConfig.xml] [-DV]
`basename $0` -x lConfig.xml

	eg.: `basename $0` -v 5.12 -r 07/31/2017 -d 2
		 `basename $0` -x lConfig.xml
		 `basename $0` -D
		 `basename $0` -V
		 
	-v : Version of BIOS
	-r : Release date of BIOS
	-d : Daylight Saving time(DST) status of CMOS,value=2,or 3
		 Default equal to 2
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
	   0 : Check the BIOS pass: BIOS version and release date are match the standard
	   1 : Check the BIOS fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	
	
HELP
exit 3
}


ChkExternalCommands ()
{
	ExtCmmds=(xmlstarlet getCmosDST)
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

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<BIOS>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NXF02|Check BIOS version fail</ErrorCode>
			<Pretest>
				<!--Dual BIOS的時候用,需要滿足DetectCommand執行的結果等於PassCriterion,單BIOS則置空DetectCommand -->
				<Prompt>Set BIOS_SW1 jumper at Pin2-3</Prompt>
				<Location>BIOS_SW1,BIOS_LC</Location>
				<!--執行的指令返回值和PassCriterion指定的值完全一致則通過測試-->
				<DetectCommand PassCriterion="01">ipmitool raw 0x38 0x12 0xd6</DetectCommand>
			</Pretest>
			
			<!-- ChkBios.sh: for Check BIOS版本和發行日期 --> 
			<Version>6.00</Version>
			<!--PassCriterion: ReleaseDate Newer(更新於)/Older(更舊於)/Match(完全配備) -->
			<!--且Version的第一段必須完全一致如ES258IMS.102和ES258IMS.100的ES258IMS一致-->
			<ReleaseDate PassCriterion="Match">06/03/2016</ReleaseDate>
			<!-- 置空DST則不再測試,但會顯示在屏幕上 --> 
			<DST>2</DST>
			
			<!--文件存檔如下-->
			<SaveData>/TestAP/PPID/BIOSVER.TXT</SaveData>
		</TestCase>
	</BIOS>
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

GetParametersFrXML()
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
	
	# Get the BIOS information from the config file(*.xml)
	Prompt=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/Pretest/Prompt" -n "${XmlConfigFile}" 2>/dev/null)
	Location=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/Pretest/Location" -n "${XmlConfigFile}" 2>/dev/null)
	DetectCommand=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/Pretest/DetectCommand" -n "${XmlConfigFile}" 2>/dev/null)
	DetectCmdPassCriterion=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/Pretest/DetectCommand/@PassCriterion" -n "${XmlConfigFile}" 2>/dev/null)
	
	StdVersion=($(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/Version" -n "${XmlConfigFile}" 2>/dev/null))
	StdReleaseDate=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/ReleaseDate" -n "${XmlConfigFile}" 2>/dev/null)
	PassCriterion=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/ReleaseDate/@PassCriterion" -n "${XmlConfigFile}" 2>/dev/null)
	StdDstStatus=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/DST" -n "${XmlConfigFile}" 2>/dev/null)
	SaveData=$(xmlstarlet sel -t -v "//BIOS/TestCase[ProgramName=\"${BaseName}\"]/SaveData" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#StdVersion} == 0 ] ; then
		Process 1 "Invalid Version, error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi

	if [ ${#StdReleaseDate} == 0 ] ; then
		Process 1 "Invalid ReleaseDate,error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi
	
	if [ ${#PassCriterion} == 0 ] ; then
		PassCriterion='Match'
	fi
	
	echo "${PassCriterion}" | grep -iwq "newer\|older\|match"
	if [ $? != 0 ] ; then
		Process 1 "Invalid Pass Criterion: ${PassCriterion}"
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
	
	if [ ${#StdVersion} == 0 ] ||  [ ${#StdReleaseDate} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile} ..."
		let ErrorFlag++
	fi
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0
}

GetBiosInfo()
{
	local Vendor=$(dmidecode -t0  | awk -F':' '/Vendor:/{print $2}' | head -n1 | tr -d '\n')
	local Version=$(dmidecode -t0 | awk -F':' '/Version:/{print $2}' | head -n1 | tr -d '\n')
	local ReleaseDate=$(dmidecode -t0 | awk -F':' '/Release Date:/{print $2}' | head -n1  | tr -d '\n')
	local Address=$(dmidecode -t0 | awk -F':' '/Address:/{print $2}' | head -n1 | tr -d '\n')
	local RuntimeSize=$(dmidecode -t0 | awk -F':' '/Runtime Size:/{print $2}' | head -n1 | tr -d '\n')
	local ROMSize=$(dmidecode -t0 | awk -F':' '/ROM Size:/{print $2}' | head -n1 | tr -d '\n')
	local BiosRevision=$(dmidecode -t0 | awk -F':' '/BIOS Revision:/{print $2}' | head -n1 | tr -d '\n')
	local FirmwareRevision=$(dmidecode -t0 | awk -F':' '/Firmware Revision:/{print $2}' | head -n1 | tr -d '\n')

	printf "%15s\n" "=============================="
	printf "%15s\n" " Current BIOS Information"
	printf "%15s\n" "=============================="
	printf "%15s%-55s\n" "Bios Vendor       :" "${Vendor:-"Unknown"}"
	printf "%15s%-55s\n" "Bios Version      :" "${Version}"
	printf "%15s%-55s\n" "Bios Release Date :" "${ReleaseDate}"
	printf "%15s%-55s\n" "Address           :" "${Address:-"NULL"}"
	printf "%15s%-55s\n" "Runtime Size      :" "${RuntimeSize:-"NULL"}"
	printf "%15s%-55s\n" "ROM Size          :" "${ROMSize:-"NULL"}"
	printf "%15s%-55s\n" "Bios Revision     :" "${BiosRevision:-"NULL"}"
	printf "%15s%-55s\n" "Firmware Revision :" "${FirmwareRevision:-"NULL"}"
	printf "\n"
}

CompareSpec()
{
	[ ${#StdVersion} == 0 ] && { Process 1 "Error version setting in xml ..." || let ErrorFlag++ ; }
	[ ${#StdReleaseDate} == 0 ] && { Process 1 "Error Release date setting in xml ..." || let ErrorFlag++ ; }
	[ ${ErrorFlag} -ne 0 ] && exit 2

	CurVersion=$(dmidecode -t0 | grep -i "Version:" | head -n1 | awk -F':' '{print $2}' | tr -d '\n' | awk '$1=$1')
	local MainVersion=$(echo "${CurVersion}" | awk -F'.' '{print $1}' )
	CurReleaseDate=$(dmidecode -t0 | grep -i "Release Date:" | head -n1 | awk -F':' '{print $2}' | tr -d '\n'| awk '$1=$1')
	CurReleaseDateVal=$(date -d "${CurReleaseDate}" +%s)
	StdReleaseDateVal=$(date -d "${StdReleaseDate}" +%s)
	PassCriterion=$(echo "${PassCriterion}" | tr '[A-Z]' '[a-z]')
	case ${PassCriterion} in
		"older")
			echo "x${StdVersion}" | grep -iwq "x${MainVersion}"
			Process $? "Verify BIOS version (standard: ${StdVersion})" || let ErrorFlag++
			printf "%s\n" "${CurReleaseDateVal}-${StdReleaseDateVal}<0" | bc | grep -wq "1"
			Process $? "Verify BIOS release date(older than standard: ${StdReleaseDate})" || let ErrorFlag++
		;;
		
		"newer")
			echo "x${StdVersion}" | grep -iwq "x${MainVersion}"
			Process $? "Verify BIOS version (standard: ${StdVersion})" || let ErrorFlag++
			printf "%s\n" "${CurReleaseDateVal}-${StdReleaseDateVal}>0" | bc | grep -wq "1"
			Process $? "Verify BIOS release date(newer than standard: ${StdReleaseDate})" || let ErrorFlag++
			
		;;
		
		"match")
			echo "${CurVersion}" | grep -iwq "${StdVersion}"
			Process $? "Verify BIOS version (standard: ${StdVersion})" || let ErrorFlag++

			echo "${CurReleaseDate}" | grep -iwq "${StdReleaseDate}" 
			Process $? "Verify BIOS release date(match standard: ${StdReleaseDate})" || let ErrorFlag++
		;;
		esac
		
	# Show the DST status
	case ${StdDstStatus:-"null"} in
		2|3)	
			CurDstStatus=$(getCmosDST 2>/dev/null)
			echo "${CurDstStatus}" | grep -iwq "${StdDstStatus}"
			Process $? "Verify DST status(current: ${CurDstStatus}) ..." || let ErrorFlag++	
		;;
		
		null)
			CurDstStatus=$(getCmosDST 2>/dev/null)
			Process 0 "Get the DST(Current status: ${CurDstStatus}) ..."
		;;
		
		NA|*)printf "%-10s%-60s\n" "" "Does not support DST status,or ignore to verify ...";;
		esac
		
	# Write the recode to file 
	SaveData=${SaveData:-"../PPID/BIOSVER.TXT"}
	if [ ${ErrorFlag} == 0 ] ; then
		echo "${StdDstStatus}" | grep -iwq "2\|3"
		if [ $? == 0 ] ; then
			echo "${StdVersion},${StdReleaseDate},${CurDstStatus}" > ${SaveData}
		else
			echo "${StdVersion},${StdReleaseDate}" > ${SaveData}
		fi
		sync;sync;sync
	fi
	
	# Check the file is not empty
	local Length=$(cat ${SaveData} 2>/dev/null)
	if [ ${#Length} -le 3 ] && [ ${ErrorFlag} == 0 ]  ; then
		Process 1 "Check length of ${SaveData}"
		cat ${SaveData} 2>/dev/null
		let ErrorFlag++
	fi
}

Pretest()
{
	if [ "${#DetectCommand}" == "0" ] ; then
		return 0
	fi
	
	printf "\e[0;30;43m%s\e[0m\n" " ******************************************************************** "
	if [ ${#Prompt} == 0 ] ; then
		printf "\e[0;30;43m%10s%50s%10s\e[0m\n" " ****     " "請務必按WI提示操作" "     **** "
	else
		printf "\e[0;30;43m%10s%50s%10s\e[0m\n" " ****     " "${Prompt}" "     **** "
	fi
	printf "\e[0;30;43m%s\e[0m\n" " ******************************************************************** "
	echo
	printf "\e[1;33m%s\e[0m\n" "該程式測試的相關位置是: ${Location}"
	
	local TestResult=1
	echo "${DetectCommand}" | grep -iwq "ipmitool"
	if [ $? == 0 ] ; then
		command -v ipmitool >/dev/null 2>&1
		if [ $? != 0 ] ; then
			Process 1 "No such command: ipmitool"
			let ErrorFlag++
			exit 2
		else
			${DetectCommand} | grep -iwq "${DetectCmdPassCriterion}"
			TestResult=$?
		fi
	else
		if [ -f "${DetectCommand}" ] ; then
			chmod 777 "${DetectCommand}"
			./"${DetectCommand}" | grep -iwq "${DetectCmdPassCriterion}"
			TestResult=$?
		else
			${DetectCommand} | grep -iwq "${DetectCmdPassCriterion}"
			TestResult=$?
		fi	
	fi
	
	if [ ${TestResult} == 0 ] ; then
		Process 0 "Pretest verify ..."
	else
		Process 1 "Pretest verify ..."
		let ErrorFlag++
		exit 2
	fi
	return 0
}

main()
{
	Pretest
	GetBiosInfo
	CompareSpec

	if [ ${ErrorFlag} -ne 0 ] ; then
		echoFail "Check the BIOS version and release date"
		GenerateErrorCode
		exit 1
	else
		echoPass "Check the BIOS version and release date"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile StdVersion StdReleaseDate StdDstStatus SaveData
declare CurVersion CurReleaseDate CurDstStatus ApVersion
declare Prompt Location DetectCommand DetectCmdPassCriterion
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# == 0 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :d:r:v:P:VDx: argv
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
		
		d)StdDstStatus=${OPTARG};;
		r)StdReleaseDate=${OPTARG};;
		v)StdVersion=${OPTARG};;
		V)
			VersionInfo
			exit 1
		;;

		P)
			printf "%-s\n" "SerialTest,CheckBiosVersion"
			exit 1
		;;
		
		:)
			printf "\e[1;33m%-s\n\e[0m" "The option ${OPTARG} requires an argument."
			exit 3
		;;

		?)
			printf "\e[1;33m%-s\n\n\e[0m" "Invalid option: ${OPTARG}"
			Usage
		;;
		esac
done

main
[ ${ErrorFlag} != 0 ] && exit 1	
exit 0
