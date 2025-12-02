#!/bin/bash
#============================================================================================
#        File: dmiLink.sh
#    Function: DMI link width/speed/status verify
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
	   0 : DMI link test pass
	   1 : DMI link test fail
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
			<ProgramName>dmiLink</ProgramName>
			<ErrorCode></ErrorCode>
			
			<BusID>00:00.0</BusID>
			<Width>x16</Width>
			<!--Unit: GT/s-->
			<Speed>8.0</Speed>
			<!--1: avtive, 0: inactive-->
			<Status>1</Status>			
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
	StdWidth=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/Width" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
	StdSpeed=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/Speed" -n "${XmlConfigFile}" 2>/dev/null)
	StdStatus=$(xmlstarlet sel -t -v "//Link/TestCase[ProgramName=\"${BaseName}\"]/Status" -n "${XmlConfigFile}" 2>/dev/null)
	if [ $(echo "${BusID}" | grep -iEwc "[0-9a-f]{2}:[0-9a-f]{2}.[0-9a-f]" ) != 1 ] ; then
		Process 1 "Invalid bus ID in xml config file."
		let ErrorFlag++
	fi
	
	if [ $(echo "${StdStatus}" | grep -iwEc "[0-1]") != 1 ] ; then
		Process 1 "Invalid status setting in xml config file."
		let ErrorFlag++
	fi
	
	if [ $(echo "${StdWidth}" | grep -iwEc "x[0-9]{1,2}") != 1 ] ; then
		Process 1 "Invalid width setting in xml config file."
		let ErrorFlag++
	fi

	if [ $(echo "${StdSpeed}" | grep -iwEc "[0-9]{1,2}.[0-9]{1,2}") != 1 ] ; then
		Process 1 "Invalid speed setting in xml config file."
		let ErrorFlag++
	fi	
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0			
}

widthConvert()
{
	local Width="$1"
	local base=1
	local dmiWidth=0
	
	for((i=1;i<=6;i++))
	do
		local bit=$(echo "obase=2;ibase=16;${Width}/${base}%2" | bc)
		[ "${bit}" == '1' ] && dmiWidth="$i"
		base=$(echo "obase=16;ibase=16;${base}*2" | bc)
	done
	local LinkWidth=$(echo "2^$((dmiWidth-1))" 2>/dev/null | bc)
	echo "x${LinkWidth:-0}"
}

speedConvert()
{
	local Speed="$1"
	local base="$2"
	local dmiSpeed=0
	
	for((i=1;i<=3;i++))
	do
		local bit=$(echo "obase=2;ibase=16;${Speed}/${base}%2" | bc)
		[ "${bit}" == '1' ] && dmiSpeed="$i"
		base=$(echo "obase=16;ibase=16;${base}*2" | bc)
	done

	case "${dmiSpeed}" in
	'0')dmiSpeed="0.0";;
	'1')dmiSpeed='2.5';;
	'2')dmiSpeed='5.0';;
	'3')dmiSpeed='8.0';;
	'4')dmiSpeed="16.0";;
	*)dmiSpeed="0";;
	esac
	echo "${dmiSpeed:-0.0}"
}

statusConvert()
{
	case $1 in
	'0')printf "%s" "inavtive";;
	'1')printf "%s" " avtive";;
	esac
}

