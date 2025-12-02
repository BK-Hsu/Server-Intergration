#!/bin/bash
#FileName : ChkFru.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2020-08-21"
	local UpdatedDate="2020-08-21"
	local Description="Verify the FRU infomation"
	
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
		if [ $? != 0 ] ; then
			echo "${ErrorCode}|${BaseName}.sh" >> ${ErrorCodeFile}	
		fi
	else
		echo "NULL|NULL|${BaseName}.sh" >> ${ErrorCodeFile}
	fi
	sync;sync;sync
	return 0
}
 
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage:
`basename $0` [-x lConfig.xml] [-DV]

	eg.: `basename $0` -x lConfig.xml
		 `basename $0` -D
		 
	-x : config file,format as: *.xml
	-D : Dump the sample xml config file
	-V : Display version number and exit(1)
	
	return code:
	   0 : Check Fru infomation pass
	   1 : Check Fru infomation fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail
	
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<BMC>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NXF11|BIOS DMI TEST FAIL</ErrorCode>
			<!--BMC FRU比對程式-->
			<!--Name: 作為程式的索引名稱-->
			<!--StringOrFile: 填寫為字符串時直接比較，填寫文件(TXT)的絕對路徑則從文件從讀取-->
			<Item>
				<Name>Chassis Part Number</Name>
				<StringOrFile>S258</StringOrFile>
			</Item>
			
			<Item>
				<Name>Board Part Number</Name>
				<StringOrFile>MS-S2581</StringOrFile>
			</Item>
			
			<Item>
				<Name>Product Manufacturer</Name>
				<StringOrFile>EPS</StringOrFile>
			</Item>	
			
			<Item>
				<Name>Product Part Number</Name>
				<StringOrFile>/TestAP/PPID/MODEL.TXT</StringOrFile>
			</Item>
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
	Count=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Item/Name" -n "${XmlConfigFile}" 2>/dev/null | wc -l)

	if [ ${Count} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
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

main()
{
	rm -rf ${BaseName}.log 2>/dev/null
	#Load IPMI Driver,or: 	modprobe ipmi_si
	modprobe ipmi_devintf 2>/dev/null
	ipmitool fru | tee ${BaseName}.log
	
	printf "%s\n" "----------------------------------------------------------------------"
	for((n=1;n<=${Count};n++))
	do
		
		Name=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Item[$n]/Name" -n "${XmlConfigFile}")
		StringOrFile=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Item[$n]/StringOrFile" -n "${XmlConfigFile}")
		if [ $(echo ${StringOrFile} | grep -iwEc "TXT+$") == 0 ] ; then
			IsString='true'
		else
			IsString='false'
		fi

		if [ ${IsString} == "false" ] ; then
			#如果不是字符串則從文件中取值
			if [ ! -f "${StringOrFile}" ] ; then
				Process 1 "No found the file: ${StringOrFile} ... " 
				let ErrorFlag++
				continue
			fi
			TargetValue=$(head -n1 ${StringOrFile})
		else
			TargetValue=${StringOrFile}
		fi

		cat ${BaseName}.log 2>/dev/null | grep -iw "${Name}" | grep -iwq "${TargetValue}"
		if [ $? != 0 ] ; then
			Process 1 "Verify the infomation of ${Name}, it should be: ${TargetValue}" 
			let ErrorFlag++
		else
			Process 0 "Verify the infomation of ${Name} ... " 
			
		fi
	done


	if [ ${ErrorFlag} -ne 0 ] ; then
		echoFail "Verify the FRU infomation "
		GenerateErrorCode
		exit 1
	else
		echoPass "Verify the FRU infomation"
	fi
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile Count
declare IsString='false'
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# == 0 ] ; then
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
			exit 1
		;;
		
		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,CheckFRU"
			exit 1
		;;		
		
		:)
			printf "\e[1;33m%-s\n\e[0m" "The option ${OPTARG} requires an argument."
			exit 3
		;;

		?)
			printf "\e[1;33m%-s\n\n\e[0m" "Invalid option: ${OPTARG}"
			echo
			Usage
		;;
		esac
done

main
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
