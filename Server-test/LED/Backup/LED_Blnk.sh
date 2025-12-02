#!/bin/bash
#============================================================================================
#        File: LED_Blnk.sh
#    Function: GR & B LED function test for S258K
#     Version: 1.0.0
#      Author: Cody,qiutiqin@msi.com
#     Created: 2020-06-03
#     Updated: 
#  Department: Application engineering course
# 		 Note: 
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
	local ErrorCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	   0 : S258K LED function test pass
	   1 : S258K LED function test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Test fail	
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<LED>
		<TestCase>
			<ProgramName>LED_Blnk</ProgramName>
			<ErrorCode>NXRD4|LED fail</ErrorCode>
		
			<Location>S258K</Location>
		</TestCase>
	</LED>
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
	Location=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
	
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	
	return 0			
}

GetControl ()
{
	ipmitool i2c bus=0 0xc0 0 0x3c 0xff >/dev/null
	Process $? "Get control rights of S258K LEDs(8Pcs on Chip1) ..." || let ErrorFlag++
	
	ipmitool i2c bus=0 0xc2 0 0x3c 0x0f >/dev/null
	Process $? "Get control rights of S258K LEDs(4Pcs on Chip2) ..." || let ErrorFlag++
	
	if [ ${ErrorFlag} != 0 ] ; then
		return 1
	else
		return 0
	fi	
}

InitLed ()
{
	local Status="$1"
	local Behavior=""
	case ${Status} in
		R|B) Behavior="0x46";;
		G) Behavior="0x40";;
		*) BehaviorSet=(0x40 0x46)
	esac
	
	if [ ${Status} == "ALL" ] ; then
		for((b=0;b<${#BehaviorSet[@]};b++))
		do
			ipmitool i2c bus=0 0xc0 0 ${BehaviorSet[$b]} 0x00 >/dev/null
			ipmitool i2c bus=0 0xc2 0 ${BehaviorSet[$b]} 0x00 >/dev/null
		done
	else
		ipmitool i2c bus=0 0xc0 0 ${Behavior} 0x00 >/dev/null
		Process $? "Initialized S258K LEDs(8Pcs on Chip1) ..." || let ErrorFlag++
		
		ipmitool i2c bus=0 0xc2 0 ${Behavior} 0x00 >/dev/null
		Process $? "Initialized S258K LEDs(4Pcs on Chip2) ..." || let ErrorFlag++
	fi
	if [ ${ErrorFlag} != 0 ] ; then
		return 1
	else
		return 0
	fi
}

BlinkingLed()
{
	local Status="$1"
	local Behavior=""
	case ${Status} in
		R|B) Behavior="0x46";;
		G) Behavior="0x40";;
	esac
	ipmitool i2c bus=0 0xc0 0 ${Behavior} 0xff >/dev/null || let ErrorFlag++
    ipmitool i2c bus=0 0xc2 0 ${Behavior} 0x0f >/dev/null || let ErrorFlag++
	if [ ${ErrorFlag} != 0 ] ; then
		return 1
	else
		return 0
	fi

}

FunctionTest()
{
	local Color="$1"
	case ${Color} in 
		R|B) 
			StdAnswer=1
			LedColor='紅色'
			;;
		G) 
			StdAnswer=2
			LedColor='綠色'
			;;
		esac
	
	LedColorSet=('紅色' '綠色')
	GetControl

	InitLed ALL

	BlinkingLed ${Color} 
	if [ $? != 0 ] ; then
		Process 1 "Fail to turn on the LEDs ..."
		exit 1
	else
		echo	
		printf "\e[1;31m%10s\e[0m%60s\n" "< 紅色 >" ".........................................................[1]"
		printf "\e[1;32m%10s\e[0m%60s\n" "< 綠色 >" ".........................................................[2]"
		printf "%s" "請輸入正在閃爍的LED的顏色代碼: "
		numlockx on >/dev/null 2>&1		
		read -n1 -t20 OpReply
		echo
		InitLed ALL
		echo "${OpReply:-'9'}" | grep -iwq "${StdAnswer}"
		if [ $? != 0 ] ; then
			Process 1 "正確的LED閃爍的顏色應該是: ${LedColor}, 您輸入的顏色是: ${LedColorSet[OpReply-1]:-'TimeOut'} ..."
			return 1
		else
			Process 0 "正確的LED閃爍的顏色應該是: ${LedColor}, 您輸入的顏色是: ${LedColorSet[OpReply-1]} ..."
			return 0
		fi
	fi
}

