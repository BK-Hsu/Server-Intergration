#!/bin/bash
#FileName : ChkPCIe.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.3"
	local CreatedDate="2018-06-08"
	local UpdatedDate="2020-11-18"
	local Description="Compare the width and speed of PCIE device"
	
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
	printf "%16s%-s\n" "" "2020-06-11,當VendorID設定為 Unlimited 的時候，則不再限制使用哪種配備測試"
	printf "%16s%-s\n" "" "2020-07-15,優化Show方式,新增不限制PCI/PCIE卡功能"
	printf "%16s%-s\n" "" "2020-11-18,新增按數量測試,參數有效性檢查"
	printf "%16s%-s\n" "" "2023-02-22,kernel5 侦测width和speed的方式变更调整，同时针对PCIe报错的侦测方式进行调整"
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
	ExtCmmds=(xmlstarlet lspci dmesg)
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
	VersionInfo "getVersion"
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
`basename $0` [-x lConfig.xml] [-DVl]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	eg.: `basename $0` -l
	
	-D : Dump the sample xml config file
	-l : List all PCIE test card	,eg.: TL584,WiFi,card
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Check pcie card pass
		1 : Check pcie card fail
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
		<!-- 支持多個配置檔測試（多種情形）-->
		<!--	Bus, Dev.Fun ID of PCI Card -->
		<!--	Vendor, Device ID of PCI Card -->
		<!--	PCI Express Speed of PCI-e Card -->
		<!--	PCI Express Width of PCI-e Card -->
		<!--	PCI-E_Num|Bus|Vendor|Speed|Width -->
		<!--	Vendor填寫 Unlimited 則不限定VenderID -->
		<!--按位置測試: Location|BusID|VendorID|Speed|Width-->
		<!--按數量測試: EquipmentName|Amount|VendorID|Speed|Width-->
		<!--依據下面的索引值填寫，index索引不能重複，否則不能正確的檢索到-->
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS1T|PCIe function fail</ErrorCode>				
			<Case index="1">
				<Card>PCI_E1|01:00.0|Unlimited|5GT/s|x16</Card>
				<Card>PCI_E2|03:00.0|1fc8:09.0|5GT/s|x16</Card>
				<Card>PCI_E3|08:00.0|8086:1533|2.5GT/s|x1</Card>
				<Card>PCI_E4|0b:00.0|1fc8:0900|5GT/s|x4</Card>
			</Case>
			
			<Case index="2">
				<Card>PCI_E1A|01:00.0|1fc8:09.0|5GT/s|x16</Card>
				<Card>PCI_E2A|03:00.0|1fc8:09.0|5GT/s|x16</Card>
				<Card>PCI_E3A|08:00.0|8086:1533|2.5GT/s|x1</Card>
				<Card>PCI_E4A|0b:00.0|1fc8:0900|5GT/s|x4</Card>
			</Case>	
			
						
			<Case index="3">
				<Card>TL-584-0A|3PCS|1fc8:09.0|5GT/s|x16</Card>
				<Card>M.2-256GB|1PCS|144d:a80.|5GT/s|x4</Card>
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
	
	local PcieCardsAmount=0
	local GetPcieCardsAmount='enable'
	local DisplayPcieCardsAmount='enable'
	
	for ((r=0;r<${#TotalCase[@]};r++))
	do
		local AllCards=()
		AllCards=($(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/Case[@index=\"${TotalCase[r]}\"]/Card" -n "${XmlConfigFile}" 2>/dev/null | tr -d ' ' | grep -v "^#" | grep -v "^$" ))
		if [ ${#AllCards[@]} == 0 ] ; then
			let ErrorFlag++
			Process 1 "Error Case: ${TotalCase[r]}"
			continue
		fi
		
		#每個Case不能包含重複的信息
		echo ${AllCards[@]} | tr ' ' '\n' | awk -F'|' '{print $2$3$4$5}' | sort -u | grep -iEc "[0-9A-Z]" | grep -iwq "${#AllCards[@]}"
		if [ $? != 0 ] ; then
			let ErrorFlag++
			Process 1 "Duplicate setting found in Case=${TotalCase[r]}"
			printf "\n\e[31m%s\e[0m\n" "`echo ${AllCards[@]} | tr ' ' '\n' | awk -F'|' -v char="|" '{print $2 char $3 char $4 char $5}' |  sort -s | uniq -c | awk '$1=$1' | sort -r | grep -vw "^1" | sed "s/ / lines:  /g"`" 
 			continue
		fi
		
		#每個Case數量應該是相等的
		local TestMode=$(echo "${AllCards[@]}" | tr " " '\n' | awk -F'|' '{print $2}' | grep -iwEc '[0-9]{1,3}PCS')
		case ${TestMode} in
			0)
				#BusID
				if [ "${GetPcieCardsAmount}" == 'enable' ] ; then
					PcieCardsAmount=${#AllCards[@]}
					GetPcieCardsAmount='disable'
				else
					if [ ${PcieCardsAmount} != ${#AllCards[@]} ] ; then
						let ErrorFlag++
						Process 1 "Different amount of PCIe cards in Case=${TotalCase[r]}: ${#AllCards[@]}PCS ..."
					fi
				fi
				
			;;
			
			"${#AllCards[@]}")
				#Amount
				if [ "${GetPcieCardsAmount}" == 'enable' ] ; then
					PcieCardsAmount=$(echo ${AllCards[@]} | tr ' ' '\n' | awk -F'|' '{print $2}' | tr -d '[a-zA-Z]' | awk '{sum+=$1}END{print sum}' )
					GetPcieCardsAmount='disable'
				else
					if [ ${PcieCardsAmount} != $(echo ${AllCards[@]} | tr ' ' '\n' | awk -F'|' '{print $2}' | tr -d '[a-zA-Z]' | awk '{sum+=$1}END{print sum}' ) ] ; then
						let ErrorFlag++
						Process 1 "Different amount of PCIe cards in Case=${TotalCase[r]}: $(echo ${AllCards[@]} | tr ' ' '\n' | awk -F'|' '{print $2}' | tr -d '[a-zA-Z]' | awk '{sum+=$1}END{print sum}' )PCS ..."
					fi					
				fi
			;;
			
			*)
				Process 1 "Error Case: ${TotalCase[r]}. 數量和位置不能混合設置..."
				let ErrorFlag++
			;;
			esac
			if [ "${GetPcieCardsAmount}" == 'disable' ] && [ ${DisplayPcieCardsAmount} == 'enable' ] ; then
				printf "\e[1;33m%s\e[0m\n" "本程式将測試 ${PcieCardsAmount} PCS PCIe slots..."
				DisplayPcieCardsAmount='disable'
			fi
	done
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0
}

DetectBusError ()
{
	#ErrorMsg=$(dmesg | grep -i "pcie"| grep -iw "error")
	#ErrMsg=$(dmesg | grep -i "pcie"| grep -iw "err")
	Errflag=("err" "error")
	# Check dmesg info,detect it while power on OS
	for((i=0;i<${#Errflag[@]};i++))
	do	
		dmesg | grep -i "pcie" | grep -iwq "${Errflag[i]}" 
		if [ $? == 0 ] ; then
			dmesg |grep -i "hardware" | grep -iB10 "pcie" | grep -iwB10 "${Errflag[i]}" | grep -iwq "been corrected"
			if [ $? != 0 ] ; then
				ShowMsg --1 "Detect PCIE bus error message information"
				echo "----------------------------------------------------------------------"
				dmesg | grep -i "pcie"| grep -iw "err\|error" | head -n8
				echo "----------------------------------------------------------------------"
				exit 4
			fi
		fi
	done
	#if [ -n "${ErrorMsg}" ] || [ -n "${ErrMsg}" ] ; then
	#	ShowMsg --1 "Detect PCIE bus error message information"
	#	echo "----------------------------------------------------------------------"
	#	dmesg | grep -i "pcie"| grep -iw "err\|error" | head -n8
	#	echo "----------------------------------------------------------------------"
	#	exit 4
	#fi
}

GetOsversion()
{

	kernelver=$(uname -r |cut -c 1)
}

CheckPcie ()
{
	local PcieArg=$1
	local SubFlag=0
	# Usage: CheckPcie "PCI_E1|01:00.0|1fc8:09.0|5GT/s|x16"
	# PcieArg="PCI_E1|01:00.0|1fc8:09.0|5GT/s|x16"

	# PcieMark:The Name of PCIE Slot
	PcieMark=$(echo ${PcieArg}| awk -F'|' '{print $1}')

	# PcieBus:Dev.Fun ID of PCI Card
	PcieBus=$(echo ${PcieArg} | awk -F'|' '{print $2}')

	# PcieVendor:Device ID of PCI Card
	PcieVendor=$(echo ${PcieArg} | awk -F'|' '{print $3}' | tr '[A-Z]' '[a-z]')

	# PCI Express Speed of PCI-e Card 2.5GT/s
	PcieSpeed=$(echo ${PcieArg} | awk -F'|' '{print $4}')

	# PCI Express Width of PCI-e Card
	PcieWidth=$(echo ${PcieArg} | awk -F'|' '{print $5}')
	while :
	do
		# Check PCI card
		echo "${PcieVendor}" | grep -iwq "Unlimited"
		if [ $? == 0 ] ; then
			PcieVendor=$(lspci -n  2>/dev/null | grep -w "${PcieBus}" | awk '{print $3}' | head -n1)
		else
			PcieVendor=$(lspci -n  2>/dev/null | grep -w "${PcieBus}" | grep -wE "$PcieVendor" | awk '{print $3}' | head -n1)    
		fi

		if [ "${#PcieVendor}" == 0 ]; then
			SubFlag=50
			break
		fi  		
		
		# Check PCI Express speed
		if [ $kernelver -gt "3" ];then
			CurSpeed=$(lspci -n -s $PcieBus -vvv | awk '/LnkSta:/{print substr($3, 1, length($3))}')
			if [ "$CurSpeed"x != "$PcieSpeed"x ]; then
				let SubFlag=1
			fi

			# Check PCI Express width
			CurWidth=$(lspci -n -s $PcieBus -vvv | awk '/LnkSta:/{print substr($6, 1, length($6))}')
			if [ "$CurWidth"x != "$PcieWidth"x ]; then
				let SubFlag=2
			fi
		else
			CurSpeed=$(lspci -n -s $PcieBus -vvv | awk '/LnkSta:/{print substr($3, 1, length($3)-1)}')
			if [ "$CurSpeed"x != "$PcieSpeed"x ]; then
				let SubFlag=1
			fi

			# Check PCI Express width
			CurWidth=$(lspci -n -s $PcieBus -vvv | awk '/LnkSta:/{print substr($5, 1, length($5)-1)}')
			if [ "$CurWidth"x != "$PcieWidth"x ]; then
				let SubFlag=2
			fi
		fi

		
		break
		
	done

	if [ "$SubFlag" == "50" ] ; then
		PcieVendor=$(lspci -n  2>/dev/null | grep -w "${PcieBus}" | awk '{print $3}' | head -n1)

		printf "%-17s%-9s\e[1;31m%-12s\e[0m%-10s%-9s%-9s%-4s\n" "${PcieMark}" "${PcieBus}" "${PcieVendor:-NULL}" "NULL" "${PcieSpeed}" "NULL" "${PcieWidth}"
		return 2
	fi

	if [ "$SubFlag" != "0" ] ; then
		if [ "$SubFlag" == "1" ] ; then
			printf "%-17s%-9s%-12s\e[1;31m%-10s\e[0m%-9s%-9s%-4s\n" "${PcieMark}" "${PcieBus}" "${PcieVendor:-NULL}" "${CurSpeed}" "${PcieSpeed}" "${CurWidth}" "${PcieWidth}"
		else
			printf "%-17s%-9s%-12s%-10s%-9s\e[1;31m%-9s\e[0m%-4s\n" "${PcieMark}" "${PcieBus}" "${PcieVendor:-NULL}" "${CurSpeed}" "${PcieSpeed}" "${CurWidth}" "${PcieWidth}"
		fi
		return 1
	fi


	if [ "$SubFlag" == "0" ] &&  [ "$CurWidth"x != ""x ] &&  [ "$CurSpeed"x != ""x ] ; then
		printf "%-17s%-9s%-12s\e[32m%-10s\e[0m%-9s\e[32m%-9s\e[0m%-4s\n" "${PcieMark}" "${PcieBus}" "${PcieVendor:-NULL}" "${CurSpeed}" "${PcieSpeed}" "${CurWidth}" "${PcieWidth}"
		return 0
	fi
}

CheckPcieAmount()
{
	local PcieArg=$1 #TL-584-0A|4PCS|1fc8:09.0|5GT/s|x16
	local Location=$(echo "${PcieArg}" | awk -F'|' '{print $1}' )
	local Number=$(echo "${PcieArg}" | awk -F'|' '{print $2}' | tr -d "[A-Za-z]" )
	local Unit=$(echo "${PcieArg}" | awk -F'|' '{print $2}' | tr -d "[0-9]" )
	local VenderID=$(echo "${PcieArg}" | awk -F'|' '{print $3}' )
	local StdSpeed=$(echo "${PcieArg}" | awk -F'|' '{print $4}' )
	local StdWidth=$(echo "${PcieArg}" | awk -F'|' '{print $5}' )
	
	local CurAmount=0
	local SubFlag=0
	
	AllDevicesAmount=$(lspci -n 2>/dev/null | grep -iwEc "${VenderID}" )

	for((i=1;i<=${AllDevicesAmount};i++))
	do
		#Bus:Dev.Fun  VID:DID    Width   Speed   Revision
		DeviceInfo=$(lspci -n 2>/dev/null | grep -iwE "${VenderID}" | sed -n ${i}p)
		Bus=$(echo "${DeviceInfo}" | awk '{print $1}'| awk -F":" '{print $1}')
		Dev=$(echo "${DeviceInfo}" | awk '{print $1}'| awk -F":" '{print $2}'| awk -F"." '{print $1}')
		Fun=$(echo "${DeviceInfo}" | awk '{print $1}'| awk -F":" '{print $2}'| awk -F"." '{print $2}')
		VID=$(echo "${DeviceInfo}" | awk '{print $3}'| awk -F":" '{print $1}')
		DID=$(echo "${DeviceInfo}" | awk '{print $3}'| awk -F":" '{print $2}')
		REV=$(echo "${DeviceInfo}" | awk '{print $5}'| tr -d ")")
		
		#CurSpeed=$(lspci -n -s "${Bus}:${Dev}.${Fun}" -vvv  2>/dev/null | awk '/LnkSta:/{print substr($3, 1, length($3)-1)}')
		#CurWidth=$(lspci -n -s "${Bus}:${Dev}.${Fun}" -vvv  2>/dev/null | awk '/LnkSta:/{print substr($5, 1, length($5)-1)}')
		SpeedWidth=($(lspci -n -s "${Bus}:${Dev}.${Fun}" -vvv 2>/dev/null | grep -w "LnkSta:" | awk '{print $3 $5}' | tr ',' ' '))
		CurSpeed=${SpeedWidth[0]}
		CurWidth=${SpeedWidth[1]}
		
		echo "${CurWidth}${CurSpeed}" | grep -iwq "${StdWidth}${StdSpeed}"
		if [ $? == 0 ]; then
			let CurAmount++	
		fi
	done
	
	printf "%-16s%-16s%-11s%-10s%-10s" "${Location}" "${VenderID}" "${StdSpeed}" "${StdWidth}" "${Number} ${Unit}"
	if [ "${Number}"x != "${CurAmount}"x ] ; then
		printf "\e[1;31m%-7s\e[0m\n" "${CurAmount} ${Unit}"
		return 1
	else
		printf "%-7s\n" "${CurAmount} ${Unit}"
		return 0
	fi
}

ListAllPcieCard ()
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
		ShowMsg --1 "No found any PCIE cards on this system"
	fi 
	exit 5
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
	GetOsversion
	# For a variety of situations
	for ((f=0;f<${#TotalCase[@]};f++))
	do
		if [ ${f} == 0 ] ; then
			printf "%s" "Checking the PCIE device(s), please wait ."
		fi
		ErrorFlag=0	
		AllCards=()
		AllCards=($(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/Case[@index=\"${TotalCase[$f]}\"]/Card" -n "${XmlConfigFile}" 2>/dev/null | tr -d ' ' | grep -v "^#" | grep -v "^$" ))
		if [ ${#AllCards[@]} == 0 ] ; then
			let ErrorFlag++
			PassCase[$f]="9999"
			Process 1 "Error Case: ${TotalCase[$f]}"
			continue
		fi
		
		#判定按數量還是位置測試
		TestMode=$(echo "${AllCards[@]}" | tr " " '\n' | awk -F'|' '{print $2}' | grep -iwEc '[0-9]{1,3}PCS')
		case ${TestMode} in
		0)
			#busID
			for ((c=0;c<${#AllCards[@]};c++))
			do
				printf "%s" "."
				CheckPcie "${AllCards[$c]}" >/dev/null 2>&1
				[ $? != 0 ] && let ErrorFlag++
			done
		;;
		
		"${#AllCards[@]}")
			#Amount
			for ((c=0;c<${#AllCards[@]};c++))
			do
				printf "%s" "."
				CheckPcieAmount "${AllCards[$c]}" >/dev/null 2>&1
				[ $? != 0 ] && let ErrorFlag++
			done
		;;
		
		*)
			let ErrorFlag++
			PassCase[$f]="9999"
			Process 1 "Error Case: ${TotalCase[$f]}. 數量和位置不能混合設置..."
			continue
		;;
		esac
		
		PassCase[$f]=${ErrorFlag}
		# It test pass in a situations,then skip the other case
		if [ ${ErrorFlag} == 0 ] ; then
			break
		fi
		
	done
	echo

	MinIndex=($(ArrayMin "${PassCase[@]}"))
	AllCards=()
	AllCards=($(xmlstarlet sel -t -v "//PCIE/TestCase[ProgramName=\"${BaseName}\"]/Case[@index=\"${TotalCase[${MinIndex[0]}]}\"]/Card" -n "${XmlConfigFile}" 2>/dev/null | tr -d ' ' | grep -v "^#" | grep -v "^$" ))

	#按位置測試
	#PcbMark       BusID   VendorID    CurSpd    StdSpd  CurWth  StdWth    
	#----------------------------------------------------------------------
	#OCULINK1     b0:00.0  8086:0953   NULL      8GT/s    NULL     x4      
	#OCULINK2     b1:00.0  8086:0953   8GT/s     8GT/s    x4       x4      
	#OCULINK3     d8:00.0  8086:0953   8GT/s     8GT/s    x4       x4      
	#OCULINK4     d9:00.0  8086:0953   8GT/s     8GT/s    x4       x4      
	#M2_1         01:00.0  144d:a802   8GT/s     8GT/s    x4       x4      
	#----------------------------------------------------------------------

	#按數量測試
	#Equiment        VendorID        Speed     Width     Expect     Actual
	#----------------------------------------------------------------------
	#U.2_P3700       8086:9566       8GT/s      x4        3Pcs       3Pcs 
	#M.2_M-key       8086:9566       8GT/s      x4        1Pcs       1Pcs
	#TL-584-0A       8086:9566       8GT/s      x4        2Pcs       1Pcs 
	#----------------------------------------------------------------------

	ShowTitle "PCIe devices detection test"

	#判定按數量還是位置測試
	TestMode=$(echo "${AllCards[@]}" | tr " " '\n' | awk -F'|' '{print $2}' | grep -iwEc '[0-9]{1,3}PCS')
	case ${TestMode} in
		0)
			#busID
			printf "%-17s%-9s%-12s%-10s%-8s%-8s%-6s\n" "Location" " BusID" "VendorID" "CurSpd" "StdSpd" "CurWth" "StdWth"
			echo "----------------------------------------------------------------------"
			for ((c=0;c<${#AllCards[@]};c++))
			do
				CheckPcie "${AllCards[$c]}"
				[ $? != 0 ] && let ErrorFlag++
			done
			echo "----------------------------------------------------------------------"	
		;;

		"${#AllCards[@]}")
			#Amount
			printf "%-16s%-16s%-10s%-10s%-10s%-11s%-6s\n" "Equiment" " VendorID" "Speed" "Width" "Expect" "Actual"
			echo "----------------------------------------------------------------------"
			for ((c=0;c<${#AllCards[@]};c++))
			do
				CheckPcieAmount "${AllCards[$c]}" 
				[ $? != 0 ] && let ErrorFlag++
			done
			echo "----------------------------------------------------------------------"
			if [ ${#pcb} != 0 ] ; then
				printf "%s\n" "PCIe devices detection detail: " >>../PPID/${pcb}.log 2>/dev/null
				VendorIDs=($(echo "${AllCards[@]}" | tr " " '\n' | awk -F'|' '{print $3}' | sort -u))
				if [ ${#VendorIDs[@]} -gt 1 ] ; then			
					VendorIDs=$(echo "${VendorIDs[@]}" | sed 's/ /\|/g' )
				fi
				lspci -n | grep -iwE "(${VendorIDs})" >>../PPID/${pcb}.log 2>/dev/null
			fi
		;;
		esac
	echo
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Some PCIe cards/devices detection check"
		GenerateErrorCode
		exit 1
	else
		echoPass "PCIe cards/devices detection check"
	fi
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -i TotalCase=()
declare -a PassCase=()
declare XmlConfigFile
declare PcbMarking BusID VendorID Speed Width ApVersion kernelver
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:lVDx: argv
do
	 case ${argv} in
		l)
			ListAllPcieCard
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
			printf "%-s\n" "SerialTest,CheckPCIeDevices"
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
