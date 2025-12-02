#!/bin/bash
#FileName : hwmon.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.2"
	local CreatedDate="2018-06-13"
	local UpdatedDate="2020-11-18"
	local Description="Hardware Monitor test"
	
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
	#printf "%16s%-s\n" "" "2020-10-20,add header in config file"
	#printf "%16s%-s\n" "" "2020-11-18,case 1 需要連續測試3次OK才算測試PASS"
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
	if [ $# == 0 ] ; then
	ExtCmmds=(xmlstarlet)
	else
	ExtCmmds=(xmlstarlet ipmitool)
	fi
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
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml	
	-V : Display version number and exit(1)
	
	return code:
		0 : Hard Ware Monitor test pass
		1 : Hard Ware Monitor test fail
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
			<ErrorCode>CXSAF|Hardware Monitor test fail</ErrorCode>				
			<!--hwmon.sh： HardWareMonitor 測試-->
			<!-- 支持SuperIO/AST1300/AST1400,ipmitool(AST2300/AST2400/AST2500) -->
			<!-- TestTool is the tool read the Fan speed ,temperature,and voltage from registers -->
			<!--測試工具從如下選項中選擇TestTool=AST1300FW/AST1400FW/HWM/ipmitool(internal command) and so on -->
			<TestTool>ipmitool</TestTool>
			
			<!--忽略的測試選項清單-->
			<IgnoreItem>P3V3</IgnoreItem>
			<IgnoreItem>PVCCP</IgnoreItem>
			
			<!--TestTool選擇ipmitool的時候如下配置內容被忽略-->
			<!-- # DO NOT MODIFY THIS HEADER -->
			<!-- # First line: chip_name, address -->
			<!-- # Others: sensor_name, pin, par1, par2, min, max, multiplier -->
			<ChipsetAddress>AST1400, 0x4E</ChipsetAddress>
			<TestItem>CPU_TEMP, J18, 0, 0, 20, 100, 0</TestItem>
			<TestItem>SYS_TEMP, J18, 0, 0, 20, 100, 0</TestItem>
			<TestItem>SYS_FAN1, V6, 0, 0, 100, 10000, 0</TestItem>
			<TestItem>SYS_FAN2, Y5, 0, 0, 100, 10000, 0</TestItem>
			<TestItem>P5V_STBY, L5, 28, 0, 4.75, 5.25, 0</TestItem>
			<TestItem>P3V3_STBY, L4, 20, 0, 3.135, 3.465, 0</TestItem>
			<TestItem>P5V_ATX, L3, 28, 0, 4.75, 5.25, 0</TestItem>
			<TestItem>P3V3, L2, 20, 0, 3.135, 3.465, 0</TestItem>
			<TestItem>P12V, L1, 66, 0, 11.4, 12.6, 0</TestItem>
			<TestItem>VBAT, M5, 30, 0, 2, 3.6, 0</TestItem>
			<TestItem>PVCCP,M4, 10, 0, 0.70, 1.0, 0</TestItem>
			<TestItem>P1V0, M3, 10, 0, 0.95, 1.05, 0</TestItem>
			<TestItem>PVNN, M2, 10, 0, 0.95, 1.05, 0</TestItem>
			<TestItem>P1V1, M1, 10, 0, 1.045, 1.155, 0</TestItem>
			<TestItem>PVDDRA, N5, 10, 0, 1.425, 1.575, 0</TestItem>
			<TestItem>PVTT_A, N4, 10, 0, 0.675, 0.825, 0</TestItem>
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
	
	# Get the information from the config file(*.xml)
	ReadSensorTool=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/TestTool" -n "${XmlConfigFile}" 2>/dev/null)
	IgnoreItems=($(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/IgnoreItem" -n "${XmlConfigFile}" 2>/dev/null))

	if [ ${#ReadSensorTool} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi

	if [ $(echo "${ReadSensorTool}" | grep -ic 'ipmitool') == 0 ] ; then
		HWMConfigFile=${BaseName}.ini
		rm -rf ${HWMConfigFile} 2>/dev/null
		cat <<-HEADER > ${HWMConfigFile}
		# DO NOT MODIFY THIS HEADER
		# First line: chip_name, address
		# Others: sensor_name, pin, par1, par2, min, max, multiplier
		HEADER
		
		xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/ChipsetAddress" -n "${XmlConfigFile}" >> ${HWMConfigFile} 2>/dev/null
		xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/TestItem" -n "${XmlConfigFile}" >> ${HWMConfigFile} 2>/dev/null
		sync;sync;sync
		
		if [ ! -s "${HWMConfigFile}" ] ; then
			Process 1 "No such file or 0 KB size of file: ${HWMConfigFile}"
			exit 2
		else
			if [ $(grep -cv '^$' ${HWMConfigFile}) -lt 2 ] ; then
				# Do not need any config file,as case #3:  ./HWM 3
				HWMConfigFile=''
			fi
		fi
	fi
	return 0
}

main ()
{
	ShowTitle "Linux OS Hard Ware Monitor test" 
	[ ! -d  .temp ] && mkdir -p .temp

	if [ $(echo ${ReadSensorTool} | grep -ic 'ipmitool') == 0 ] ; then
		ChkExternalCommands || exit 2
	else
		cp -rf ${ReadSensorTool} HWMON 2>/dev/null
		chmod 777 HWMON 2>/dev/null
	fi

	# IgnoreItems="P3V3\|P5V"
	SoleIgnoreItems=($(echo ${IgnoreItems[@]} | tr ' ' '\n' | sort -u ))
	SoleIgnoreItems=$(echo ${SoleIgnoreItems[@]} | sed 's/ /\\|/g')
	SoleIgnoreItems=${SoleIgnoreItems:-"^$"}

	if [ "${#HWMConfigFile}" -gt 2 ] ; then
		if [ ! -s "${HWMConfigFile}" ] ; then
			Process 1 "No such file or 0 KB size of file: ${HWMConfigFile}"
			exit 2
		fi
		
		rm -rf HWMON.conf
		cat "${HWMConfigFile}" | grep -iv "$SoleIgnoreItems" >  HWMON.conf  2>/dev/null
	fi

	# For case 1  AST2300/AST2400/AST2500: ipmitool sensor 
	if [ $(echo "${ReadSensorTool}" | grep -ic 'ipmitool') == 1 ] ; then
		# Define the Major Project
		MajorProject=(Voltages Current Temperatures FANs)
		MajorProjectUnit=(Volts Amps degrees RPM)

		#Start ipmi service, or: service ipmi start
		modprobe ipmi_devintf
		if [ $? != "0" ]; then
			Process 1 "Load IPMI Driver"
			exit 4
		fi
		
		local TestCount=(1st 2nd 3rd 4th 5th)
		ipmitool mc info 2>&1 >/dev/null
		if [ $? != 0 ];then
			Process 1 "IPMI Driver not work"
			exit 4
		fi
		
		# 2020/11/17 新增測試3次OK才算測試PASS
		rm -rf .temp/hwm_*.log .temp/${BaseName}_*.log  2>/dev/null
		for((t=1;t<=1;t++))
		do
			printf "%s\r" "The ${TestCount[t-1]} testing, now reading the sensors, please wait ..."
			ipmitool sensor 2>/dev/null > .temp/${BaseName}_${t}.log
			sync;sync;sync
			
			# hardware monitor Test 
			for((h=0;h<${#MajorProjectUnit[@]};h++))
			do
				if [ ${h} == 0 ] ; then
					echo
					# Check hardware
					val1='ItemName';  val2='Current';  val3='Minimum';  val4='Maximum';  val5='Result'
					echo | awk -v v1=$val1 -v v2=$val2 -v v3=$val3 -v v4=$val4 -v v5=$val5 '{print v1 "\t\t" v2 "\t\t" v3 "\t\t" v4 "\t\t" v5}'
					echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
				fi
				
				TempLog=.temp/hwm_${MajorProjectUnit[$h]}.log
				rm -rf ${TempLog} >/dev/null 2>&1
				# Hardware monitor test
				#ipmitool sensor 2>/dev/null | grep -iw "${MajorProjectUnit[$h]}" | grep -vw "${SoleIgnoreItems}" >  ${TempLog}
				cat .temp/${BaseName}_${t}.log 2>/dev/null | grep -iw "${MajorProjectUnit[$h]}" | grep -vw "${SoleIgnoreItems}" > ${TempLog}
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
				val1='ItemName';  val2='Current';  val3='Minimum';  val4='Maximum';  val5='Result'
				echo | awk -v v1=$val1 -v v2=$val2 -v v3=$val3 -v v4=$val4 -v v5=$val5 '{print v1 "\t\t" v2 "\t\t" v3 "\t\t" v4 "\t\t" v5}'
				echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
				cat .temp/${BaseName}_result_${t}.log | grep -iw "FAIL"
				echo -e "\e[1;37m-----------------------------------------------------------------------------\e[0m"
				break
			fi
		done
		if [ ${ErrorFlag} == 0 ] ; then
			cat .temp/${BaseName}_result_$((t-1)).log
		fi
	fi

	# For case 2  AST1300/AST1400,or some Super I/O: ./ReadSensorTool S1581.conf [ n ]
	if [ $(echo ${ReadSensorTool} | grep -ic 'ipmitool') == 0 ] && [ ${#HWMConfigFile} -ge 2 ] ; then
		TempLog=.temp/hwm_error.log
		rm -rf ${TempLog} >/dev/null 2>&1
		
		./HWMON HWMON.conf 3  | tr -d '!' | sed 's/fail/FAIL\n/gi' | sed 's/pass/PASS\n/gi' | while read LINE
		do
			flag=3	
			echo $LINE | grep -iq "Fail\|Usage" 
				if [ $? == 0 ] ; then
					flag=1
					let error=${error}+1
					echo "${error}" >> ${TempLog}
					sync;sync;sync
				fi
			 
			case $flag in  
			 1)
				echo -e "\033[31m $LINE \033[0m" # show red color
				let error++
			 ;;
		  
			 *)
				echo -e " $LINE "  # show white color
			 ;;
		 
			 esac
			 sleep 0.03
		done 
		ErrorFlag=$(cat ${TempLog} 2>/dev/null| grep -c "[1-9]")
	fi


	# For case 3 AST1300/AST1400,or some Super I/O: ./ReadSensorTool [ n ]
	if [ $(echo ${ReadSensorTool} | grep -ic 'ipmitool') == 0 ] && [ ${#HWMConfigFile} -lt 2 ] ; then
		IgnoreItemsSwitch='disable'
		TempLog=.temp/hwm_error.log
		rm -rf ${TempLog} >/dev/null 2>&1
		./HWMON 3  | tr -d '!' | sed 's/fail/FAIL\n/gi' | sed 's/pass/PASS\n/gi' | while read LINE
		do
			flag=3	
			echo $LINE | grep -iq "Fail\|Usage" 
				if [ $? == 0 ] ; then
					flag=1
					echo error >> ${TempLog}
					sync;sync;sync
				fi
			 
			case $flag in  
			 1)
				echo -e "\033[31m $LINE \033[0m" # show red color
			 ;;
		  
			 *)
				echo -e " $LINE "  # show white color
			 ;;
		 
			 esac
			 sleep 0.03
		done 
		ErrorFlag=$(cat ${TempLog} 2>/dev/null| grep -ic "[1-9A-Za-z]")
	fi

	if [ ${#IgnoreItems[@]} != 0 ] && [ $IgnoreItemsSwitch = 'enable' ] ; then
		echo -e "\e[1m The item(s) below has been skipped\e[0m"	
		echo "----------------------------------------------------------------------"
		for ((p=0;p<${#IgnoreItems[@]};p++))
		do
			echo "${IgnoreItems[$p]} " 
		done |  cat -n  | while read LINE
		do
			LINE=$(echo "$LINE                         " | cut -c 1-25) 
			let ID=$(echo $LINE | awk '{print $1}')%3
			if [ $ID == 0 ]; then
				echo
				echo 'enable' >.temp/Enter.log
			else
				echo -ne "$LINE\t\t"
				echo 'disable' >.temp/Enter.log
			fi
			sync;sync;sync
		done
		[ $(grep -ic 'disable' .temp/Enter.log 2>/dev/null) -gt 0 ] && echo
		echo "----------------------------------------------------------------------"
	fi
	echo
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Hardware Monitor test"
		GenerateErrorCode
		exit 1
	else
		echoPass "Hardware Monitor test"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare IgnoreItemsSwitch='enable'
declare XmlConfigFile HWMConfigFile ReadSensorTool IgnoreItems ApVersion
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
			printf "%-s\n" "SerialTest,HardwareMonitorTest"
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
