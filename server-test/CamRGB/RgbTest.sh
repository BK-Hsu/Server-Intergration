#!/bin/bash
#FileName : RgbTest.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2019-08-15"
	local UpdatedDate="2019-08-15"
	local Description="RGB verify"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet camera GetMonitorInfo jpg2Bmp getBmpRGB)
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
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
	   0 : Check RGB color pass
	   1 : Check RGB color fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail
	
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml

	<RGBTest>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NXL09|RGB abnormal</ErrorCode>
			
			<!--CameraDevice: 攝像頭設備-->
			<CameraDevice>/dev/video0</CameraDevice>
			<!--ScreenDevice: 屏幕設備-->
			<ScreenDevice>/dev/fb0</ScreenDevice>
			<RGB>
				<!--讀取Red/Green/Bule圖片的時候，對應如下為RGB最小值-->
				<Colour index="R">200,100,100</Colour>
				<Colour index="G">100,200,125</Colour>
				<Colour index="B">100,100,200</Colour>
			</RGB>
			
			<Sampling>
				<!--採樣密度-->
				<WidthInterval>40</WidthInterval>
				<HeightInterval>30</HeightInterval>
			</Sampling>
		</TestCase>
	</RGBTest>

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
	
	# Get the RGB information from the config file(*.xml)
	CameraDevice=$(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/CameraDevice" -n "${XmlConfigFile}" 2>/dev/null)
	ScreenDevice=$(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/ScreenDevice" -n "${XmlConfigFile}" 2>/dev/null)
	WidthInterval=$(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/Sampling/WidthInterval" -n "${XmlConfigFile}" 2>/dev/null)
	HeightInterval=$(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/Sampling/HeightInterval" -n "${XmlConfigFile}" 2>/dev/null)
	RGBRange=($(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/RGB/Colour/@index" -n "${XmlConfigFile}" 2>/dev/null))
	if [ ${#CameraDevice} == 0 ] || [ ${#RGBRange} == 0 ] ; then
		Process 1 "Error parameters and config: ${XmlConfigFile}"
		exit 3
	fi
	return 0			
}

TakeAPhoto()
{
	if [ ! -e "${CameraDevice}" ] ; then
		ps ax | awk '/eog /{print $1}' | while read PID
		do
			kill -9 "${PID}" > /dev/null 2>&1
		done
		Process 1 "No found the camera device: ${CameraDevice}"
		exit 2
	fi

	camera -d "${CameraDevice}" -o > test.jpg
	Process $? "Take a photo name test.jpg ..." || return 1
	sync;sync;sync
	return 0
}

ShowColor()
{
	local Color=$(echo $1 | tr '[a-z]' '[A-Z]')

	if [ ! -e "${ScreenDevice}" ] ; then
		printf "%-s" "Found the screen device: "
		ls /dev/fb* 2>/dev/null
		Process 1 "No found the sreen device: ${ScreenDevice}"
		exit 2
	fi

	XYres=($(GetMonitorInfo ${ScreenDevice} 2>/dev/null | grep -iw "xres\|yres" | tr ',' '\n' | tr -d ' ' | awk -F'=' '{print $NF}'))
	#用高度x100÷寬度900/1600=56等以此類推確認打開的圖片為滿屏狀態
	let YdX=${XYres[1]:-"4"}*100/${XYres[0]:-"5"}
	local PicPath="5-4"
	case ${YdX} in 
		56)PicPath="16-9";;
		80)PicPath="5-4";;
		133)PicPath="4-3";;
		esac

	case ${Color} in
		R)gnome-terminal --hide-menubar --geometry=1x1 -x bash -c "eog -f ${WorkPath}/rgbPic/${PicPath}/red.png";;
		G)gnome-terminal --hide-menubar --geometry=1x1 -x bash -c "eog -f ${WorkPath}/rgbPic/${PicPath}/green.png";;
		B)gnome-terminal --hide-menubar --geometry=1x1 -x bash -c "eog -f ${WorkPath}/rgbPic/${PicPath}/blue.png";;
		esac
}

main()
{
	let Divisor=2**24

	for ((c=0;c<${#RGBRange[@]};c++))
	do
		rm -rf ${RGBRange[$c]}.log ${RGBRange[$c]}.bmp test.bmp test.jpg 2>/dev/null

		ShowColor ${RGBRange[$c]}

		sleep 2

		TakeAPhoto
		jpg2Bmp
		mv test.bmp ${RGBRange[$c]}.bmp 2>/dev/null
		getBmpRGB ${RGBRange[$c]}.bmp ${WidthInterval} ${HeightInterval} > ${RGBRange[$c]}.log 2>/dev/null
		
		ps ax | awk '/eog /{print $1}' | while read PID
		do
			kill -9 "${PID}" > /dev/null 2>&1
		done

	done

	for ((c=0;c<${#RGBRange[@]};c++))
	do
		cat ${RGBRange[$c]}.log | grep -iwq "biBitCount: 24"
		if [ $? != 0 ] ; then
			Process 1 "Wrong format of picture: ${RGBRange[$c]}.bmp"
			let ErrorFlag++
		fi
		#RGBRangeValue=200,100,100
		RGBRangeValue=($(xmlstarlet sel -t -v "//RGBTest/TestCase[ProgramName=\"${BaseName}\"]/RGB/Colour[@index=\"${RGBRange[$c]}\"]" -n "${XmlConfigFile}" 2>/dev/null | tr "," " "))
		local RGBValue_R=()
		local RGBValue_G=()
		local RGBValue_B=()
		RGBValue_R=($( grep -wE "^RGB" ${RGBRange[$c]}.log | awk -F':' '{print $NF}' | tr -d " " | awk -F',' '{print $1}'))
		RGBValue_G=($( grep -wE "^RGB" ${RGBRange[$c]}.log | awk -F':' '{print $NF}' | tr -d " " | awk -F',' '{print $2}'))
		RGBValue_B=($( grep -wE "^RGB" ${RGBRange[$c]}.log | awk -F':' '{print $NF}' | tr -d " " | awk -F',' '{print $3}'))
		
		RGBRangeValue_R_Cnt=0
		RGBRangeValue_G_Cnt=0
		RGBRangeValue_B_Cnt=0
		for((i=0;i<${#RGBValue_R[@]};i++))
		do
			if [ ${RGBValue_R[$i]} -ge 256 ] ; then
				let RGBValue_R[$i]=${RGBValue_R[$i]}/${Divisor}
			fi
			
			if [ ${RGBValue_R[$i]} -ge ${RGBRangeValue[0]} ] ; then
				let RGBRangeValue_R_Cnt++
			fi
		done
		
		for((i=0;i<${#RGBValue_G[@]};i++))
		do
			if [ ${RGBValue_G[$i]} -ge 256 ] ; then
				let RGBValue_G[$i]=${RGBValue_G[$i]}/${Divisor}
			fi
			
			if [ ${RGBValue_G[$i]} -ge ${RGBRangeValue[1]} ] ; then
				let RGBRangeValue_G_Cnt++
			fi
		done

		for((i=0;i<${#RGBValue_B[@]};i++))
		do
			if [ ${RGBValue_B[$i]} -ge 256 ] ; then
				let RGBValue_B[$i]=${RGBValue_B[$i]}/${Divisor}
			fi
			
			if [ ${RGBValue_B[$i]} -ge ${RGBRangeValue[2]} ] ; then
				let RGBRangeValue_B_Cnt++
			fi
		done
		
		let RedPercent=${RGBRangeValue_R_Cnt}*100/${#RGBValue_R[@]}
		let GreenPercent=${RGBRangeValue_G_Cnt}*100/${#RGBValue_G[@]}
		let BluePercent=${RGBRangeValue_B_Cnt}*100/${#RGBValue_B[@]}

		local Color=$(echo ${RGBRange[$c]} | tr '[a-z]' '[A-Z]')
		local ColorName=''
		local ColorErrorFlag=0
		case ${Color} in
			R)
				[ ${GreenPercent} -lt 20 ] || let ColorErrorFlag++
				[ ${BluePercent} -lt 20 ] || let ColorErrorFlag++
			
				[ ${GreenPercent} == 0 ] && let ColorErrorFlag=0
				[ ${BluePercent} == 0 ] && let ColorErrorFlag=0
		
				[ ${RedPercent} -ge 80 ] || let ColorErrorFlag++
				ColorName='red'
			;;

			G)
				[ ${RedPercent} -lt 20 ] || let ColorErrorFlag++
				[ ${BluePercent} -lt 20 ] || let ColorErrorFlag++
				
				[ ${RedPercent} == 0 ] && let ColorErrorFlag=0
				[ ${BluePercent} == 0 ] && let ColorErrorFlag=0
		
				[ ${GreenPercent} -ge 80 ] || let ColorErrorFlag++			
				ColorName='green'
			;;

			B)
				[ ${RedPercent} -lt 20 ] || let ColorErrorFlag++
				[ ${GreenPercent} -lt 20 ] || let ColorErrorFlag++
				
				[ ${RedPercent} == 0 ] && let ColorErrorFlag=0
				[ ${GreenPercent} == 0 ] && let ColorErrorFlag=0
		
				[ ${BluePercent} -ge 80 ] || let ColorErrorFlag++
				ColorName='blue'
			;;
		esac

		echo "------------------------------------------------"
		printf "%-6s%-2s%6s%16s%8s\n" "Red" "" ">${RGBRangeValue[0]}: " "${RGBRangeValue_R_Cnt}/${#RGBValue_R[@]}" "${RedPercent}%"
		printf "%-6s%-2s%6s%16s%8s\n" "Green" "" ">${RGBRangeValue[1]}: " "${RGBRangeValue_G_Cnt}/${#RGBValue_G[@]}" "${GreenPercent}%"
		printf "%-6s%-2s%6s%16s%8s\n" "Bule" "" ">${RGBRangeValue[2]}: " "${RGBRangeValue_B_Cnt}/${#RGBValue_B[@]}" "${BluePercent}%"
		echo "------------------------------------------------"
		
		Process ${ColorErrorFlag} "Verify the color of \"${ColorName}\" ..." || let ErrorFlag++
	done

	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "RGB verify"
		rm -rf *.txt *.log *.bmp *.jpg 2>/dev/null
	else
		echoFail "RGB verify"
		GenerateErrorCode
		exit 1
	fi
}

#----main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile CameraDevice WidthInterval HeightInterval RGBRange RGBRangeValue ScreenDevice
declare Divisor=1
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
			printf "%-s\n" "SerialTest,RGBComfirn"
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
