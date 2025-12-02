#!/bin/bash
#============================================================================================
#        File: AutoChkNetLEDs.sh
#    Function: Auto check the status and color of LEDs by Camera
#     Version: 1.1.0
#      Author: Cody,qiutiqin@msi.com
#     Created: 2018-09-19
#     Updated: 2019-07-04
#  Department: Application engineering course
# 		 Note: the tool of camera developed by KaiLuo
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
	ExtCmmds=(xmlstarlet ${LedTool})
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


ShowTitle()
{
	local BlankCnt=0
	echo 
	ApVersion=$(cat -v `basename $0` | grep -i "version" | head -n1 | awk '{print $3}')
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
`basename $0` [-x lConfig.xml] [-D|d]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -d
	
	-D : Dump the sample xml config file
	-d : For debug only,get the location of LED
	-x : config file,format as: *.xml

	return code:
		0 : Test pass
		1 : Test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<LED>
		<TestCase>
			<ProgramName>AutoChkNetLEDs</ProgramName>
			<ErrorCode>TXLAF|LAN led abnormal</ErrorCode>
			<!-- for AutoChkNetLEDs.sh -->
			<!-- Act-X|Act-Y|Spd-X|Spd-Y|Act.LED|Spd-10Mb|Spd-100Mb|Spd-1000Mb|Spd-10Gb|Marking|Shell -->
			<!-- Standard Color: 0-undefine or while,1-green,2-orange,3-red,4-blue,.-ignored,d-dark -->
			<LED>2|2|1|2|1|d|2|1|0|LAN1|LAN12_LED.sh</LED>
			<LED>3|2|4|2|1|d|2|1|0|LAN2|-</LED>
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

	# Get the information from the config file(*.xml)
	LEDsConfigFile=${BaseName}.ini
	xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/LED" -n "${XmlConfigFile}" 2>/dev/null | tr -d '\t' | grep -v "^$" >${BaseName}.ini 2>/dev/null
	sync;sync;sync

	if [ ! -f "${LEDsConfigFile}" ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

CreateConfigFile()
{
	if [ ${#LEDsConfigFile} != 0 ]; then
		return 0
	fi

	#eg.: `basename $0` -l 4,3,3,3 -A 1 -C d,2,1,0 -n LAN1 -a LAN12_LED.sh
	#2|2|1|2|1|0|2|1|0|LAN1|LAN12_LED.sh
	LEDsConfigFile=${BaseName}.ini
	rm -rf ${LEDsConfigFile} 2>/dev/null
	for ((p=0;p<${#Location[@]};p++))
	do
		SubLocation=$(echo ${Location[$p]} | tr ',' '|')
		SubActLEDColorCode=$(echo ${ActLEDColorCode[$p]} | tr ',' '|') 	
		
		#n=null,undefine,or does not need to test
		SubStdCode=$(echo ${StdCode[$p]} | tr ',' '|' | tr -d '[a-zA-Z]') 	
		SubPcbMarking=$(echo ${PcbMarking[$p]} | tr ',' '|') 	
		SubActiveShell=$(echo ${ActiveShell[$p]} | tr ',' '|') 	
		echo "${SubLocation}|${SubActLEDColorCode}|${SubStdCode}|${SubPcbMarking}|${SubActiveShell}" >>${LEDsConfigFile}
		sync;sync;sync
	done

	if [ ! -s "${LEDsConfigFile}" ] ; then
		Process 1 "No such file or 0 KB size of file: ${LEDsConfigFile}"
		exit 2
	fi
}

EnableCamera()
{
	ls /dev/ 2>/dev/null | grep -iq video
	if [ $? -ne 0  ] ; then
		Process 1 "No such usb Micsoft camera: /dev/video#"
		exit 2
	else
		CameraDevice=$(ls /dev/* | grep -i "video" | head -n1)
	fi

	echo "Enable the usb camera ..."
	rm -rf ${BaseName}.log 2>/dev/null
	killall ${LedTool} 2>/dev/null
	sleep 2
	${LedTool} ${CameraDevice} ${BaseName}.log 2>/dev/null &
	sleep 2
}

GetXYLocation()
{
	EnableCamera
	while :
	do
		clear
		echo -e "\e[0;30;43m ********************************************************************** \e[0m"
		echo -e "\e[0;30;43m ***         Get a LED X,Y(C,R) coordinates,for debug only          *** \e[0m"
		echo -e "\e[0;30;43m ********************************************************************** \e[0m"
		#Get the YLocation
		echo
		echo X=`grep -nE "[1-9],[1-9]" ${BaseName}.log | tr '|' '\n' | grep -nE "[1-9],[1-9]"  |awk -F':' '{print $1}'`
		echo Y=`grep -nE "[1-9],[1-9]" ${BaseName}.log | awk -F':' '{print $1}'`
		
		read -t3 -p "Press [Enter/Y] to check again,[Q] to quit. " -n1 Reply
		Reply=${Reply:-"Y"}
		echo
		case ${Reply} in
			Y|y)continue;;
			Q|q)break;;
			*)echo "Wrong key! Try again: [Enter/Y]=continue, [Q]=Qiut.";;
		esac	
	done

	# killall process in background
	killall ${LedTool} >/dev/null 2>&1
	exit 5
}

Code2Color()
{
	local Code=$1
	Code=${Code:-"U"}
	case $Code in
		0)Color='dark';;
		1)Color=green;;
		2)Color=orange;;
		3)Color=red;;
		4)Color=blue;;
		U|u)Color="---";;
		.)Color=ignored;;

		*)
			echo "Undefine yet, Invalid code"
			exit 3
		;;
		esac
}

Code2Status()
{
	local Code=$1
	Code=${Code:-"U"}
	case $Code in
		0)Status=off;;
		1)Status=on;;
		2)Status=blinking;;
		3|.)Status=ignored;;
		U|u)Status="---";;
		*)
			echo "Undefine yet, Invalid code"
			exit 3
		;;
		esac
}

CheckLED()
{
	local LogFile=$1
	local X=$2
	local Y=$3
	local StdColor=$4
	local Status=$5

	# Usage: CheckLED LogFile X Y StdColor ON|OFF
	# Check LED, check it turned on and the color is right
	CurCode=($(sed -n ${Y}p  ${LogFile} | awk -F'|' -v C=${X} '{print $C}' | tr ',' ' '))
	if [ $(echo ${Status} | grep -ic 'on') == 1 ] ; then
		echo ${CurCode[@]} | grep -wEq "${StdColor} [1-9]"
	else
		echo ${CurCode[@]} | grep -wEq "[0-9] 0"
	fi

	if [ "$?"x != "0x" ] ; then 
		return 1
	else
		return 0
	fi 
}

PrintColor()
{
	local Code=$1
	# Usage: PrintColor ColorCode
	Code2Color ${Code}
	Color=${Color:-"---"}
	case ${Color} in
		dark|---)printf "%-8s" ${Color};;
		green)printf "\e[32m%-8s\e[0m" ${Color};;
		orange)printf "\e[33m%-8s\e[0m" ${Color};;
		red)printf "\e[31m%-8s\e[0m" ${Color};;
		blue)printf "\e[34m%-8s\e[0m" ${Color};;
		ignored)printf "\e[1;31m%-8s\e[0m" ${Color};;
		*)
			printf "\e[1;31m%-8s\e[0m" "Invalid"
			exit 5
			;;
		esac
}

AnalyseLog4NETLED ()
{
	ShowTitle "Analyse LEDs' Log for LAN"
	# LED#    A-C,R  S-C,R   G-D#   G-O#   G-G#   O-D#   O-G#   O-O#   A-A#
	#----------------------------------------------------------------------
	#LAN1      2,3    1,2     1      2      0      0      12     12     20
	#LAN2      2,4    2,2     1      2      0      0      14     14     20
	#LAN3      2,5    3,2     1      2      0      0      1      14     20
	#LAN4      2,6    4,2     1      2      0      0      12     14     20
	#----------------------------------------------------------------------
	#G-Green,O-Orange,D-Dark,A-Amount of lighting on /blinking

	printf "%-9s%-7s%-7s%-7s%-7s%-7s%-7s%-7s%-7s%-4s\n"   "LED#"    "A-C,R"  "S-C,R"   "G-D#"   "G-O#"   "G-G#"   "O-D#"   "O-G#"   "O-O#"   "A-A#"
	echo "----------------------------------------------------------------------"
	for ((L=0;L<${#AllLEDs[@]};L++))
	do
		#4|2|1|1|ErrorLED|ErrorLED.sh
		printf "%-10s%-7s%-7s" "${PcbMarking[$L]}" "${ActXLocation[$L]},${ActYLocation[$L]}" "${SpdXLocation[$L]},${SpdYLocation[$L]}"
		
		#G-D#  
		printf "%-7s" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "[0-9],0V1,[1-9]"`
		
		#G-O#
		printf "%-7s" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "2,[1-9]V1,[1-9]"`
		
		#G-G#
		printf "%-7s" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "1,[1-9]V1,[1-9]"`
		
		
		#O-D#
		printf "%-7s" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "[0-9],0V2,[1-9]"`

		#O-G#
		printf "%-7s" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "1,[1-9]V2,[1-9]"`

		#O-O#
		printf "%-7s" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "2,[1-9]V2,[1-9]"`
		
		#A-A#
		printf "%-3s\n" `cat ${PcbMarking[$L]}.log 2>/dev/null | grep -Ec "[1-9],[1-9]V[1-9],[1-9]"`
		rm -rf ${PcbMarking[$L]}.log
	done
	echo "----------------------------------------------------------------------"
	echo "G-Green,O-Orange,D-Dark,A-Amount of lighting on /blinking"
}

main ()
{
	echo ${#XmlConfigFile}${#LEDsConfigFile} | grep -q [1-9]
	if [ $? != 0 ] ; then
		# this the command line mode, both XmlConfigFile=null and LEDsConfigFile=null
		if [ ${#Location[@]} != 0 ] && [ ${#Location[@]} == ${#StdCode[@]} ] && [ "${#Location[@]}x" == "${#PcbMarking[@]}x" ] ; then
			CreateConfigFile
		else
			Process 1 "Invalid parameters,check parameters"
			printf "%-10s%-60s\n" ""  "Parameters1: ${Location[@]}"
			printf "%-10s%-60s\n" ""  "Parameters2: ${StdCode[@]}"
			printf "%-10s%-60s\n" ""  "Parameters3: ${#PcbMarking[@]}"
			exit 3
		fi
	fi

	EnableCamera

	# Active all LEDs in back ground
	ActiveShell=($(cat $LEDsConfigFile 2>/dev/null | awk -F'|' '{print $11}'))
	if [ ${#ActiveShell[@]} != 0 ]; then
		for((s=0;s<${#ActiveShell[@]};s++))
		do
			echo ${ActiveShell[$s]} | grep -iq "sh"
			if [ $? == 0 ] ; then
				(./${ActiveShell[$s]} >/dev/null 2>&1) &
			fi
		done
	fi

	# Get the test record
	<<-CAMERA
	0,0|0,0|0,0|0,0|0,0|0,0|0,0|0,0|
	0,0|0,0|0,0|1,1|0,0|0,0|0,0|0,0|
	0,0|0,0|0,0|0,0|0,0|0,0|0,0|0,0|
	0,0|0,0|0,0|0,0|0,0|0,0|0,0|0,0|
	0,0|0,0|0,0|0,0|0,0|0,0|0,0|0,0|
	0,0|0,0|0,0|0,0|0,0|0,0|0,0|0,0|
	CAMERA
		
	mkdir -p ./logs
	rm -rf ./logs/NET_*.log >/dev/null 2>&1
	echo -e "\e[1;33m Active the LAN LEDs, please wait ...\e[0m"
	for((P=0;P<150;P++))
	do
		TempLogName=$(echo "./logs/NET_`date "+%Y%m%d%H%M%S"`.log")
		cat ${BaseName}.log > ${TempLogName}
		sync;sync;sync
		sleep 1.1
		ps all >./logs/ps.log
		cat ./logs/ps.log | grep -iq "celo"
		if [ $? != 0 ]; then
			break
		fi
		echo -ne "\e[1;33m`printf "\rGet the LEDs lighting record, time elapsed %02d seconds ...\n" "${P}"`\e[0m"

	done

	if [ $P -ge 100 ] ; then
		Process 1 "Time out, Active LAN LED test fail"
		exit 4
	fi 

	# Kill the process firstly
	killall ${LedTool} >/dev/null 2>&1

	#Check the color,status code 
	AllLogs=($(ls ./logs/NET_*.log | grep -iv 'ps' | sort -s))
	AllLEDs=($(cat ${LEDsConfigFile} 2>/dev/null | grep -v "^$"))
	for ((L=0;L<${#AllLEDs[@]};L++))
	do
		echo $(echo ${AllLEDs[$L]} | awk -F'|' '{print $1,$3}') | grep -q "9\|[1-9][0-9]" 
		if [ $? == 0 ] ; then
			Process 1 "Invalid X coordinates"
			printf "%-10s%-60s\n" ""  "The X coordinates value should less then 9."
			exit 3
		fi
		
		echo $(echo ${AllLEDs[$L]} | awk -F'|' '{print $2,$4}') | grep -q "[7-9]\|[1-9][0-9]"
		if [ $? == 0 ] ; then
			Process 1 "Invalid Y coordinates"
			printf "%-10s%-60s\n" ""  "The Y coordinates value should less then 7."
			exit 3
		fi

		# Act-X|Act-Y|Spd-X|Spd-Y|Act.LED|Spd-10Mb|Spd-100Mb|Spd-1000Mb|Spd-10Gb|Marking|Shell 
		# Standard Color: 0-undefine or while,1-green,2-orange,3-red,4-blue,.-ignored,d-dark 
		#2|2|1|2|1|d|2|1|0|LAN1|LAN12_LED.sh
		ActXLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $1}')
		ActYLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $2}')
		
		SpdXLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $3}')
		SpdYLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $4}')
		PcbMarking[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $10}')	
		rm -rf ${PcbMarking[$L]}.log 2>/dev/null
		for ((a=0;a<${#AllLogs[@]};a++))
		do
			ActLED=$(sed -n ${ActYLocation[$L]}p  ${AllLogs[$a]} | awk -F'|' -v C=${ActXLocation[$L]} '{print $C}')
			SpdLED=$(sed -n ${SpdYLocation[$L]}p  ${AllLogs[$a]} | awk -F'|' -v C=${SpdXLocation[$L]} '{print $C}')
			echo "${SpdLED}V${ActLED}">>${PcbMarking[$L]}.log
			sync;sync;sync
		done
	done

	#                        Spd. LED                    Act. LED               
	#LED#        C.R  10Mb    100Mb   1000Mb  10Gb    C.R   Ac.tLED Result
	#----------------------------------------------------------------------
	#LAN1        1,6  Dark    Orange  Green   ---     1,5   Green   Pass
	#LAN2        2,6  ---     ---     Orange  Green   2,5   Green   Pass
	#LAN3        3,6  ---     ---     ---     Green   3,5   Green   Pass
	#----------------------------------------------------------------------
	#10Mb--Dark  100Mb--Green  1000Mb--Orange  10Gb--Green
	clear
	ShowTitle "LANs LED Auto Check Program"
	printf "%32s%28s\n" "Spd. LED" "Act. LED"
	printf "%-12s%-5s%-8s%-8s%-8s%-8s%-6s%-8s%-7s\n" "LED#" "C.R" "10Mb" "100Mb" "1000Mb" "10Gb" "C.R" "Act.LED" "Result"
	echo "----------------------------------------------------------------------"	
	for ((L=0;L<${#AllLEDs[@]};L++))
	do	
		ActXLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $1}')
		ActYLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $2}')
		SpdXLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $3}')
		SpdYLocation[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $4}')
		ActColourCode[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $5}')
		Spd10MbColourCode[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $6}')
		Spd100MbColourCode[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $7}')
		Spd1000MbColourCode[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $8}')
		Spd10000MbColourCode[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $9}')
		PcbMarking[$L]=$(echo ${AllLEDs[$L]} | awk -F'|' '{print $10}')		
		
		# Check Speed LED, check it turned on and the color is right
		TestResult='1'
		ChkColor='1'
		HWSpec=$(echo "${Spd10MbColourCode[$L]}Q${Spd100MbColourCode[$L]}Q${Spd1000MbColourCode[$L]}Q${Spd10000MbColourCode[$L]}")
		case ${HWSpec} in
		0Q[1-9]Q[1-9]Q)
			#10Mb->100Mb-->1000Mb
			Chk10MbLED="1"
			Chk100MbLED="1"
			Chk1000MbLED="1"
			cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEA500 "[0,1,${Spd10MbColourCode[$L]}],0V${ActColourCode[$L]},[1-9]" | grep -wEA500  "${Spd100MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]"  | grep -qwE "${Spd1000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]" && ChkColor='0'
			[ $(cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEc  "[0,1,${Spd10MbColourCode[$L]}],0V${ActColourCode[$L]},[1-9]") -ge 3 ] && Chk10MbLED='0'
			[ $(cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEA500 "[0,1,${Spd10MbColourCode[$L]}],0V${ActColourCode[$L]},[1-9]" | grep -wEc  "${Spd100MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]") -ge 3 ] && Chk100MbLED='0'
			[ $(cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEA500 "[0,1,${Spd10MbColourCode[$L]}],0V${ActColourCode[$L]},[1-9]" | grep -wEA500  "${Spd100MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]" | grep -wEc "${Spd1000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]") -ge 3 ] && Chk1000MbLED='0'
			echo ${ChkColor}${Chk10MbLED}${Chk100MbLED}${Chk1000MbLED} | grep -vq "1"
			if [ $? == 0 ] ; then
				TestResult=0
			fi
			;;
		
		QQ[1-9]Q[1-9])
			#1000Mb-->10000Mb
			Chk1000MbLED="1"
			Chk10000MbLED="1"
			cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEA500  "${Spd1000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]"  | grep -wqE "${Spd10000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]" && ChkColor='0'
			[ $(cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEc  "${Spd1000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]") -ge 3 ] && Chk1000MbLED='0'
			[ $(cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wEA500  "${Spd1000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]" | grep -wEc "${Spd10000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]") -ge 3 ] && Chk10000MbLED='0'
			echo ${ChkColor}${Chk1000MbLED}${Chk10000MbLED} | grep -vq "1"
			if [ $? == 0 ] ; then
				TestResult=0
			fi
			;;
			
		QQQ[1-9])
			#10000Mb
			Chk10000MbLED="1"
			cat ${PcbMarking[$L]}.log 2>/dev/null | grep -wqE "${Spd10000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]" && ChkColor='0'
			[ $(cat ${PcbMarking[$L]}.log 2>/dev/null| grep -wEc "${Spd10000MbColourCode[$L]},[1-9]V${ActColourCode[$L]},[1-9]") -ge 3 ] && Chk10000MbLED='0'
			echo ${ChkColor}${Chk10000MbLED} | grep -vq "1"
			if [ $? == 0 ] ; then
				TestResult=0
			fi
			;;	
		
		*)
			Process 1 "Invalid config file"
			exit 2
			;;
		esac
		
		# Print the location of Speed LED
		printf "%-12s%-5s" "${PcbMarking[$L]}" "${SpdXLocation[$L]},${SpdYLocation[$L]}"
		
		Color10=`PrintColor ${Spd10MbColourCode[$L]}`
		Color100=`PrintColor ${Spd100MbColourCode[$L]}`
		Color1000=`PrintColor ${Spd1000MbColourCode[$L]}`
		Color10000=`PrintColor ${Spd10000MbColourCode[$L]}`
			
		# Print the current color of Speed LED
		if [ $TestResult == 0 ]; then
			PrintColor ${Spd10MbColourCode[$L]}
			PrintColor ${Spd100MbColourCode[$L]}
			PrintColor ${Spd1000MbColourCode[$L]}
			PrintColor ${Spd10000MbColourCode[$L]}
			
			# Print the current color of Active LED
			printf "%-6s" "${ActXLocation[$L]},${ActYLocation[$L]}"
			PrintColor ${ActColourCode[$L]}
		
		else
			printf "%-8s%-8s%-8s%-8s" "Error" "Error" "Error" "Error" 
			printf "%-6s" "${ActXLocation[$L]},${ActYLocation[$L]}"
			PrintColor ""
			let ErrorFlag++
		fi
		
		#Result
		if [ ${TestResult} == 0 ] ; then
			printf "\e[1;32m%-7s\n\e[0m" "Pass"
			
			#if pass, rm the log fail
			#rm -rf ${PcbMarking[$L]}.log
		else
			printf "\e[1;31m%-7s\n\e[0m" "Fail"
			let ErrorFlag++
		fi
	done
	echo "----------------------------------------------------------------------"
	echo -n "Speed LED spec: "
	echo "10Mb-${Color10}/100Mb-${Color100}/1Gb-${Color1000}/10Gb-${Color10000}" | tr -d '\t '
	echo "C=COLUMN, R=ROW"
	if [ $ErrorFlag == 0 ] ; then
		echoPass "All LANs LED test" 
	else
		AnalyseLog4NETLED
		echoFail "Some LANs LED test" 
		GenerateErrorCode
	fi

	# killall process in background
	if [ ${#ActiveShell[@]} != 0 ]; then
		for((s=0;s<${#ActiveShell[@]};s++))
		do
			echo ${ActiveShell[$s]} | grep -iq "*.sh$"
			if [ $? == 0 ] ; then
				killall ${ActiveShell[$s]} >/dev/null 2>&1
			fi
		done
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare LedTool='led_camera'
declare XmlConfigFile LEDsConfigFile CameraDevice 
declare Location XLocation YLocation StdCode CurCode ColourCode StatusCode PcbMarking ActiveShell Color Status ActLEDColorCode
declare ActXLocation ActYLocation SpdXLocation SpdYLocation
declare ActColourCode Spd10MbColourCode Spd100MbColourCode Spd1000MbColourCode Spd10000MbColourCode
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :Ddx: argv
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

		d)
			GetXYLocation
			#For debug only
			exit 5
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
