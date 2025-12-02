#!/bin/bash
#FileName : SmartFan.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2020-08-21"
	local UpdatedDate="2020-08-21"
	local Description="FAN 100% and 50% speed test"
	
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
	   0 : FAN 100% or 50% speed test pass
	   1 : FAN 100% or 50% speed test fail
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
			<ErrorCode></ErrorCode>
			<!--適用於BMC Smart FAN-->
			<!--FansIndex和Locations一一對應-->
			<FansIndex>1 2 3 4 5 6</FansIndex>
			<Locations>FANTACH1 FANTACH2 FANTACH3 FANTACH4 FANTACH5 FANTACH6</Locations>
			<!--最低半速,單位RPM-->
			<HalfSpeed>8400</HalfSpeed>
			<!--最低全速,單位RPM-->
			<FullSpeed>15000</FullSpeed>
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
	
	# Get the BIOS information from the config file(*.xml)
	FansIndex=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FansIndex" -n "${XmlConfigFile}" 2>/dev/null))
	Locations=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/Locations" -n "${XmlConfigFile}" 2>/dev/null))
	HalfSpeed=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/HalfSpeed" -n "${XmlConfigFile}" 2>/dev/null))
	FullSpeed=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FullSpeed" -n "${XmlConfigFile}" 2>/dev/null))
	if [ ${#FansIndex[@]} == 0 ] ; then
		Process 1 "Invalid xml config file ..."
		let ErrorFlag++		
	fi
	
	for ((i=0;i<${#FansIndex[@]};i++ ))
	do
		if [ ${FullSpeed[$i]} -lt ${HalfSpeed[$i]} ] ; then
			Process 1 "Half speed is greater than full speed ..."
			let ErrorFlag++
		fi
	done

	[ ${ErrorFlag} != 0 ] && exit 1
	return 0			
}

main()
{
	local FullHalf=(64 32)
	local FullHalfName=('全速' '半速')
	#Start ipmi service
	#service ipmi start
	modprobe ipmi_devintf
	if [ "$?" != "0" ]; then
		Process 1 "Load IPMI Driver"
		exit 1
	fi
	
	echo -e "\e[0;30;43m ******************************************************************** \e[0m"
	echo -e "\e[0;30;43m ***********               風扇半速/全速測試              *********** \e[0m"
	echo -e "\e[0;30;43m ******************************************************************** \e[0m"
	
	echo "Read the sensor, please wait ..."
	rm -rf "${BaseName}.log" 
	ipmitool sdr | grep -iw 'RPM' > "${BaseName}.log"
	
	#Check all FANs are installed
	for((l=0;l<${#Locations[@]};l++))
	do
		
		grep -iwq "${Locations[l]}" "${BaseName}.log" 
		if [ $? != 0 ] || [ $(cat "${BaseName}.log" | grep -iw "${Locations[l]}" | awk '{print $3}' | grep -c "[[:alpha:]]") != 0  ]; then
			Process 1 "${Locations[l]} is not installed ..."
			let ErrorFlag++
		fi
	done
	[ ${ErrorFlag} != 0 ] && exit 1
	
	
	# Stop BMC smart fan
	# ipmitool raw 0x38 0x14 0x0b 0x00 >/dev/null
	# if [ $? != 0 ] ; then
	# 	Process 1 "未能終止smart FAN 自動控制功能 ..."
	# 	exit 1
	# fi

	# sleep 3
	
	for ((h=0;h<${#FullHalf[@]};h++)) 
	do
		printf "%s" "${FullHalfName[h]} 測試中."
		for((i=0;i<${#FansIndex[@]};i++))
		do
			# ipmitool raw 0x38 0x03 ${pwm id} ${mode} ${duty} mode :0-auto 1-manual duty:10-100
			ipmitool raw 0x28 0x03 ${FansIndex[i]} 1 0x${FullHalf[h]} >/dev/null 2>&1
			if [ $? != 0 ] ; then
				Process 1 "設置${FansIndex[i]}到${FullHalfName[h]}失敗..."
				let ErrorFlag++
				continue
			fi
			sleep 0.2
			printf "%s" "."
		done
		
		# wait for 5s
		for((t=1;t<=5;t++))
		do
			printf "%s" "."
			sleep 1
		done

		rm -rf "${BaseName}.log" 
		ipmitool sdr | grep -iw 'RPM' > "${BaseName}.log" &
		for((s=1;s>0;s++))
		do
			ChildenProcesses=($(pgrep -P ${PPIDKILL} ipmitool))
			if [ ${#ChildenProcesses[@]} == 0 ] || [ ${s} -ge 15 ]; then
				break
			else
				sleep 1s
				printf "%s" "."
				if [ $((s%70)) == 0 ] ; then
					printf "\r%s\r" "                                                                       "
				fi
			fi
		
		done
		wait
		sync;sync;sync
		echo

		for((i=0;i<${#Locations[@]};i++))
		do
			SpeedOfFan[$i]=$(cat "${BaseName}.log" | grep -iw "${Locations[i]}" | awk '{print $3}')
			
			if [ ${h} == 0 ] ; then
				#if [ $i -ge 6 ] ; then
				#	printf "%s\n" "${SpeedOfFan[$i]}-${CpuFullSpeed}>0" | bc | grep -iwq "1"
				#else
					printf "%s\n" "${SpeedOfFan[$i]}-${FullSpeed[$i]}>0" | bc | grep -iwq "1"
				#fi
				if [ $? == 0 ] ; then
					Process 0 "${Locations[i]}當前${FullHalfName[h]}速度是${SpeedOfFan[$i]} RPM, 測試PASS. "
				else
					Process 1 "${Locations[i]}當前${FullHalfName[h]}速度是${SpeedOfFan[$i]} RPM, 測試FAIL. "
					let ErrorFlag++
				fi
			fi
		
			if [ ${h} != 0 ] ; then
				SpeedTest='PASS'
				#if [ $i -ge 6 ] ; then
				#	printf "%s\n" "${SpeedOfFan[$i]}-${CpuHalfSpeed}<0" | bc | grep -iwq "1"
				#else
					printf "%s\n" "${SpeedOfFan[$i]}-${HalfSpeed[$i]}<0" | bc | grep -iwq "1"
				#fi
				if [ $? == 0 ] ; then
					Process 1 "${Locations[i]}當前${FullHalfName[h]}速度是${SpeedOfFan[$i]} RPM(太慢), 測試FAIL. "
					let ErrorFlag++
					SpeedTest='FAIL'
				fi
				
				printf "%s\n" "${SpeedOfFan[$i]}-${HalfSpeed[$i]}*1.25>0" | bc | grep -iwq "1"
				if [ $? == 0 ] ; then
					Process 1 "${Locations[i]}當前${FullHalfName[h]}速度是${SpeedOfFan[$i]} RPM(太快), 測試FAIL. "
					let ErrorFlag++
					SpeedTest='FAIL'
				fi
				
				if [ ${SpeedTest} != 'FAIL' ] ; then
					Process 0 "${Locations[i]}當前${FullHalfName[h]}速度是${SpeedOfFan[$i]} RPM, 測試PASS. "
				fi

			fi
		done
	done
	
	# Start BMC smart fan
	# ipmitool raw 0x38 0x14 0x0b 0x01 >/dev/null 2>&1
	echo
	# FAN control change to Auto Mode
	printf "%s\n" "All Fan切换回Auto 模式."
	for((i=0;i<${#FansIndex[@]};i++))
	do
		# ipmitool raw 0x38 0x03 ${pwm id} ${mode} ${duty} mode :0-auto 1-manual duty:10-100
		ipmitool raw 0x28 0x03 ${FansIndex[i]} 0 0 >/dev/null 2>&1
		if [ $? != 0 ] ; then
			Process 1 "設置${FansIndex[i]}到Auto Mode失敗..."
			let ErrorFlag++
			continue
		fi
		sleep 0.2
		printf "%s" "."
	done
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "Smart FAN half and full speed test"
	else
		echoFail "Smart FAN half and full speed test"
		GenerateErrorCode
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare PPIDKILL=$$
declare XmlConfigFile FansIndex Locations HalfSpeed FullSpeed  ApVersion CpuHalfSpeed CpuFullSpeed
declare -i CpuHalfSpeed=4200
declare -i CpuFullSpeed=8600
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :i:z:d:P:VDx:g: argv
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
			printf "%-s\n" "SerialTest,SmartFanTest"
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
