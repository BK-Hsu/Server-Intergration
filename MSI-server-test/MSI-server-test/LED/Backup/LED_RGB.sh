#!/bin/bash
#============================================================================================
#        File: LED_RGB.sh
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
			<ProgramName>LED_RGB</ProgramName>
			<ErrorCode>NXRD4|LED fail</ErrorCode>
			
			<!--檢查那種顏色的LED, 請填寫: Red/Green/Blue, 同時填寫請使用空格隔開 -->
			<LedColor>Red</LedColor>
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
	ColorSet=($(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/LedColor" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]'))
	
	if [ ${#Location} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	
	for ((i=0;i<${#ColorSet[@]};i++))
	do
		echo ${ColorSet[$i]} | grep -wq "RED\|GREEN\|BLUE"
		if [ $? != 0 ] ; then
			Process 1 "Error LedColor setting: ${ColorSet[$i]} ..."
			let ErrorFlag++
		fi
	done
	
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0			
}

RandomLightOnOffCode ()
{
	local Color="$1"
	#前8個LED 點亮
	while :
	do
		# RandomNum=0~255
		RandomNum=$(($RANDOM%256))
		if [ ${RandomNum} -lt 15 ] ; then
			continue
		fi
		
		LED8_LightOnBin=$(printf "obase=2;ibase=16; %X\n" "${RandomNum}" | bc )
		LED8_LightOnBin=$(printf "%08d" "${LED8_LightOnBin}")
		
		LED8_1Cnt=$(echo "${LED8_LightOnBin}" | grep -o "1" | grep -c "1" )
		if [ ${LED8_1Cnt} -ge 4 ] && [ ${LED8_1Cnt} -le 6 ]; then
			LED8_LightOnHex=$(printf "obase=16;ibase=2; %s\n" "${LED8_LightOnBin}" | bc )
			LED8_LightOnHex=$(printf "%02X" "0x${LED8_LightOnHex}" )
			break
		else
			continue
		fi
	done
	
	#後4個LED 點亮
	while :
	do
		# RandomNum=0~15
		RandomNum=$(($RANDOM%16))
		if [ ${RandomNum} == 0 ] ; then
			continue
		fi
		
		LED4_LightOnBin=$(printf "obase=2;ibase=16; %X\n" "${RandomNum}" | bc )
		LED4_LightOnBin=$(printf "%04d" "${LED4_LightOnBin}")
		
		LED4_1Cnt=$(echo "${LED4_LightOnBin}" | grep -o "1" | grep -c "1")
		if [ ${LED4_1Cnt} -ge 1 ] && [ ${LED4_1Cnt} -le 3 ]; then
			LED4_LightOnHex=$(printf "obase=16;ibase=2; %s\n" "${LED4_LightOnBin}" | bc )
			LED4_LightOnHex=$(printf "%02X" "0x${LED4_LightOnHex}" )
			break
		else
			continue
		fi
	done
	
	#藍燈取反, 0 代表藍燈開啟
	if [ ${Color} == "B" ] ; then
		LED8_LightOnHex=$(printf "obase=16;ibase=16; %s\n" "FF-${LED8_LightOnHex}" | bc )
		LED4_LightOnHex=$(printf "obase=16;ibase=16; %s\n" "F-${LED4_LightOnHex}" | bc )
		LED8_LightOnHex=$(printf "%02X" "0x${LED8_LightOnHex}" )
		LED4_LightOnHex=$(printf "%02X" "0x${LED4_LightOnHex}" )
	
	fi
	
	#GroupA_StdAnswer=5~9
	let GroupA_StdAnswer=${LED8_1Cnt}+${LED4_1Cnt}
	
	#將原來熄滅的LED 點亮
	Reverse_LED12_LightOnHex=$(printf "%03s" "${LED4_LightOnHex}${LED8_LightOnHex}" )
	Reverse_LED12_LightOnBin=$(echo "obase=2;ibase=16; FFF-${Reverse_LED12_LightOnHex}" | bc )
	Reverse_LED12_LightOnBin=$(printf "%012d" "${Reverse_LED12_LightOnBin}" )

	
	#加入干擾
	# TurnOnLedCnt=9-(12-${GroupA_StdAnswer})
	let MaxTurnOnLedCnt=${GroupA_StdAnswer}-3
	if [ ${Color} == "B" ] ; then
		LedsOff=$(echo ${Reverse_LED12_LightOnBin} | grep -o "1" | tr -d "\n")
		AllOne_Hex=$(echo ${LedsOff})	
	else
		LedsOff=$(echo ${Reverse_LED12_LightOnBin} | grep -o "0" | tr -d "\n")
		AllOne_Hex=$(echo ${LedsOff} | sed "s/0/1/g" )	
	fi
	
	AllOne_Dec=$(echo "obase=10;ibase=2; ${AllOne_Hex}" | bc)
	while :
	do
		RandomNum=$(($RANDOM%${AllOne_Dec}))
		LedsOff_RandomOn=$(printf "obase=2;ibase=10; %X\n" "${RandomNum}" | bc )
		LedsOff_RandomOn=$(printf "%0${#LedsOff}d" "${LedsOff_RandomOn}")
		if [ ${Color} == "B" ] ; then
			LedsOff_RandomOn_1Cnt=$(echo "${LedsOff_RandomOn}" | grep -o "0" | grep -c "0" )
		else
			LedsOff_RandomOn_1Cnt=$(echo "${LedsOff_RandomOn}" | grep -o "1" | grep -c "1" )
		fi
		
		if [ ${LedsOff_RandomOn_1Cnt} -ge 2 ] && [ ${LedsOff_RandomOn_1Cnt} -le ${MaxTurnOnLedCnt} ]; then
			break
		else
			continue
		fi
	done
	
	let GroupB_StdAnswer=12-${GroupA_StdAnswer}+${LedsOff_RandomOn_1Cnt}
	
	R=0
	for((i=0;i<12;i++))
	do
		bit[$i]=${Reverse_LED12_LightOnBin:$i:1}
		if [ "${Color}" == "B" ] ; then
			if [ ${bit[$i]} == 0 ] ; then
				continue 
			else
				bit[$i]=${LedsOff_RandomOn:$R:1}
				let R++
			fi			
		else
			if [ ${bit[$i]} == 1 ] ; then
				continue 
			else
				bit[$i]=${LedsOff_RandomOn:$R:1}
				let R++
			fi
		fi
	
	done
	Reverse_LED12_LightOnBin=$(echo ${bit[@]} | tr -d ' ')
	Reverse_LED8_LightOnHex=$(echo "obase=16;ibase=2; ${Reverse_LED12_LightOnBin:0-8:8}" | bc )
	Reverse_LED4_LightOnHex=$(echo "obase=16;ibase=2; ${Reverse_LED12_LightOnBin:0:4}" | bc )
	Reverse_LED8_LightOnHex=$(printf "%02X" "0x${Reverse_LED8_LightOnHex}" )
	Reverse_LED4_LightOnHex=$(printf "%02X" "0x${Reverse_LED4_LightOnHex}" )
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
		R|B) Behavior="0x44";;
		G) Behavior="0x40";;
		*) BehaviorSet=(0x40 0x44)
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

TurnOnLed()
{
	local Status="$1"
	local Behavior=""
	local Address_GroupA="$2"
	local Address_GroupB="$3"
	case ${Status} in
		R|B) Behavior="0x44";;
		G) Behavior="0x40";;
	esac
	ipmitool i2c bus=0 0xc0 0 ${Behavior} ${Address_GroupA} >/dev/null || let ErrorFlag++
    ipmitool i2c bus=0 0xc2 0 ${Behavior} ${Address_GroupB} >/dev/null || let ErrorFlag++
	if [ ${ErrorFlag} != 0 ] ; then
		return 1
	else
		return 0
	fi

}

FunctionTest()
{
	local Color="$1"
	local SubErrorFlag=0
	GetControl
	while :
	do
		InitLed ALL
		RandomLightOnOffCode ${Color}
		
		if [ ${SubErrorFlag} -ge 3 ] ; then
			Process 1 "Fail too many times ..."
			printf "%10s%60s\n" "" "Exit ..."
			let ErrorFlag++
			InitLed ${Color}
			exit 1
		fi
		
		TurnOnLed ${Color} "0x${LED8_LightOnHex}" "0x${LED4_LightOnHex}"
		if [ $? != 0 ] ; then
			Process 1 "Fail to turn on the LEDs ..."
			exit 1
		else
			case ${Color} in
				R)
					printf "%s\e[1;31m%s\e[0m%s" "第1組測試,觀察${Location}上的" "紅色LED" ",有幾個是常亮的,請在20秒鐘內輸入答案: "
					;;
					
				G)
					printf "%s\e[1;32m%s\e[0m%s\e[1;31m%s\e[0m%s" "第1組測試,觀察${Location}上的" "綠色LED" ",有幾個是" "閃爍" "的,請在20秒鐘內輸入答案: "			
					;;
					
				B)
					printf "%s\e[1;34m%s\e[0m%s" "第1組測試,請觀察${Location}上的" "藍色LED" ",有幾個是常亮的,在20秒鐘內輸入答案: "				
					;;
				esac
			numlockx on >/dev/null 2>&1
			read -n1 -t20 OpReply
			echo
			echo "${OpReply:-'y'}" | grep -iwq "${GroupA_StdAnswer}"
			if [ $? != 0 ] ; then
				Process 1 "正確的LED數量應該是: ${GroupA_StdAnswer}, 您輸入的數量是: ${OpReply} ..."
				let SubErrorFlag++
				continue
			else
				printf "%10s%s\n" "" "正確, 您輸入的數量是: ${OpReply}" 
				SubErrorFlag=0
			fi
		fi
		
		TurnOnLed ${Color} "0x${Reverse_LED8_LightOnHex}" "0x${Reverse_LED4_LightOnHex}"
		if [ $? != 0 ] ; then
			Process 1 "Fail to turn on the LEDs ..."
			exit 1
		else
			case ${Color} in
				R)
					printf "%s\e[1;31m%s\e[0m%s" "第2組測試,觀察${Location}上的" "紅色LED" ",有幾個是常亮的,請在20秒鐘內輸入答案: "
					LedColor="RED"
					;;
					
				G)
					printf "%s\e[1;32m%s\e[0m%s\e[1;31m%s\e[0m%s" "第2組測試,觀察${Location}上的" "綠色LED" ",有幾個是" "閃爍" "的,請在20秒鐘內輸入答案: "
					LedColor="GREEN"			
					;;
					
				B)
					printf "%s\e[1;34m%s\e[0m%s" "第2組測試,觀察${Location}上的" "藍色LED" ",有幾個是常亮的,請在20秒鐘內輸入答案: "
					LedColor="Blue"					
					;;
				esac
			numlockx on >/dev/null 2>&1		
			read -n1 -t20 OpReply
			echo
			echo "${OpReply:-'y'}" | grep -iwq "${GroupB_StdAnswer}"
			if [ $? != 0 ] ; then
				Process 1 "正確的LED數量應該是: ${GroupB_StdAnswer}, 您輸入的數量是: ${OpReply} ..."
				printf "%10s%s\n" "" "第2組測試FAIL後需要重新從第1組開始測試 ..."
				let SubErrorFlag++
				continue
			else
				printf "%10s%s\n" "" "正確, 您輸入的數量是: ${OpReply}" 
				SubErrorFlag=0
			fi
		fi
		
		Process ${SubErrorFlag} "Check the ${LedColor} LEDs ..."
		if [ ${SubErrorFlag} == 0 ] ; then
			InitLed ALL
			return 0
		fi
	done
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
	#Index=($(seq 0 ${#ColorSet[@]} | awk 'BEGIN{srand();ORS=" "} {b[rand()]=$0} END{for(x in b) print b[x]}'))
	printf "%s\n" "**********************************************************************"
	printf "%s\n" "       MS-S258K LED 功能測試程式，請根據提示輸入正確的LED數量         "
	printf "%s\n" "**********************************************************************"
	for c in ${ColorSet[@]}
	do
		 FunctionTest ${c:0:1}
		 printf "\n\n"
	done
	
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "Check all the LEDs on ${Location}"
	else
		echoFail "Check all the LEDs on ${Location}"
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
declare LED8_LightOnHex StdAnswer LED4_LightOnHex GroupA_StdAnswer Reverse_LED8_LightOnHex Reverse_LED4_LightOnHex GroupB_StdAnswer ColorSet
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
