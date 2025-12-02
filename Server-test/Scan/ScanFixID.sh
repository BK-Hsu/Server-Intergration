#!/bin/bash
#FileName : ScanFixID.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.2"
	local CreatedDate="2018-07-10"
	local UpdatedDate="2020-10-30"
	local Description="Scan Fixture ID and save in file FIXID.TXT"
	
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
	printf "%16s%-s\n" "" "2020-09-16,Add the tool: scanner for forbidden keyboard input"
	printf "%16s%-s\n" "" "2020-10-30,Add Scan cycle"
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

ChkExternalCommands ()
{
	ExtCmmds=(xmlstarlet)
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

PrintfTip()
{
	local String="$@"
	LCutCnt=$(echo "ibase=10;obase=10; (70-${#String})/2" | bc)
	RCutCnt=$(echo "ibase=10;obase=10; 50-${LCutCnt}" | bc)
	Left=$(echo "<<------------------------------------------------" | cut -c 1-${LCutCnt})
	Right=$(echo "------------------------------------------------>>" | cut -c ${RCutCnt}-)
	local PrintfStr="${Left}${String}${Right}"
	printf "\e[0;30;43m%70s\e[0m\n" "${PrintfStr}"
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
		0 : Fixture ID scan pass
		1 : Fixture ID scan fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Scan>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<!-- ScanFixID.sh: Length=0表示no limited -->
			<Length>6</Length>
			<SavePath>/TestAP/PPID</SavePath>
			
			<!-- A: 20Bit,EPS_Bur_b33_01-01-01 -->
			<!-- B: 6Bit,B3Dxxx,B3Cxxx,B3xxxx,Sxxxxx,e.g.:B3D001,B33001 -->
			<!-- C: 6bit,B3D001,123123 -->
			<!-- D: no-limited,auto input HDD SN -->
			<FormatType>D</FormatType>
			<!--每測試多少PCS主板掃描一次? 1：每次都掃描，n：每n次掃描一次-->
			<ScanCycle>1</ScanCycle>
		</TestCase>
	</Scan>
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
	
	# Get the information from the config file
	Length=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/Length" -n "${XmlConfigFile}" 2>/dev/null)
	SavePath=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/SavePath" -n "${XmlConfigFile}" 2>/dev/null)
	FormatType=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/FormatType" -n "${XmlConfigFile}" 2>/dev/null)
	ScanCycle=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/ScanCycle" -n "${XmlConfigFile}" 2>/dev/null)
	
	if [ ${#ScanCycle} == 0 ] || [ "${ScanCycle}"x == "0x" ]; then
		ScanCycle=20
	else
		if [ $(echo "${ScanCycle}" | grep -iwEc "[0-9]{1,9}") == 0 ] ; then
			Process 1 "Invalid Scan Cycle: ${ScanCycle}"
			let ErrorFlag++
		fi
	fi
	
	if [ ${#SavePath} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi
	
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0
}

main ()
{
	which scanner >/dev/null 2>&1
	if [ $? != 0 ] && [ -f "scanner" ] ; then
		chmod 777 ./scanner >/dev/null 2>&1
		cp -rf ./scanner /bin >/dev/null 2>&1	 
	fi

	FormatType=${FormatType:-'D'}
	if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
		Length=''
		# Show length on screem
		sLength='No-limited'
	else
		sLength=${Length}
	fi

	EOS=$(echo $SavePath | tr -d ' ' | awk -F'/' '{print $NF}')
	if [ ${#EOS} == 0 ] ; then
		let CutLength=${#SavePath}-1
		SavePath=$(echo $SavePath | tr -d ' ' | cut -c 1-${CutLength} )
	else
		SavePath=$(echo $SavePath | tr -d ' ')
	fi

	if [ -s "FIXID.ini" ] && [ ${#pcb} -gt 0 ] && [ $(($(cat FIXID.ini 2>/dev/null | wc -l )%${ScanCycle})) != 0 ] && [ "${ScanCycle}" != 1 ] ; then
		fixid=$(cat FIXID.ini 2>/dev/null | grep -iE "[0-9A-Z]" | tail -n1 | cut -c 1- )
		echo "$fixid" > $SavePath/FIXID.TXT
		echo "$fixid" >> FIXID.ini
		sync;sync;sync
		echoPass "FIXID: $fixid, read from: $WorkPath/FIXID.ini"
		return 0
	fi

	while :
	do
		case ${FormatType} in
		A|a)
			#A: 20Bit,EPS_Bur_b33-01-01-01
			Length='20'
			while :
			do 
				BeepRemind 0
				PrintfTip "Please scan 20-bit Fixture number, eg.: EPS_Bur_b33-01-01-01" 2>/dev/null
				echo -ne "Scan \033[31m20-bit\033[0m Fixture number: ____________________\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
				which scanner >/dev/null 2>&1
				if [ $? == 0 ] ; then
					rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
					scanner ${WorkPath}/scan_${BaseName}.txt || continue
					#read fixid<${WorkPath}/scan_${BaseName}.txt
					fixid=$(cat ${WorkPath}/scan_${BaseName}.txt | sed 's/!/1/g' |sed 's/@/2/g' |sed 's/#/3/g' |sed 's/\$/4/g' |sed 's/%/5/g' |sed 's/\^/6/g' |sed 's/\&/7/g' |sed 's/\*/8/g' |sed 's/(/9/g' |sed 's/)/0/g')
					rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
				else
					read fixid
				fi		
			
				echo $fixid | grep -Eq '^[Ee][Pp][Ss]_[Bb][Uu][Rr]_[A-Za-z][0-9A-Za-z]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}+$' 
				if [ $? != 0 ] ; then
					Process 1 "Invalid FIXID: $fixid"
					printf "%-10s%-60s\n" "" "Try again ... "
					echo
					continue	
				else
					break		
				fi
			done
		;;
		
		B|b)
			#B: 6Bit,B3Dxxx,B3Cxxx,B3xxxx,Sxxxxx,e.g.:B3D001,B33001
			while :
			do 
				BeepRemind 0
				PrintfTip "Please scan ${sLength}-bit Fixture number, eg.: B3B001, B33125" 2>/dev/null
				echo -ne "Scan \033[31m${sLength}-bit\033[0m Fixture number: ______\b\b\b\b\b\b"
				which scanner >/dev/null 2>&1
				if [ $? == 0 ] ; then
					rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
					scanner ${WorkPath}/scan_${BaseName}.txt || continue
					#read fixid<${WorkPath}/scan_${BaseName}.txt
					fixid=$(cat ${WorkPath}/scan_${BaseName}.txt | sed 's/!/1/g' |sed 's/@/2/g' |sed 's/#/3/g' |sed 's/\$/4/g' |sed 's/%/5/g' |sed 's/\^/6/g' |sed 's/\&/7/g' |sed 's/\*/8/g' |sed 's/(/9/g' |sed 's/)/0/g')
					rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
				else
					read fixid
				fi	
				
				if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
					echo $fixid | grep -Eq "^[BbSs][0-9A-Za-z]{1,50}"
				else
					let iLength=$Length-1
					echo $fixid | grep -Eq "^[BbSs][0-9A-Za-z]{${iLength}}+$"
				fi
				
				if [ $? != 0 ] ; then
					Process 1 "Invalid FIXID: $fixid"
					printf "%-10s%-60s\n" "" "Try again ... "
					echo
					continue	
				else
					break		
				fi			
			done
		;;
		
		C|c)
			#C: 6bit,B3D001,123123
			while :
			do 
				BeepRemind 0
				PrintfTip "Please scan ${sLength}-bit Fixture number, eg.: 123456" 2>/dev/null
				echo -ne "Scan \e[31m${sLength}-bit\e[0m Fixture number: ______\b\b\b\b\b\b"
				which scanner >/dev/null 2>&1
				if [ $? == 0 ] ; then
					rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
					scanner ${WorkPath}/scan_${BaseName}.txt || continue
					#read fixid<${WorkPath}/scan_${BaseName}.txt
					fixid=$(cat ${WorkPath}/scan_${BaseName}.txt | sed 's/!/1/g' |sed 's/@/2/g' |sed 's/#/3/g' |sed 's/\$/4/g' |sed 's/%/5/g' |sed 's/\^/6/g' |sed 's/\&/7/g' |sed 's/\*/8/g' |sed 's/(/9/g' |sed 's/)/0/g')
					rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
				else
					read fixid
				fi				
				
				if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
					echo $fixid | grep -Eq "^[0-9A-Za-z]{1,50}"
				else
					echo $fixid | grep -Eq "^[0-9A-Za-z]{${Length}}+$"
				fi
				
				if [ $? != 0 ] ; then
					Process 1 "Invalid FIXID: $fixid"
					printf "%-10s%-60s\n" "" "Try again ... "
					echo
					continue	
				else
					break		
				fi			
			done
		;;
		
		D|d)
			Length=''
			#D: no-limited,auto input HDD SN
			if [ "$BootDiskSN"x == ""x ] ; then
				# Get the main Disk Label
				BootDiskUUID=$(cat /etc/fstab |grep -iw "uuid" | awk '{print $1}'| sed -n 1p |cut -c 6-100)
				BootDiskVol=$(blkid | grep -iw "${BootDiskUUID}" | awk '{print $1}'| sed -n 1p | awk '{print $1}' | tr -d ': ')	
				BootDiskVol=$( echo $BootDiskVol | cut -c 1-$((${#BootDiskVol}-1))) 
				BootDiskSN=$(hdparm -I $BootDiskVol 2>/dev/null | grep "Serial Number" 2>/dev/null | awk '{print $3}') 
			else
				#fixid=$(echo $BootDiskSN | tr -d "[[:punct:]]" | tr -d ' ')
				fixid=$(echo $BootDiskSN | tr -d ' ')
			fi
	 
			BootDiskSN=${BootDiskSN:-"NoSerialNumber"}
			fixid=$(echo $BootDiskSN | tr -d ' ')
	 
			if [ ${#fixid} == 12 ] ; then
				fixid=$(echo "SSD-$fixid")
			fi 

			while :
			do 
				PrintfTip "Fixture number will be auto inputed, eg.: SSD-E5A5567AFDSX" 2>/dev/null
				echo -e "Auto input \033[31mHDD/SSD\033[0m serial number: $fixid"
				echo $fixid | grep -q '[0-9A-Za-z]'
				if [ $? != 0 ] ; then
					Process 1 "Invalid FIXID: $fixid"
					printf "%-10s%-60s\n" "" "Try again ... "
					echo
					FormatType=B
					continue 2
				else
					break
				fi		
			done 
		;;
		
		*)
			Process 1 "Invalid parameter: ${FormatType}"
			exit 3
		;;
		esac
		
		#Save the Fixture ID
		fixid=$(echo $fixid |cut -c 1-${Length}| tr [a-z] [A-Z])
		echo "$fixid" > $SavePath/FIXID.TXT
		echo "$fixid" >> FIXID.ini
		sync;sync;sync
		if [ $(cat "${SavePath}/FIXID.TXT" | grep -iEc "[0-9A-Z]") != 0 ] || [ $(cat "./FIXID.ini" | grep -iEc "[0-9A-Z]") != 0 ] ; then
			echoPass "FIXID: $fixid, write to: $SavePath/FIXID.TXT"
			break
		else
			echoFail "Invalid file: $SavePath/FIXID.TXT or ./FIXID.ini"
			echo "Try again ... "
			echo
		fi
	done
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile Length SavePath FormatType
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
			printf "%-s\n" "SerialTest,ScanFixID"
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

