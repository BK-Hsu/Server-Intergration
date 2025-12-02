#!/bin/bash
#FileName : ScanOPID.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.2"
	local CreatedDate="2018-07-10"
	local UpdatedDate="2020-10-30"
	local Description="Scan OP ID and save in file OPID.TXT"
	
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
	printf "%16s%-s\n" "" "2020-10-15,Add the tool: scanner for forbidden keyboard input"
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
		0 : OP ID scan pass
		1 : OP ID scan fail
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
			
			<!-- ScanOPID.sh: Length=0表示no limited -->
			<Length>8</Length>
			<SavePath>/TestAP/PPID</SavePath>
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

	EOS=$(echo $SavePath | tr -d ' ' | awk -F'/' '{print $NF}')
	if [ ${#EOS} == 0 ] ; then
		let CutLength=${#SavePath}-1
		SavePath=$(echo $SavePath | tr -d ' ' | cut -c 1-${CutLength} )
	else
		SavePath=$(echo $SavePath | tr -d ' ')
	fi

	if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
		Length=''
		# Show length on screem
		sLength='No-limited'
	else
		sLength=${Length}
	fi

	if [ -s "OPID.ini" ] && [ ${#pcb} -gt 0 ] && [ $(($(cat OPID.ini 2>/dev/null | wc -l )%${ScanCycle})) != 0 ] && [ "${ScanCycle}" != 1 ] ; then
		opid=$(cat OPID.ini 2>/dev/null | grep -iE "[0-9A-Z]" | tail -n1 | cut -c 1-$Length )
		echo "$opid" > $SavePath/OPID.TXT
		echo "$opid" >> OPID.ini
		sync;sync;sync
		echoPass "OPID: $opid, read from: $WorkPath/OPID.ini"
	else
		while :
		do
			BeepRemind 0
			PrintfTip "Please scan ${sLength}-bit Operater number, eg.: 00188886, 80168168" 2>/dev/null
			echo -ne "Scan \033[31m${sLength}-bit\033[0m Operater number: ________\b\b\b\b\b\b\b\b" 
			which scanner >/dev/null 2>&1
			if [ $? == 0 ] ; then
				rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
				scanner ${WorkPath}/scan_${BaseName}.txt || continue
				read opid<${WorkPath}/scan_${BaseName}.txt
				rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
			else
				read opid
			fi		
			
			if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
				echo $opid | grep -E "^[0-9A-Za-z]{1,50}" | grep -vq "00188886\|80168168"
			else
				echo $opid | grep -E "^[0-9]{${Length}}+$" | grep -vq "00188886\|80168168"
			fi
		
			if [ $? != 0 ]; then
				Process 1 "Invalid OPID: $opid"
				printf "%-10s%-60s\n" "" "Try again ... "
				echo
				continue	
			fi

			opid=$(echo $opid | cut -c 1-${Length} | tr [a-z] [A-Z])
			echo "$opid" > $SavePath/OPID.TXT
			echo "$opid" >> OPID.ini
			sync;sync;sync
			if [ $(cat "${SavePath}/OPID.TXT" | grep -iEc "[0-9A-Z]") != 0 ] || [ $(cat "./OPID.ini" | grep -iEc "[0-9A-Z]") != 0 ] ; then
				echoPass "OPID: $opid, write to: $SavePath/OPID.TXT"
				break
			else
				echoFail "Invalid file: $SavePath/OPID.TXT or ./OPID.ini"
				echo "Try again ... "
				echo
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
declare XmlConfigFile Length SavePath
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
			printf "%-s\n" "SerialTest,ScanOPID"
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