DumpDmiInfo()
{
	local Device=$(lspci -s ${BusID} | grep "[[:alpha:]]" | awk -F': ' '{print $NF}')
	if [ ${#Device} = 0 ] ; then
		Process 1 "No any device on \"${BusID}\" "
		let ErrorFlag++
		exit 1
	else
		Process 0 "Found device: ${Device}"
	fi
	
	rm -rf ${BaseName}_cap.log ${BaseName}_sts.log
	lspci -s ${BusID} -xxx | tr '[a-z]' '[A-Z]' > ${BaseName}_cap.log
	lspci -s ${BusID} -xxxx | tr '[a-z]' '[A-Z]' > ${BaseName}_sts.log
	sync;sync;sync	
}

DmiSpecVerify()
{
	DumpDmiInfo
	#width
	LnkCap=$(awk '/^90: /{print $15$14}' ${BaseName}_cap.log)
	LnkSts=$(awk '/^1B0: /{print $5$4}' ${BaseName}_sts.log)

	CapWidth=$(echo "obase=2;ibase=16;${LnkCap}" | bc | awk '{print substr($1, length($1)-9, 6)}')
	CapWidth=$(echo "obase=16;ibase=2;${CapWidth}" | bc)
	CapWidth=$(widthConvert "${CapWidth}")

	StsWidth=$(echo "obase=2;ibase=16;${LnkSts}" | bc | awk '{print substr($1, length($1)-9, 6)}')
	StsWidth=$(echo "obase=16;ibase=2;${StsWidth}" | bc)
	StsWidth=$(widthConvert "${StsWidth}")
	
	#speed
	LnkCap=$(awk '/^B0: /{print $14}' ${BaseName}_cap.log)
	CapSpeed=$(speedConvert "${LnkCap}" "2")
	StsSpeed=$(speedConvert "${LnkSts}" "1")

	#status
	LnkSts=$(echo "obase=2;ibase=16;${LnkSts}/2000%2" | bc)

	# DMI link width/speed/status verify
	# Itmes             Config         LnkCap         LnkSta         Result
	# -------------+--------------+--------------+--------------+-----------
	# Width              x16            x16            x16            PASS 
	# Speed(GT/s)        8.0            8.0            5.0            FAIL 
	# Status            avtive          ---          inavtive         FAIL 
	# -------------+--------------+--------------+--------------+-----------
	
	printf "%18s%s\n" "" "DMI link width/speed/status verify"
	printf "%-18s%-15s%-15s%-15s%-7s\n" " Itmes" "Config" "LnkCap" "LnkSta" "Result"
	echo "-------------+--------------+--------------+--------------+-----------"
	WidthTest="\e[32mPASS\e[0m"
	printf "%-19s%-15s" " Width" "${StdWidth}"
	if [ "${StdWidth}" != "${CapWidth}" ]; then
		printf "\e[31m%-15s\e[0m" "${CapWidth}"
		WidthTest="\e[31mFAIL\e[0m"
		let ErrorFlag++
	else
		printf "%-15s" "${CapWidth}"
	fi

	if [ "${StdWidth}" != "${StsWidth}" ]; then
		printf "\e[31m%-15s\e[0m" "${StsWidth}"
		WidthTest="\e[31mFAIL\e[0m"
		let ErrorFlag++
	else
		printf "%-15s" "${StsWidth}"
	fi
	
	echo -e "${WidthTest}"
	
	SpeedTest="\e[32mPASS\e[0m"
	printf "%-19s%-15s" " Speed(GT/s)" "${StdSpeed}"
	if [ "${StdSpeed}" != "${CapSpeed}" ]; then
		printf "\e[31m%-15s\e[0m" "${CapSpeed}"
		SpeedTest="\e[31mFAIL\e[0m"
		let ErrorFlag++
	else
		printf "%-15s" "${CapSpeed}"
	fi

	if [ "${StdSpeed}" != "${StsSpeed}" ]; then
		printf "\e[31m%-15s\e[0m" "${StsSpeed}"
		SpeedTest="\e[31mFAIL\e[0m"
		let ErrorFlag++
	else
		printf "%-15s" "${StsSpeed}"
	fi
	
	echo -e "${SpeedTest}"	
	
	StatusTest="\e[32mPASS\e[0m"
	printf "%-17s%-17s%-13s" " Status" "`statusConvert ${StdStatus}`" "---"

	if [ "${StdStatus}" != "${LnkSts}" ]; then
		printf "\e[31m%-17s\e[0m" "`statusConvert ${LnkSts}`"
		StatusTest="\e[31mFAIL\e[0m"
		let ErrorFlag++
	else
		printf "%-17s" "`statusConvert ${LnkSts}`"
	fi
	
	echo -e "${StatusTest}"		
	echo "-------------+--------------+--------------+--------------+-----------"
	echo
	
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "DMI link width/speed/status test"
	else
		echo "LnkCap和Config不一致的，則可能錯料了！"
		echo "LnkSta和LnkCap不一致，可能是製程或物料有問題！"
		echoFail "DMI link width/speed/status test"
		GenerateErrorCode
	fi	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile BusID StdWidth StdSpeed StdStatus
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

DmiSpecVerify
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
