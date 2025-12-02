#!/bin/bash
#FileName : BmcSD.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2020-12-14"
	local UpdatedDate="2020-12-14"
	local Description="SD card read and write test"
	
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
	ExtCmmds=(xmlstarlet expect ssh)
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
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V

	-D : Dump the sample xml config file	
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
		
	return code:
	   0 : SD Card read and write test pass
	   1 : SD Card read and write test fail
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
			<ErrorCode>TXC02|SD/MS/CF Card test fail</ErrorCode>
			
			<UserInfo>
				<UserID>sysadmin</UserID>
				<Password>superuser</Password>
				<!--可指定主機的IP地址, 缺省則從BMC讀取-->
				<HostIP>20.40.2.195</HostIP>
			</UserInfo>
			<SD>
				<Device>/dev/mmcblk0</Device>
				<Speed>
					<!--SD 4K讀寫同時達到如下速度測試PASS,單位是MB/s-->
					<Read>10</Read>
					<Write>10</Write>
				</Speed>				
			</SD>
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
	UserID=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/UserInfo/UserID" -n "${XmlConfigFile}" 2>/dev/null)
	Password=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/UserInfo/Password" -n "${XmlConfigFile}" 2>/dev/null)
	HostIP=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/UserInfo/HostIP" -n "${XmlConfigFile}" 2>/dev/null)
	SdDevice=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/SD/Device" -n "${XmlConfigFile}" 2>/dev/null)
	ReadSpeed=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/SD/Speed/Read" -n "${XmlConfigFile}" 2>/dev/null | grep -E "[0-9]")
	WriteSpeed=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/SD/Speed/Write" -n "${XmlConfigFile}" 2>/dev/null | grep -E "[0-9]")
	if [ ${#UserID} == 0 ] ; then
		Process 1 "User id is null ..."
		let ErrorFlag++
	fi
	
	if [ ${#SdDevice} == 0 ] ; then
		Process 1 "SD device is null ..."
		let ErrorFlag++
	fi
	
	if [ ${#ReadSpeed} == 0 ] ; then
		Process 1 "Read speed is null or invalid ..."
		let ErrorFlag++
	else
		if [ ${ReadSpeed} == 0 ] ; then
			Process 1 "Read speed is zero ..."
			let ErrorFlag++
		fi
	fi
		
	if [ ${#WriteSpeed} == 0 ] ; then
		Process 1 "Write speed is null or invalid ..."
		let ErrorFlag++
	else
		if [ ${WriteSpeed} == 0 ] ; then
			Process 1 "Write speed is zero ..."
			let ErrorFlag++
		fi
	fi

	[ ${ErrorFlag} != 0 ] && exit 1
	return 0			
}

CheckIPaddr ()
{
	local IPaddr=$1
	echo ${IPaddr} | grep -iq "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$"
	if [ "$?" != "0" ] ; then 
		Process 1 "Invalid IP address: ${IPaddr}"
		return 1
	fi 

	for ((i=1;i<=4;i++))
	do
		IPaddrSegment=$(echo ${IPaddr} | awk -F'.'  -v S=$i '{print $S}')
		IPaddrSegment=${IPaddrSegment:-"999"}
		if [ $IPaddrSegment -gt 255 ] || [ $IPaddrSegment -lt 0 ] ; then 
			Process 1 "Invalid IP address: ${IPaddr}"
			return 1
		fi 
	done 
	return 0
}

GetHost()
{
	if [ ${#HostIP} != 0 ] ; then
		ping ${HostIP} -w 3 2>/dev/null
		if [ $? == 0 ] ; then
			Process 0 "Link the Host ..."
			return 0
		fi
	fi
	
	local Channel=(1 8)
	for((c=0;c<${#Channel[@]};c++))
	do
		HostIP=$(ipmitool lan print ${Channel[c]} | grep "IP Address" | cut -d ":" -f2 | tail -1 | awk '$1=$1')
		echo ${HostIP} | grep -wq "0.0.0.0" && continue
		echo ${HostIP} | grep -wq "255.255.255.255" && continue
		CheckIPaddr ${HostIP} && break
	done
	
	if [ ${c} == ${#Channel[@]} ] ;then
		Process 1 "Can not link the Host ..."
		return 1
	else
		for((i=1;i<=3;i++))
		do
			ping ${HostIP} -w 3
			if [ $? == 0 ] ; then
			Process 0 "Link the Host ..."
				break
			else
				if [ $(dhclient --help 2>&1 | grep -wFc "[--timeout" ) == 1 ] ; then
					dhclient --timeout 5 >/dev/null 2>&1
				elif [ $(dhclient --help 2>&1 | grep -wFc "[-timeout" ) == 1 ] ; then
					dhclient -timeout 5  >/dev/null 2>&1
				else
					Process 1 "No argument 'timeout' for dhclient ..."
					return 1
				fi
			fi
		done
	
		if [ ${i} -gt 3 ] ; then
			Process 1 "Can not link the Host ..."
			return 1
		fi
	fi
	return 0
}

SDdetect()
{
	rm -rf DetectSD.exp 2>/dev/null
	cat<<-EOF > DetectSD.exp
	#!`command -v expect`
	set timeout 20
	spawn ssh ${UserID}@${HostIP}
	expect	{
		"*yes*" {send "yes\r"}
		"*assword*" {send "${Password}\r"}
		}
	
	expect	{
		"*assword*" {send "${Password}\r"}
		"#" {send "ls ${SdDevice}\r"}
	}
	expect "#"
	send "ls ${SdDevice}\r"
	
	expect "#"
	send  "exit\r" 
	expect eof
	EOF
	chmod 777 DetectSD.exp 2>/dev/null
	${WorkPath}/DetectSD.exp > DetectSD_${BaseName}.log 2>&1  
	rm -rf DetectSD.exp 2>/dev/null
	sync;sync;sync
	cat DetectSD_${BaseName}.log 2>/dev/null | grep -iwEq "^${SdDevice}"
	if [ $? != 0 ] ; then
		Process 1 "Detect the SD card fail. No SD card(${SdDevice}) found ..."
		exit 1
	else
		Process 0 "Detected a SD card on system ..."
	fi
}

SDrw()
{
	rm -rf rwSD.exp 2>/dev/null
	cat<<-EOF > rwSD.exp
	#!`command -v expect`
	set timeout 30
	spawn ssh ${UserID}@${HostIP}
	expect	{
		"*yes*" {send "yes\r"}
		"*assword*" {send "${Password}\r"}
		}
	
	expect	{
		"*assword*" {send "${Password}\r"}
		"#" {send "ls ${SdDevice}\r"}
	}
	expect "#"
	send "dd if=${SdDevice} of=/dev/null  bs=4k count=1000 \r"

	expect "#" 
	send "dd if=/dev/zero of=${SdDevice} bs=4k count=1000 conv=fsync\r" 
	
	expect "#"  
	send "cd\n"

	expect "#"
	send  "exit\r" 
	expect eof
	EOF
	chmod 777 rwSD.exp 2>/dev/null
	${WorkPath}/rwSD.exp 2>&1 | tee Rw_${BaseName}.log
	cat -v Rw_${BaseName}.log | sed "s/\^M//g" > ${BaseName}.log
	mv -f ${BaseName}.log Rw_${BaseName}.log 2>/dev/null
	rm -rf rwSD.exp 2>/dev/null
	sync;sync;sync
}

ParseLog()
{
	CurReadSpeed=$(cat Rw_${BaseName}.log 2>/dev/nul | grep -B20 "if=/dev/zero" |grep "copied" | awk -F', ' '{print $NF}' | awk '{print $1}' | head -n1 | tr -d "[[:alpha:]]/")
	CurReadUnit=$(cat Rw_${BaseName}.log 2>/dev/nul | grep -B20 "if=/dev/zero" | grep "copied" | awk -F', ' '{print $NF}' | awk '{print $NF}' | head -n1 | tr -d "[0-9].")
	CurReadUnit=${CurReadUnit:-"MB/s"}
	CurReadSpeed=${CurReadSpeed:-0.00}
	if [ $(echo ${CurReadUnit} | grep -iwc "GB/s") == 1 ] ; then
		CurReadSpeed=$((CurReadSpeed*1024))
		CurReadUnit="MB/s"
	elif [ $(echo "${CurReadUnit}" | grep -iwc "MB/s") == 1 ] ; then
		:
	elif [ $(echo "${CurReadUnit}" | grep -iwc "kB/s") == 1 ] ; then
		CurReadSpeed=$(printf "%0.2f\n" "`echo "scale=2;${CurReadSpeed}/1024" |bc`")
		CurReadUnit="MB/s"
	else
		let ErrorFlag++	
	fi

	echo "${CurReadSpeed}>=${ReadSpeed}" | bc | grep -wq "1"
	if [ $? == 0 ] ; then
		Process 0 "SD card current 4k read speed is: ${CurReadSpeed}${CurReadUnit}"
	else
		Process 1 "SD card current 4k read speed is: ${CurReadSpeed}${CurReadUnit},lower than spec."
		let ErrorFlag++
	fi
	
	CurWriteSpeed=$(cat Rw_${BaseName}.log 2>/dev/nul | grep -A20 "if=/dev/zero" | grep "copied" | awk -F', ' '{print $NF}' | awk '{print $1}' | tail -n1 | tr -d "[[:alpha:]]/" )
	CurWriteUnit=$(cat Rw_${BaseName}.log 2>/dev/nul | grep -A20 "if=/dev/zero" | grep "copied" | awk -F', ' '{print $NF}' | awk '{print $NF}' | tail -n1 | tr -d "[0-9].")
	CurWriteUnit=${CurWriteUnit:-"MB/s"}
	CurWriteSpeed=${CurWriteSpeed:-0.00}
	if [ $(echo ${CurWriteUnit} | grep -iwc "GB/s") == 1 ] ; then
		CurWriteSpeed=$((CurWriteSpeed*1024))
		CurWriteUnit="MB/s"
	elif [ $(echo ${CurWriteUnit} | grep -iwc "MB/s") == 1 ] ; then
		:
	elif [ $(echo ${CurWriteUnit} | grep -iwc "kB/s") == 1 ] ; then
		CurWriteSpeed=$(printf "%0.2f\n" "`echo "scale=2;${CurWriteSpeed}/1024" |bc`")
		CurWriteUnit="MB/s"
	else
		let ErrorFlag++	
	fi

	echo "${CurWriteSpeed}>=${WriteSpeed}" | bc | grep -wq "1"
	if [ $? == 0 ] ; then
		Process 0 "SD card current 4k write speed is: ${CurWriteSpeed}${CurWriteUnit}"
	else
		Process 1 "SD card current 4k write speed is: ${CurWriteSpeed}${CurWriteUnit},lower than spec"
		let ErrorFlag++
	fi	
}

main()
{
	GetHost
	if [ $? == 0 ] ; then 
		SDdetect
		SDrw
		sleep 1
		ParseLog
	else
		printf "\e[1;33m%s\e[0m\n" "請確認主板已經聯網,且BMC已經獲得IP地址..."
		let ErrorFlag++
	fi
	echo
	
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "SD card test"
	else
		echoFail "SD card test"
		GenerateErrorCode
	fi
	[ ${ErrorFlag} != 0 ] && exit 1
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile ApVersion
declare HostIP UserID Password SdDevice ReadSpeed WriteSpeed
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
			printf "%-s\n" "SerialTest,BmcSDtest"
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
