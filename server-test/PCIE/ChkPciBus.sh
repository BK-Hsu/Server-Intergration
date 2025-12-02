#!/bin/bash
#FileName : ChkPCIBus.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.0"
	local CreatedDate="2018-12-21"
	local UpdatedDate="2020-07-06"
	local Description="Compare all the PCIE/PCI device on system"
	
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
	printf "%16s%-s\n" "" "2020-07-06,優化Show方式,新增不限制PCI(E)卡功能"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [-x lConfig.xml] [-DVm]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	eg.: `basename $0` -m
	
	-D : Dump the sample xml config file
	-m : Make the config file, pass word is need,please connect Cody
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Check pci(e) devices pass
		1 : Check pci(e) devices fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<PCIE>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS1T|PCIe function fail</ErrorCode>
			<!--ErrorCode>TXS2H|PCI TEST FAIL</ErrorCode-->	
			<!--此程式和上述有區別，無PCB Marking-->
			<!--CheckPciBus.sh: 主板所有的PCIE設備校驗-->
			<!--	Vendor填寫 Unlimited 則不限定VenderID -->
			<!--	PCIE BusID|VerndorID|Speed|Width|Stepping -->			
			<Case index="1">
				<Card>01:00.0|8086:1e25|5GT/s|x4|09</Card>
				<Card>0b:00.0|8086:1f25|5GT/s|x4|09</Card>
				<Card>0c:00.0|8086:1e27|5GT/s|x4|09</Card>
			</Case>

			<Case index="2">
				<Card>01:00.0|8086:1e25|5GT/s|x4|09</Card>
				<Card>0b:00.0|8086:1f25|5GT/s|x4|09</Card>
				<Card>0c:00.0|8086:1e27|5GT/s|x4|09</Card>
			</Case>
		</TestCase>			
	</PCIE>
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
	TotalCase=($(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/Case/@index" -n "${XmlConfigFile}" 2>/dev/null))
	if [ ${#TotalCase[@]} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

DetectBusError ()
{
	ErrorMsg=$(dmesg | grep -i "pcie"| grep -iw "error")
	ErrMsg=$(dmesg | grep -i "pcie"| grep -iw "err")
	# Check dmesg info,detect it while power on OS

	if [ -n "${ErrorMsg}" ] || [ -n "${ErrMsg}" ] ; then
		ShowMsg --1 "Detect PCIE bus error message information"
		echo "----------------------------------------------------------------------"
		dmesg | grep -i "pcie"| grep -i "err" | head -n8
		echo "----------------------------------------------------------------------"
		exit 4
	fi
}

GetOSversion()
{
	kernelver=$(uname -r |cut -c 1)
}
ListAllExternalPcieCard ()
{
	Card[2]="8086:1521|8|S038C"
	Card[3]="8086:1522|8|S038D"
	Card[0]="8086:1521|4|S038A"
	Card[1]="8086:1522|4|S038B"
	Card[4]="8086:1572|4|S038E"
	Card[5]="null:null|1|S038F"
	Card[6]="null:null|1|S038G"
	Card[7]="1fc8:09.0|2|TL584-0A"
	Card[8]="10b5:8747|1|TL584-0B"
	Card[9]="126f:2260|1|M.2-128GB"
	Card[10]="144d:a802|1|M.2-256GB"
	Card[11]="8086:4229|1|INTEL-WiFi"
	Card[12]="10ee:20121|1|SobolCard"
	Card[13]="8086:1533|3|S140A-1.0"
	Card[13]="8086:1533|2|S140B"
	Card[14]="1b21:1182|3|S140A-2.1"
	Card[15]="168c:0030|1|S141-WiFi"
	Card[16]="8086:0953|1|IntelPCIESSD-400GB"
	Card[17]="168c:0033|1|S1581-WiFiCard"
	Card[18]="1000:0097|1|S101B-IR"
	Card[19]="1000:005f|1|S101B-IMR"
	Card[20]="144d:a80.|1|M.2-256GB"

	R=0
	for ((r=0;r<${#Card[@]};r++))
	do
		CardAmount=0
		LocalBusID=$(echo ${Card[$r]}| awk -F'|' '{print $1}')
		LineCnt=$(echo ${Card[$r]}| awk -F'|' '{print $2}')
		CardName=$(echo ${Card[$r]}| awk -F'|' '{print $3}')
		
		CurLineCnt=$(lspci -n 2>/dev/null | grep -c "$LocalBusID")
		let Mod=${CurLineCnt}%${LineCnt}
		let CardAmount=${CurLineCnt}/${LineCnt}
		if [ $Mod == 0 ] && [ ${CardAmount} != 0 ] ; then
			let R++
		
			[ ${R} != 0 ] && echo "----------------------------------------------------------------------"
			# [ 1 ]Found 3 Pcs TL584-0A Card: 
			echo "[ $R ] Found $CardName  $CardAmount Pcs"
			echo
			lspci -n 2>/dev/null | grep -w "$LocalBusID" | grep -w 'rev' |  while read LINE 
			do
				echo -e "\t $LINE"
			done
		fi

	done 

	[ ${CardAmount} != 0 ] && echo "----------------------------------------------------------------------"
	if [ ${R} == 0 ] ; then
		ShowMsg --1 "No found any external PCIE cards on this system"
		return 0
	fi 
	return 1
}

MakeStandardConfigeFile ()
{
	ListAllExternalPcieCard
	if [ $? != 0 ] ; then
		ShowMsg --1 "Remove all external PCIE devices firstly"
		read -p "Press [Q/q] to exit , other key to make anyway ..." -n1 OpReply
		OpReply=${OpReply:-'y'}
		echo 
		
		case ${OpReply} in
		Q|q)exit 4;;
		*)
			:
		;;
		esac
		
	fi

	# Input correct PassWord to make standard config file
	while :
	do
		echo -e "\033[1m--Input the correct password,make standard config file!--\033[0m"
		read -p "Please input password: " -s psw
		pswmd5=$(echo -n $psw  | md5sum |cut -c 1-32)
		echo ''
		if [ "$pswmd5"x == "$PassWord"x  ]; then
			echo "Standard config file is making,please wait ..."
			break
		else				
			echo -e "\033[0;31m--Incorrect password.Please try again!--\033[0m"
		fi
	done


	<<-LSPCI
	00:00.0 Host bridge: Intel Corporation 440BX/ZX/DX - 82443BX/ZX/DX Host bridge (rev 01)
	00:01.0 PCI bridge: Intel Corporation 440BX/ZX/DX - 82443BX/ZX/DX AGP bridge (rev 01)
	00:07.0 ISA bridge: Intel Corporation 82371AB/EB/MB PIIX4 ISA (rev 08)

	01:00.0|8086:1e25|5GT/s|x4|09
	0b:00.0|8086:1f25|5GT/s|x4|09
	0c:00.0|8086:1e27|5GT/s|x4|09
	LSPCI

	rm -rf ${BaseName}.ini 2>/dev/null
	rm -rf ${BaseName}.xml 2>/dev/null
	lspci 2>/dev/null | while read EachDevice
	do

		BusID=$(echo ${EachDevice} | awk '{print $1}')
		VendorID=$(lspci -n -s $BusID  2>/dev/null | awk '{print $3}')
		
		Stepping=$(lspci -n -s $BusID  2>/dev/null | awk '{print $5}' | tr -d [[:punct:]])
		Stepping=${Stepping:-NULL}
		
		if [ $kernelver -gt "3" ];then
			Speed=$(lspci -n -s $BusID -vvv 2>/dev/null | awk '/LnkSta:/{print substr($3, 1, length($3))}')
			Speed=${Speed:-NULL}
		
			Width=$(lspci -n -s $BusID -vvv 2>/dev/null | awk '/LnkSta:/{print substr($6, 1, length($6))}')
			Width=${Width:-NULL}
		else
			Speed=$(lspci -n -s $BusID -vvv 2>/dev/null | awk '/LnkSta:/{print substr($3, 1, length($3)-1)}')
			Speed=${Speed:-NULL}
		
			Width=$(lspci -n -s $BusID -vvv 2>/dev/null | awk '/LnkSta:/{print substr($5, 1, length($5)-1)}')
			Width=${Width:-NULL}
		fi
		
		# ${BaseName}.ini,format as:  01:00.0|8086:1e25|5GT/s|x4|09
		# Create ini config file
		
		echo "${BusID}|${VendorID}|${Speed}|${Width}|${Stepping}" >>${BaseName}.ini
		sync;sync;sync
		
		# Create xml config file
		echo "<Card>${BusID}|${VendorID}|${Speed}|${Width}|${Stepping}</Card>" >>Sub_${BaseName}.xml
		sync;sync;sync
		
	done
	echo

	echoPass "Create Sub_${BaseName}.xml"
	exit 4
}

CheckPci()
{
	local index=$1
	local PcieArg=$2
	local SubErrorFlag=0

	let D=${index}+1
	D=$(printf "%02d" ${D})

	# PcieBus:Dev.Fun ID of PCI Card
	PcieBus=$(echo ${PcieArg} | awk -F'|' '{print $1}')

	# PcieVendor:Device ID of PCI Card
	PcieVendor=$(echo ${PcieArg} | awk -F'|' '{print $2}')

	# PCI Express Speed of PCI-e Card 2.5GT/s
	PcieSpeed=$(echo ${PcieArg} | awk -F'|' '{print $3}' | tr [NUL] [nul])

	# PCI Express Width of PCI-e Card
	PcieWidth=$(echo ${PcieArg} | awk -F'|' '{print $4}' | tr [A-Z] [a-z])
	
	# PCI Express Width of PCI-e Card
	PcieStepping=$(echo ${PcieArg} | awk -F'|' '{print $5}' | tr [A-Z] [a-z])

	CurDevice=$(lspci -n -s ${PcieBus} | grep -F "$PcieVendor" )
	if [ ${#CurDevice} != 0 ]	; then
		if [ $kernelver -gt "3" ];then
			Speed=$(lspci -n -s $BusID -vvv 2>/dev/null | awk '/LnkSta:/{print substr($3, 1, length($3))}')
			Speed=${Speed:-NULL}
		
			Width=$(lspci -n -s $BusID -vvv 2>/dev/null | awk '/LnkSta:/{print substr($6, 1, length($6))}')
			Width=${Width:-NULL}
		else
			CurSpeed=$(lspci -n -s $PcieBus -vvv 2>/dev/null | awk '/LnkSta:/{print substr($3, 1, length($3)-1)}')
			CurSpeed=${CurSpeed:-null}
		
			CurWidth=$(lspci -n -s $PcieBus -vvv 2>/dev/null | awk '/LnkSta:/{print substr($5, 1, length($5)-1)}')
			CurWidth=${CurWidth:-null}
		fi
		CurStepping=$(lspci -n -s $PcieBus  2>/dev/null | awk '{print $5}' | tr -d [[:punct:]])
		CurStepping=${CurStepping:-null}
		
		printf "%-5s%-12s%-14s" "[$D]"  "${PcieBus}"  "${PcieVendor}"
		if [ "${CurSpeed}" == "${PcieSpeed}" ] ; then
			printf "\e[0;32m%-10s\e[0m"   "${CurSpeed}" 
		else
			printf "\e[0;31m%-10s\e[0m"   "${CurSpeed}(${PcieSpeed})" 
			let SubErrorFlag++
		fi

		if [ "${CurWidth}" == "${PcieWidth}" ] ; then
			printf "\e[0;32m%-9s\e[0m"   "${CurWidth}" 
		else
			printf "\e[0;31m%-9s\e[0m"   "${CurWidth}(${PcieWidth})" 
			let SubErrorFlag++
		fi
		
		if [ "${CurStepping}" == "${PcieStepping}" ] ; then
			printf "\e[0;32m%-11s\e[0m"   "${CurStepping}" 
		else
			printf "\e[0;31m%-11s\e[0m"   "${CurStepping}(${PcieStepping})" 
			let SubErrorFlag++
		fi		
		
		if [ ${SubErrorFlag} == "0" ]; then
			printf "\e[0;32m%-5s\n\e[0m"  "Pass" 
			return 0
		else
			printf "\e[0;31m%-5s\n\e[0m"  "Fail" 
			return 1
		fi
		
	else
		printf "\e[1;31m%-5s%-12s%-14s%-10s%-9s%-11s%-5s\n\e[0m" "[$D]"  "${PcieBus}"  "${PcieVendor}"  "Error"  "Error"  "Error"  "(No found)"   
		return 1
	fi
}

ArrayMin()
{
	local List=($(echo $@))
	MinValue=${List[0]}
	MinIndex=0
	for((i=0;i<${#List[@]};i++))
	do
		if [ ${List[$i]} -lt ${MinValue} ] ; then
			MinValue=${List[$i]}
			MinIndex=$i
		fi
	done
	printf "%s\n" "${MinIndex} ${MinValue}"
}

main()
{
	DetectBusError	
	GetOSversion
	for ((f=0;f<${#TotalCase[@]};f++))
	do
		ErrorFlag=0
		PCIEDevice=()
		PCIEDevice=($(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/Case[@index=\"${TotalCase[$f]}\"]/Card" -n "${XmlConfigFile}" 2>/dev/null | grep -v "^#" | grep -v "^$" ))

		for((d=0;d<${#PCIEDevice[@]};d++))
		do
			CheckPci $d "${PCIEDevice[$d]}" >/dev/null 2>&1
			[ $? != 0 ] && let ErrorFlag++
		done

		PassCase[$f]=${ErrorFlag}
		if [ ${ErrorFlag} == 0 ] ; then
			break
		fi
	done
	
	MinIndex=($(ArrayMin "${PassCase[@]}"))
	
	<<-SHOW
	No.   BusID       Vendor       Speed          Width   Stepping  Result?   
	----------------------------------------------------------------------
	[01] 02:00.0     1fc8:0920     5GT/s           x16        03      Pass
	[02] 05:00.0     1fc8:0900     5GT/s(2.5GT/s)  x8         09      Fail
	[03] 05:00.0     1fc8:0900     5GT/s(2.5GT/s)  x8(x16)    09      Fail
	----------------------------------------------------------------------
	SHOW

	PCIEDevice=()
	PCIEDevice=($(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/Case[@index=\"${TotalCase[${MinIndex[0]}]}\"]/Card" -n "${XmlConfigFile}" 2>/dev/null | grep -v "^#" | grep -v "^$" ))

	ShowTitle "PCI/PCIe devices on board funtion test in linux"
	printf "%-6s%-12s%-13s%-10s%-8s%-11s%-6s\n" " No."   "BusID"  "Vendor"    "Speed"   "Width"   "Stepping"  "Result?"   
	echo "-----------------------------------------------------------------------"
		for((d=0;d<${#PCIEDevice[@]};d++))
		do
			CheckPci $d "${PCIEDevice[$d]}"
			[ $? != 0 ] && let ErrorFlag++
		done	
	echo "-----------------------------------------------------------------------"
	
	if [ ${ErrorFlag}x != "0x" ] ; then
		echoFail "PCI/PCIe devices on board detection"
		GenerateErrorCode
		exit 1
	else
		echoPass "PCI/PCIe devices on board detection"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -a PassCase=()
declare PassWord='abcf314e470e139bf3c06c859761d560'
declare XmlConfigFile 
declare BusID VendorID Speed Width PCIEDevice ApVersion kernelver
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:mVDx: argv
do
	 case ${argv} in
		m)
			MakeStandardConfigeFile
		;;
			
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
			printf "%-s\n" "SerialTest,CheckPCIBus"
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
