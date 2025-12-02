#!/bin/bash
#============================================================================================
#        File: qpiLink.sh
#    Function: QPI link width/speed verify
#     Version: 1.0.0
#      Author: 
#     Created: 2020-08-24
#     Updated: 
#  Department: Application engineering course
#        Note: 
# Environment: Linux/CentOS
#============================================================================================
#----Define sub function---------------------------------------------------------------------
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet lspci)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			uuid)printf "%10s%s\n" "" "Please install: uuid-1.6.2-42.el8.x86_64.rpm";;
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
`basename $0` [-x lConfig.xml] [-D]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D

	-D : Dump the sample xml config file	
	-x : config file,format as: *.xml

		
	return code:
	   0 : QPI link test pass
	   1 : QPI link test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Link>
		<TestCase>
			<ProgramName>qpiLink</ProgramName>
			<ErrorCode></ErrorCode>
			
			<BusID>00:05.0</BusID>
			<!--enable/disable-->
			<CheckRxTx>enable</CheckRxTx>
			<QpiDevice>08 09</QpiDevice>
			<Status>6</Status>
			<!--Unit: GT/s-->
			<Speed>8.0</Speed>
			<RX>FFFFF</RX>			
			<TX>FFFFF</TX>			
		</TestCase>
	</Link>
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

	# Get the information from the config file(*.xml)
	BusID=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/BusID" -n "${XmlConfigFile}" 2>/dev/null)
	CheckRxTx=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/CheckRxTx" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
	QpiDevice=($(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/QpiDevice" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]'))
	StdStatus=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/Status" -n "${XmlConfigFile}" 2>/dev/null)
	StdSpeed=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/Speed" -n "${XmlConfigFile}" 2>/dev/null)
	RX=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/RX" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]' )
	TX=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/TX" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]' )
	if [ $(echo "${BusID}" | grep -iEwc "[0-9a-f]{2}:[0-9a-f]{2}.[0-9a-f]" ) != 1 ] ; then
		Process 1 "Invalid bus ID in xml config file."
		let ErrorFlag++
	fi
	
	if [ $(echo "${StdStatus}" | grep -iwEc "[0-9a-f]{1,2}") != 1 ] ; then
		Process 1 "Invalid status setting in xml config file."
		let ErrorFlag++
	fi

	if [ $(echo "${StdSpeed}" | grep -iwEc "[0-9]{1,2}.[0-9]{1,2}") != 1 ] ; then
		Process 1 "Invalid speed setting in xml config file."
		let ErrorFlag++
	fi	
	
	if [ ${#RX} == 0 -o ${#TX} == 0 ] ; then
		Process 1 "Invalid TX/RX setting in xml config file."
		let ErrorFlag++		
	fi
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0			
}

DumpQpiInfo()
{
	local Device=$(lspci -s "${BusID}" | grep "[[:alpha:]]" | awk -F': ' '{print $NF}')
	if [ ${#Device} == 0 ] ; then
		Process 1 "No any devie found at ${BusID} ... "
		let ErrorFlag++
		exit 1
	fi
	
	# Set CPU BUS
	cpuBus1=$(lspci -s "${BusID}" -xxxx | awk '/^100: /{print toupper($11)}')
	if [ ${#cpuBus1} == 0 ]; then
		Process 1 "${BusID} is not the CPU's QPI BUS ID... "
		let ErrorFlag++
		exit 1
	fi
	
	cpuBus2=$(echo "obase=16;ibase=16;${cpuBus1}+80" | bc)
	cpuBus=($(printf "%s\n" "${cpuBus1} ${cpuBus2}" | tr '[A-Z]' '[a-z]'))
	
	local Cpu2nd=$(lspci -s "${cpuBus[1]}:${QpiDevice[0]}.0" | grep "[[:alpha:]]" | awk -F': ' '{print $NF}')
	if [ ${#Cpu2nd} == 0 ] ; then
		Process 1 "No found the 2nd CPU ... "
		let ErrorFlag++
		exit 1
	else
		Process 0 "Found the 2nd CPU: ${Cpu2nd}"
	fi
	
	# Get lspci info
	rm -rf "${cpuBus[0]}_*.log" "${cpuBus[1]}_*.log"
	for((j=0;j<${#QpiDevice[@]};j++))
	do
		lspci -s "${cpuBus[0]}:${QpiDevice[$j]}.0" -xxx | tr '[a-z]' '[A-Z]' > "${cpuBus[0]}_${QpiDevice[$j]}.0.log"
		lspci -s "${cpuBus[1]}:${QpiDevice[$j]}.0" -xxx | tr '[a-z]' '[A-Z]' > "${cpuBus[1]}_${QpiDevice[$j]}.0.log"

		if [ "${CheckRxTx}" == "enable" ]; then
			lspci -s "${cpuBus[0]}:${QpiDevice[$j]}.3" -xxxx | tr '[a-z]' '[A-Z]' > "${cpuBus[0]}_${QpiDevice[$j]}.3.log"
			lspci -s "${cpuBus[1]}:${QpiDevice[$j]}.3" -xxxx | tr '[a-z]' '[A-Z]' > "${cpuBus[1]}_${QpiDevice[$j]}.3.log"
		fi
	done	
	sync;sync;sync	
}

QpiSpecVerify()
{
	DumpQpiInfo
	
	# CPU QPI TEST
	for((i=0;i<"${#cpuBus[@]}";i++))
	do
		for((j=0;j<"${#QpiDevice[@]}";j++))
		do
			error=0
			qpiStatus=$(awk '/^40: /{print substr($13, length($13))}' "${cpuBus[$i]}_${QpiDevice[$j]}.0.log")
			if [ "${qpiStatus}" == "${StdStatus}" ]; then
				msg='UP...'
			else
				let error++
				msg='DOWN...'
			fi
		
			Process ${error} "CPU${i} QPI port ${j} status is ${msg}" || let ErrorFlag++
			
			if [ "${CheckRxTx}" == 'enable' ]; then
				if [ -s "${cpuBus[$i]}_${QpiDevice[$j]}.3.log" ]; then
					# Check QPI RX
					qpiRx=$(awk '/^130: /{printf $10$11 substr($12, length($12))}' "${cpuBus[$i]}_${QpiDevice[$j]}.3.log")
					if [ "${qpiRx}" == "${RX}" ]; then
						msg='PASS'
						error=0
					else
						msg='FAIL'
						error='1'
					fi
					Process ${error} "Verify CPU${i} QPI port ${j} RX ${msg}" || let ErrorFlag++

					# Check QPI TX
					qpiTx=$(awk '/^130: /{printf $6$7 substr($8, length($8))}' "${cpuBus[$i]}_${QpiDevice[$j]}.3.log")
					if [ "${qpiTx}" == "${TX}" ]; then
						msg='PASS'
						error=0
					else
						msg='FAIL'
						error='1'
					fi
					Process ${error} "Verify CPU${i} QPI port ${j} TX ${msg}" || let ErrorFlag++
				else
					Process 1 "Verify CPU ${i} QPI port ${j} RX/TX FAIL"
					let ErrorFlag++
				fi
				echo ""
			fi		
		done
	done
	
	# QPI link Speed TEST
	for((i=0;i<${#cpuBus[@]};i++))
	do
		# Check QPI Capability Register
		CFCLK=$(lspci -s "${cpuBus[$i]}:1e.3" -xxx | awk '/^80: /{print toupper($17)}')
		if [ "${CFCLK}" == "" ]; then
			Process 1 "No found CPU${i} QPI link speed ..."
			let ErrorFlag++
			exit 1
		fi

		base=4
		for((j=1;j<=4;j++))
		do
			bit=$(echo "obase=2;ibase=16;${CFCLK}/${base}%2" | bc)
			if [ "${bit}" == '0' ]; then
				rate=$(echo "scale=1;(${j}+8)*8/10" | bc)
				StdStatus="${rate}"
			fi
			base=$(echo "obase=16;ibase=16;${base}*2" | bc)
		done

		# Check QPI link speed status
		if [ -f "${cpuBus[$i]}_${QpiDevice[0]}.0.log" ]; then
			Speed=$(awk '/^D0: /{print $6}' "${cpuBus[$i]}_${QpiDevice[0]}.0.log")
		else
			Speed=$(lspci -s "${cpuBus[$i]}:${QpiDevice[0]}.0" -xxx | awk '/^d0: /{print toupper($6)}')
		fi
		qpiSpeed=$(echo "obase=2;ibase=16;${Speed}" | bc | awk '{print substr($1, length($1)-2, 3)}')
		qpiSpeed=$(echo "obase=10;ibase=2;${qpiSpeed}" | bc)

		case "${qpiSpeed}" in
		'2')qpiSpeed='5.6';;
		'3')qpiSpeed='6.4';;
		'4')qpiSpeed='7.2';;
		'5')qpiSpeed='8.0';;
		'6')qpiSpeed='8.8';;
		'7')qpiSpeed='9.6';;
		*)qpiSpeed='0';;
		esac

		# Check QPI speed
		if [ "${qpiSpeed}" == "${StdSpeed}" ]; then
			error='0'
		else
			error='1'
		fi
		process "${error}" "CPU ${i} QPI link speed shoud be ${StdStatus}GT/s, now link speed is: ${qpiSpeed}GT/s"  || let ErrorFlag++
	done	
	
	if [ ${ErrorFlag} == 0 ] ; then
		rm -rf "${cpuBus[0]}_*.log" "${cpuBus[1]}_*.log"
		echoPass "QPI link width/speed test"
	else
		echoFail "QPI link width/speed test"
		GenerateErrorCode
	fi	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
# Set Speed Default, unit: GT/s
declare StdStatus='6.4'
declare XmlConfigFile
declare cpuBus BusID CheckRxTx QpiDevice StdSpeed RX TX 
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts Dx: argv
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

QpiSpecVerify
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
