#!/bin/bash
#FileName : Sensors.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-11-24"
	local UpdatedDate="2023-02-21"
	local Description="Sensors test for cards"
	
	echo "$@" | grep -iq "getVersion" && return 0
	
	#    Linux Functional Test Utility Suites for Enterprise Platform Server
	#  Copyright(c) Micro-Star Int'L Co.,Ltd. 2019 - 2020. All Rights Reserved.
	#             Author：CodyQin, qiutiqin@msi.com
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
	printf "%16s%-s\n" "" "2023-02-21,add ipmitool raw command to read Temperature on card"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
				ipmitool)printf "%10s%s\n" "" "Please install: ipmitool-1.8.18-7.el7.x86_64.rpm";;
			esac
			let ErrorFlag++
		else
			chmod 777 ${_ExtCmmd}
		fi
	done
	[ ${ErrorFlag} != 0 ] && exit 127
	return 0
}

ShowTitle()
{
	local BlankCnt=0
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
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
	-V : Show the version and exit(1)
		
	return code:
		0 : Sensors on cards test pass
		1 : Sensors on cards test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<HW>	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>CXSAF|Sensor test fail</ErrorCode>
			
			<!--測試Sensor選項清單-->
			<Sensors>
				<TestItem>OCP_Amb_TEMP</TestItem>
				<TestItem>PSU1_AMB_Temp</TestItem>
			</Sensors>
			<!--如果使用ipmitool sensor读取，TestMethod 设定为Sensors-->
			<!--如果使用ipmitool raw读取，TestMethod 设定为raw_command-->
			<!--不设定默认使用Sensors作为选项-->
			<TestMethod>raw_command</TestMethod>
			<raw_comand>
				<ReadCommand>0x06 0x52 0x03 0x92 0x01 0x00</ReadCommand>
				<SwitchCommand>0x06 0x52 0x03 0xe2 0x00 0x04</SwitchCommand>
				<i2cbus>6</i2cbus>
				<location>S321A_Temp</location>
				<minTemp>15</minTemp>
				<maxTemp>45</maxTemp>
			</raw_comand>
		</TestCase>
	</HW>
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
	# Get the testmethod from config file
	TestMethod=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/TestMethod" -n "${XmlConfigFile}" 2>/dev/null)
	TestMethod=${TestMethod:-"Sensors"}
	if [ "$TestMethod" == "Sensors" ];then
		# Get the information from the config file(*.xml)
		TestItems=($(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Sensors/TestItem" -n "${XmlConfigFile}" 2>/dev/null | tr -d ' '))
		if [ ${#TestItems[@]} == 0 ] ; then
			Process 1 "Error config file: ${XmlConfigFile}"
			exit 3
		fi
	elif [ "$TestMethod" == "raw_command" ]; then
		# Get the information from the config file(*.xml)
		Location=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/raw_comand/location" -n "${XmlConfigFile}" 2>/dev/null)
		ReadCommand=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/raw_comand/ReadCommand" -n "${XmlConfigFile}" 2>/dev/null)
		SwitchCommand=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/raw_comand/SwitchCommand" -n "${XmlConfigFile}" 2>/dev/null)
		min_temp=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/raw_comand/minTemp" -n "${XmlConfigFile}" 2>/dev/null)
		max_temp=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/raw_comand/maxTemp" -n "${XmlConfigFile}" 2>/dev/null)
	else
		Process 1 "Not avaluable TestMethod, should be Sensors or raw_comand"
		exit 3
	fi
	
	return 0
}

HWM_raw_command()
{
	for((t=1;t<=3;t++))
	do
		#local TargetIndex=$1
		#local TargetBmcMac=$(cat -v $2 | tr [a-z] [A-Z] | head -n1 | grep -E '^[0-9A-F]{12}+$' )
		# swith channel before write eeprom data
		val1='Item_Name';  val2='Current';  val3='Minimum';  val4='Maximum';  val5='Result'
		echo | awk -v v1=$val1 -v v2=$val2 -v v3=$val3 -v v4=$val4 -v v5=$val5 '{print v1 "\t\t" v2 "\t\t" v3 "\t\t" v4 "\t\t" v5}'
		echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
		#如果switchcommand 内容为空，则默认不需要切换i2c 通道，直接读取sensor
		if [ ${#SwitchCommand[@]} != 0 ];then
			ipmitool raw ${SwitchCommand}
			if [ $? != 0 ];then
				Process 1 "Switch smbus channel"
				exit 1
			fi
		fi

		#read card eeprom data
		temp_x16=($(ipmitool raw $ReadCommand))
		if [[ ${#temp_x16[@]} != 1 ]];then
			ipmitool raw $ReadCommand
			Process 1 "Can't read the Temperature"
			exit 1
		fi
		temp1=($(printf %d 0x${temp_x16}))
		if [[ $temp1 -ge ${min_temp} ]] && [[ $temp1 -le ${max_temp} ]];then
			printf "\e[33m%-24s%-20s%-18s%-10s%-10s\e[0m\n" "$Location" "$temp1" "${min_temp}" "${max_temp}" "pass"
		else
	        printf "\e[33m%-24s%-20s%-18s%-10s%-10s\e[0m\n" "$Location" "$temp1" "${min_temp}" "${max_temp}" "fail"
			let ErrorFlag++
		fi
	done

	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Check the sensor(s) on cards test"
		GenerateErrorCode
		exit 1
	else
		echoPass "Check the sensor(s) on cards test"
	fi
}

HWM_Sensors ()
{
	[ ! -d  .temp ] && mkdir -p .temp

	# IgnoreItems="P3V3\|P5V"
	SoleTestItems=($(echo ${TestItems[@]} | tr ' ' '\n' | sort -u ))
	SoleTestItems=$(echo ${SoleTestItems[@]} | sed 's/ /\\|/g')

	# Define the Major Project
	MajorProject=(Voltages Current Temperatures FANs)
	MajorProjectUnit=(Volts Amps degrees RPM)
	
	local TestCount=(1st 2nd 3rd 4th 5th)
	
	# 2020/11/17 新增測試3次OK才算測試PASS
	rm -rf .temp/hwm_*.log .temp/${BaseName}_*.log  2>/dev/null
	for((t=1;t<=1;t++))
	do
		printf "%s\r" "The ${TestCount[t-1]} testing, now reading the sensors, please wait ..."
		ipmitool sensor 2>/dev/null | grep -iw "${SoleTestItems}" > .temp/${BaseName}_${t}.log
		sync;sync;sync
		
		# hardware monitor Test 
		for((h=0;h<${#MajorProjectUnit[@]};h++))
		do
			if [ ${h} == 0 ] ; then
				echo
				# Check hardware
				val1='Sensor Name';  val2='Current';  val3='Minimum';  val4='Maximum';  val5='Result'
				echo | awk -v v1="$val1" -v v2=$val2 -v v3=$val3 -v v4=$val4 -v v5=$val5 '{print v1 "\t\t" v2 "\t\t" v3 "\t\t" v4 "\t\t" v5}'
				echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
			fi
			
			TempLog=.temp/hwm_${MajorProjectUnit[$h]}.log
			rm -rf ${TempLog} >/dev/null 2>&1
			cat .temp/${BaseName}_${t}.log 2>/dev/null | grep -iw "${MajorProjectUnit[$h]}" > ${TempLog}
			sync;sync;sync

			# init the array
			GetSensorName=()
			GetSensorName=($(awk -F '|' '{print $1}' ${TempLog} ))

			for ((i=0; i<${#GetSensorName[@]}; i++))
			do
				[ ${i} == 0 ] && printf "\e[33m%-28s%-42s\e[0m\n" " -----  ${MajorProject[$h]} test " "Unit: ${MajorProjectUnit[$h]}  -----"
				cat ${TempLog} | grep -w "${GetSensorName[$i]}" | grep -iq 'ok' > /dev/null 2>&1
				if [ $? -eq 0 ];then
					msg='PASS'
					grep -w "${GetSensorName[$i]}" ${TempLog} | awk -F '|' -v MSG="$msg" '{print $1 "\t" $2 "\t" $7 "\t" $8 "\t" MSG}'
				else
					let ErrorFlag++
					msg='FAIL'
					echo -e "\e[1;31m`grep -w "${GetSensorName[$i]}" ${TempLog} | awk -F '|' -v MSG="$msg" '{print $1 "\t" $2 "\t" $7 "\t" $8 "\t" MSG}'`\e[0m"
				fi

			done

			if [ ${i} -gt 0 ] && [ ${i} -ge ${#GetSensorName[@]} ] ; then
				echo -e "-----------------------------------------------------------------------------"
			fi
		done > .temp/${BaseName}_result_${t}.log
		sync;sync;sync
		
		if [ ${ErrorFlag} != 0 ] ; then
			echo
			# Check hardware
			val1='Sensor Name';  val2='Current';  val3='Minimum';  val4='Maximum';  val5='Result'
			echo | awk -v v1="$val1" -v v2=$val2 -v v3=$val3 -v v4=$val4 -v v5=$val5 '{print v1 "\t\t" v2 "\t\t" v3 "\t\t" v4 "\t\t" v5}'
			echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
			cat .temp/${BaseName}_result_${t}.log | grep -iw "FAIL"
			echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
			break
		fi
	done
	if [ ${ErrorFlag} == 0 ] ; then
		cat .temp/${BaseName}_result_$((t-1)).log
	fi
	echo

	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Check the sensor(s) on cards test"
		GenerateErrorCode
		exit 1
	else
		echoPass "Check the sensor(s) on cards test"
	fi

}

main ()
{
	ShowTitle "Check the Sensor(s) on Cards test"

	#Start ipmi service, or: service ipmi start
	modprobe ipmi_devintf
	if [ $? != "0" ]; then
		Process 1 "Load IPMI Driver"
		exit 4
	fi

	if [ "$TestMethod" == "Sensors" ];then
		HWM_Sensors
	elif [ "$TestMethod" == "raw_command" ]; then
		HWM_raw_command
	else
		Process 1 "Not avaluable TestMethod, should be Sensors or raw_comand"
		exit 3
	fi
}


#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare IgnoreItemsSwitch='enable'
declare XmlConfigFile ApVersion
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
			printf "%-s\n" "SerialTest,SensorTest"
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