main()
{
	
	<<-Msg
	-------------------------------------------------
	Scanning for device at BusID: 0x01 Address: 0xc0
	Valid device found at address 0xc0
	Found MG9100 at I2C address 0xc0 on Bus 0x01

	Chip Information:
	Chip ID: 9100 
	FWID0 Reg 0x60:0x00 
	FWID1 Reg 0x61:0x00 
	FWID2 Reg 0x62:0x2e 
	RevID Reg 0x65:0x04 
	VPP/SHP Host:	Intel

	MG9100 BP Type Configuration:	4-drive
		Additional Chip Info:
		Configuration      (Reg 0x30):0x0c
		SGPIO Config       (Reg 0x35):0x44
		Slots Used         (Reg 0x36):0xff
		Slots Mated        (Reg 0x38):0xff
		Activity           (Reg 0x40):0x00
		Locate             (Reg 0x42):0x00
		Fail               (Reg 0x44):0x00
		Rebuild            (Reg 0x46):0x00
		Supported Drives   (Reg 0x34):0x08

	-------------------------------------------------
	Scanning for device at BusID: 0x01 Address: 0xc2
	Valid device found at address 0xc2
	Found MG9100 at I2C address 0xc2 on Bus 0x01

	Chip Information:
	Chip ID: 9100 
	FWID0 Reg 0x60:0x00 
	FWID1 Reg 0x61:0x00 
	FWID2 Reg 0x62:0x2e 
	RevID Reg 0x65:0x04 
	VPP/SHP Host:	Intel

	MG9100 BP Type Configuration:	4-drive
		Additional Chip Info:
		Configuration      (Reg 0x30):0x0d
		SGPIO Config       (Reg 0x35):0x04
		Slots Used         (Reg 0x36):0x0f
		Slots Mated        (Reg 0x38):0x0f
		Activity           (Reg 0x40):0x00
		Locate             (Reg 0x42):0x00
		Fail               (Reg 0x44):0x00
		Rebuild            (Reg 0x46):0x00
		Supported Drives   (Reg 0x34):0x04
	Msg
	printf "%s\n" "**********************************************************************"
	printf "%s\n" "      MS-S258K LED 功能測試程式，請根據提示輸入正確的LED顏色代號      "
	printf "%s\n" "**********************************************************************"	
	echo
	
	local SubErrorFlag=0
	while :
	do
		if [ ${SubErrorFlag} -ge 3 ] ; then
			Process 1 "Fail too many times ..."
			printf "%10s%60s\n" "" "Exit ..."
			let ErrorFlag++
			InitLed ALL
			exit 1
		fi
		
		RandomNum=$(($RANDOM%2))
		if [ ${RandomNum} == 0 ] ; then
			ColorSet=(Red Green Red)
		else
			ColorSet=(Green Red Green)
		fi
		
		local Index=($(seq 1 ${#ColorSet[@]} | awk 'BEGIN{srand();ORS=" "} {b[rand()]=$0} END{for(x in b) print b[x]}'))
				
		for ((c=0;c<${#Index[@]};c++))
		do
			let C=${Index[$c]}-1
			FunctionTest ${ColorSet[$C]:0:1}
			if [ $? != 0 ] ; then
				echo "重新開始測試 ..."
				let SubErrorFlag++
				continue 2
			else
				SubErrorFlag=0
			fi
			printf "\n\n"
		done
		break
	done
	
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "Check the status of LEDs on ${Location}"
	else
		echoFail "Check the status of LEDs on ${Location}"
		GenerateErrorCode
	fi

}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile 
declare StdAnswer ColorSet
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :Dx: argv
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

main
	
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
