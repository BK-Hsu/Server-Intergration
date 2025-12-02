#!/bin/bash
#FileName : lan_w.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.1"
	local CreatedDate="2018-05-29"
	local UpdatedDate="2024-02-07"
	local Description="Write the LAN MAC address"
	
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
	printf "%16s%-s\n" "" "2020-12-31,支持多線程燒錄LAN MACs Address"
	printf "%16s%-s\n" "" "2024-02-07,多进程优化，同时增加在烧录完成之后reset 动作"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet ${ProgramTool})
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
`basename $0` [-[p]x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
		 `basename $0` -D
		 `basename $0` -V

	-D : Dump the sample xml config file
	-p : Enter the password to compel write eeprom again
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Write lan mac address pass
		1 : Write lan mac address fail
		2 : File is not exist
		3 : Parameters error
	    Other : Fail

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<NetCard>		
		<TestCase>
			<!--並行測試Parallel or 串行測試Serial-->
			<ProgramName  TestMode="Parallel">${BaseName}</ProgramName>
			<ErrorCode>EXF17|LAN function test fail</ErrorCode>
			<!--範例說明
				<NicIndex>1:不接任何網卡時其Nic號</NicIndex>
				<Chipset>I354</Chipset>
				<MacAddrFile>/TestAP/Scan/MAC1.TXT</MacAddrFile>
			-->

			<!-- enable: EEPROM file/MAC address can flash more than twice if necessary; disable: Only flash one time -->
			<DoubleFlash>disable</DoubleFlash>
			<Password>abcf314e470e139bf3c06c859761d560</Password>
			<!-- Define the first MAC address is ODD , Even , Un-limit --> 
			<FirstMAC>ODD</FirstMAC>

			<!--  First 6 digits of MAC address. If is 'FFFFFF', ignore to check. -->
			<First6Bit>FFFFFF</First6Bit>
						
			<Card>
				<NicIndex>1</NicIndex>
				<Chipset>I354</Chipset>
				<MacAddrFile>/TestAP/Scan/MAC1.TXT</MacAddrFile>
			</Card>

			<Card>
				<NicIndex>2</NicIndex>
				<Chipset>I354</Chipset>
				<MacAddrFile>/TestAP/Scan/MAC2.TXT</MacAddrFile>
			</Card>	
		</TestCase>
	</NetCard>
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
	MacFirst6=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/First6Bit" -n "${XmlConfigFile}" 2>/dev/null)
	FirstMacOEU=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/FirstMAC" -n "${XmlConfigFile}" 2>/dev/null)
	DoubleFlash=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/DoubleFlash" -n "${XmlConfigFile}" 2>/dev/null)
	Password=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Password" -n "${XmlConfigFile}" 2>/dev/null)

	NicIndex=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/NicIndex" -n "${XmlConfigFile}" 2>/dev/null))
	LanChipset=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/Chipset" -n "${XmlConfigFile}" 2>/dev/null))
	MacAddrFiles=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/MacAddrFile" -n "${XmlConfigFile}" 2>/dev/null))
	TotalAmount="${#NicIndex[@]}"
	TestMode=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ProgramName[.=\"${BaseName}\"]/@TestMode" -n "${XmlConfigFile}" 2>/dev/null | tr "[A-Z]" "[a-z]")
	TestMode=${TestMode:-"serial"}
	if [ ${#NicIndex} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

MacAddrFilesContrl()
{
	SoleMacAddrFiles=$(echo ${MacAddrFiles[@]} | tr ' ' '\n' | sort -u | wc -l)
	if [ $SoleMacAddrFiles != ${#MacAddrFiles[@]} ] ; then
		Process 1 "Error mac address files,some mac files are the same"
		echo "----------------------------------------------------------------------"
		echo ${MacAddrFiles[@]} | tr ' ' '\n' | sort -s | while read LINE
		do
			echo "$LINE is: `sed -n 1p $LINE`"
		done
		echo "----------------------------------------------------------------------"
		exit 3
	fi

	MacFirst6=${MacFirst6:-'FFFFFF'}
	# Check MAC Address is valid
	for ((q=0;q<${#MacAddrFiles[@]};q++))
	do
		#Confirm Mac files is exist
		if [ ! -s "${MacAddrFiles[$q]}" ] ; then
			Process 1 "No such file or 0 KB size of file: ${MacAddrFiles[$q]}"
			let ErrorFlag++
			continue
		fi
		
		# Confirmed to be hexadecimal and upper MAC Address
		MacAddr[$q]=$(cat -v ${MacAddrFiles[$q]} | tr [a-z] [A-Z] | grep -E '^[0-9A-F]{12}+$' )
		if [ -z "${MacAddr[$q]}" ] ; then
			Process 1 "${MacAddrFiles[$q]} is invalid"
			printf "%-10s%-60s\n" "" "${MacAddrFiles[$q]} is: `cat -v ${MacAddrFiles[$q]}`"
			let ErrorFlag++	
			continue
		fi
		
		# Check the mac first 6bit
		if [ $(echo "${MacFirst6}" | grep -ic 'FFFFFF' ) == 0 ] ; then
			if [ $(cat -v ${MacAddrFiles[$q]} | cut -c 1-6 | grep -ic "${MacFirst6}") != 1 ] ; then		
				Process 1 "Check the first 6bit of ${MacAddrFiles[$q]}"
				printf "%-10s%-60s\n" "" "Current first 6bit is: `cat -v ${MacAddrFiles[$q]} | cut -c 1-6`"
				printf "%-10s%-60s\n" "" " First 6bit should be: ${MacFirst6}"
				let ErrorFlag++
				continue
			fi
		fi

	done

	[ $ErrorFlag != 0 ] && exit 2

	#Check ODD/Even/Un-limit
	local FirstMacAddr=$(echo ${MacAddr[@]} | tr ' ' '\n' | sort -s | sed -n 1p )
	GetFirstMacAddrOOEU=$(echo "ibase=16; ${FirstMacAddr}%2" | bc )
	FirstMacOEU=$(echo $FirstMacOEU | tr [a-z] [A-Z])
	case $FirstMacOEU in
		ODD)
			if [ ${GetFirstMacAddrOOEU} != "1" ] ; then
				Process 1 "Check Odd or Even of first MAC address: ${FirstMacAddr},fail."
				printf "%-10s%-60s\n" "" "Current first MAC is: 0 (Even)"
				printf "%-10s%-60s\n" "" " First MAC should be: 1 (Odd)"
				exit 4			
			fi
		;;
		
		EVEN)
			if [ ${GetFirstMacAddrOOEU} != "0" ] ; then
				Process 1 "Check Odd or Even of first MAC address: ${FirstMacAddr},fail."
				printf "%-10s%-60s\n" "" "Current first MAC is: 1 (Odd)"
				printf "%-10s%-60s\n" "" " First MAC should be: 0 (Even)"
				exit 4			
			fi
		;;
		
		*)
			: #Do nothing
		;;
		esac
}

# Confirm the nic index in valid
GetNicIndexArray ()
{
	echo "${NicIndex[@]}" | tr ' ' '\n' | sort -u | wc -l | grep -iwq "${#NicIndex[@]}"
	if [ $? != 0 ] ; then
		Process 1 "Error nic index: `echo "${NicIndex[@]}" | sed 's/ /,/g'` "
		exit 3
	fi

	rm -rf .temp/${BaseName}.log 2>/dev/null
	while :
	do
		[ ! -d .temp ] && mkdir -p .temp
		${ProgramTool} > .temp/${BaseName}.log
		sync;sync;sync
		[ $(grep -icEv "^$" .temp/${BaseName}.log) -gt 5 ] && break
	done

	SoleLanChipset=($(echo ${LanChipset[@]} | tr ' ' '\n' | sort -u ))
	SoleLanChipset=$(echo ${SoleLanChipset[@]} | sed 's/ /\\|/g')

	NicIndexArray=()
	for((j=0;j<${#NicIndex[@]};j++))
	do
		local TempNic=$(cat -v .temp/${BaseName}.log | grep -iw "${SoleLanChipset}" | sed -n ${NicIndex[$j]}p | grep -iw "${LanChipset[$j]}" | awk '{print $1}') 
		if [ ${#TempNic} == 0 ] ; then
			Process 1 "No such net card: nic=${NicIndex[$j]},device=${LanChipset[$j]}"
			cat -v .temp/${BaseName}.log | grep -iw "${SoleLanChipset}" | sed -n ${NicIndex[$j]}p 
			let ErrorFlag++
		else
			NicIndexArray[$j]="${TempNic}"
		fi
	done

	if [ "$TotalAmount"x != "${#NicIndexArray[@]}"x ] ; then
		Process 1 "Check the total amount of net card ..."
		echo "Standard: ${TotalAmount} PCs, Current: ${#NicIndexArray[@]} PCs"
		echo "----------------------------------------------------------------------"
		cat -v .temp/${BaseName}.log | grep -EA50 "==="| grep -v "===\|^$" | grep "${SoleLanChipset}" 2>/dev/null
		echo "----------------------------------------------------------------------"
		let ErrorFlag++
	fi

	[ $ErrorFlag != 0 ] && exit 2

	Process 0 "Found target nic index: `echo "${NicIndexArray[@]}" | sed 's/ /,/g'`"
}


FlashMacAddr ()
{
	local TargetNicIndex=$1
	local TargetMacAddr=$(cat -v $2 | head -n1)
	local TargetChipName=$3
	#${NicIndexArray[$m]} ${MacAddrFiles[$m]} ${LanChipset[$m]}

	# Dump the mac and check it is default mac
	# If the current mac is equal to the target mac address,skip to flash
	DumpMacArg=mac_dump 
	DumpMac[$TargetNicIndex]=$(${ProgramTool} /nic=${TargetNicIndex} /${DumpMacArg} | grep 'LAN MAC Address' | awk '{print $6}' | tr -d ' .')
	if [ "${DumpMac[$TargetNicIndex]}x" == "${TargetMacAddr}"x ] && [ $DoubleFlash == "disable" ] && [ $CompelMode == "disable" ] ; then
		echo -e "\e[1;33m LAN${TargetNicIndex} has flashed MAC Address,skip update!\e[0m"
		echo -e "\e[1;33m---------------------------------------------------------------------\e[0m"
		printf "%-10s%-60s\n" "" "Current MAC Address: ${DumpMac[$TargetNicIndex]}"
		printf "%-10s%-60s\n" "" "Scan in MAC Address: ${TargetMacAddr}"
		[ "${TestMode}"x == 'parallel'x ] && echo "0" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
		return 0
	fi

	SoleLetterAmount=$(echo ${DumpMac[$TargetNicIndex]} | grep -o '[0-9A-F]' | sort -u | wc -l)
	if [ $SoleLetterAmount -ge 6 ] && [ $DoubleFlash == "disable" ] && [ $CompelMode == "disable" ] ; then
		echo -e "\e[1;33m ${DumpMac[$TargetNicIndex]} is not default mac,skip reflash LAN${TargetNicIndex} as: ${TargetMacAddr}\e[0m"
		echo -e "\e[1;33m---------------------------------------------------------------------\e[0m"
		return 1
	fi

	${ProgramTool} /nic=${TargetNicIndex} /mac=${TargetMacAddr}
	Process "$?" "Write the LAN${TargetNicIndex} mac address(${TargetMacAddr})"
	if [ $? == 0 ] ; then
		if [ "${ResetAction}"x == "Enable"x ]; then
			${ProgramTool} /nic=${TargetNicIndex} /adapterreset
		fi
		[ "${TestMode}x" == 'parallel'x ] && echo "0" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
		return 0
	else
		[ "${TestMode}x" == 'parallel'x ] && echo "1" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
		return 1
	fi
}

RemoveRecord ()
{
	echo
	[ ${ErrorFlag} != 0 ] && return 0
	rm -rf .temp/${BaseName}*.* 2>/dev/null
	rm -rf ${BaseName}*.log 2>/dev/null
	rm -rf ./logs/${BaseName}*.* 2>/dev/null
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare XmlConfigFile NicIndexArray TotalAmount MacAddrFiles LanChipset NicIndex MacFirst6 MacAddr FirstMacOEU
declare DoubleFlash=disable 
declare CompelMode=disable
declare FirstMacOEU='Un-limit'
declare ErrorFlag=0
declare TestMode="serial"
declare Password
declare ProgramTool='eeupdate64e'
declare ResetAction=Enable
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:pVDx: argv
do
	case ${argv} in
		p)
			CompelMode="enable"
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
			#只設置SerialTest,不是使用MT模式
			printf "%-s\n" "SerialTest,WirteLanMAC"
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


MacAddrFilesContrl
GetNicIndexArray

if [ "${TestMode}x" == 'parallel'x ] ; then
	mkdir -p ./logs 2>/dev/null
	PPIDKILL=$$
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" INT
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" KILL
	Pid='S00157193'
	rm -rf ./logs/${BaseName}*.* 2>/dev/null
fi
	
for ((m=0;m<${#NicIndexArray[@]};m++))
do
	# Input correct Password,flash Mac address again!
	if [ "$CompelMode"x == "enable"x ] && [ $DoubleFlash == "disable" ] ; then
		while :
		do
			echo -e "\033[0;30;43m--Input the correct password,flash MAC again!--\033[0m"
			read -p "Please input password: " -s psw
			pswmd5=$(echo -n $psw | md5sum | cut -c 1-32)
			echo ''
			if [ $(echo "${pswmd5}"x | grep -iwc "${Password}"x ) == 1 ]; then
				CompelFlash='enable'
				DoubleFlash='enable'
				break
			else				
				echo -e "\033[0;30;41m--Incorrect password.Please try again!--\033[0m"
			fi
		done
	fi
	
	if [ "${TestMode}x" == 'serial'x ] ; then
		FlashMacAddr ${NicIndexArray[$m]} ${MacAddrFiles[$m]} ${LanChipset[$m]}
		[ $? -ne 0 ] && let ErrorFlag++
	else
		<<-Sample
			NIC Bus Dev Fun Vendor-Device  Branding string
		=== === === === ============= =================================================
		  1   4  00  00   8086-151F    i350 EEPROM-less Network Device
		  2   4  00  01   8086-151F    i350 EEPROM-less Network Device
		  3   4  00  02   8086-151F    i350 EEPROM-less Network Device
		  4   4  00  03   8086-151F    i350 EEPROM-less Network Device
		  5   5  00  00   8086-151F    i350 EEPROM-less Network Device
		  6   5  00  01   8086-151F    i350 EEPROM-less Network Device
		  7   5  00  02   8086-151F    i350 EEPROM-less Network Device
		  8   5  00  03   8086-151F    i350 EEPROM-less Network Device
		  9  11  00  00   8086-1533    Intel(R) I210 Gigabit Network Connection
		 10  14  00  00   8086-1533    Intel(R) I210 Gigabit Network Connection
		Sample
		# 相同的網卡Fun唯一則網卡芯片和網孔數量一一對應,否則就是一分二、一分四或一分多 ...
		echo "1" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
		printf "%s\n" "NIC=${NicIndexArray[$m]}, write LAN MAC address=`cat ${MacAddrFiles[$m]} 2>/dev/null`"
		cat .temp/${BaseName}.log 2>/dev/null | grep -iw "${LanChipset[$m]}" | awk '{print $4}' | sort -u | wc -l | grep -iwq "1"
		if [ $? == 0 ] ; then
			#網卡芯片和網孔數量一一對應
			`FlashMacAddr ${NicIndexArray[$m]} ${MacAddrFiles[$m]} ${LanChipset[$m]} 2>&1 > ./logs/${BaseName}${NicIndexArray[$m]}.log` &
			Pid=$(echo "${Pid}|$!")
		else
			#一分多
			FlashMacAddr ${NicIndexArray[$m]} ${MacAddrFiles[$m]} ${LanChipset[$m]} 
			[ $? -ne 0 ] && let ErrorFlag++
		fi
	fi
done

if [ "${TestMode}x" == 'parallel'x ] ; then
	for((s=1;s>0;s++))
	do
		if [ $(ps | grep -wEc "(${Pid})") == 0 ] ; then
			echo
			break
		else
			[ ${s} == 1 ] && printf "%s\n" "The LAN MACs address are writing, please wait ... "
			sleep 1s
			printf "%s" ">"
			if [ $((s%70)) == 0 ] ; then
				printf "\r%s\r" "                                                                       "
			fi
		fi
		if [ ${s} -ge 90 ] ; then
			ps | grep -wE "(${Pid})" | awk '{print $1}' | xargs -I {} kill -9 {} >/dev/null 2>&1
			echo
			printf "%s\n" "Something is wrong, test timeout ..."
			let ErrorFlag++
		fi
	done
	sync;sync;sync

	#parse test result
	for ((m=0;m<${#NicIndexArray[@]};m++))
	do
		#一分多沒有再打印log，其燒錄過程是串行測試並打印在屏幕了
		cat ./logs/${BaseName}${NicIndexArray[$m]}.log 2>/dev/null
		cat ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null | grep -iwq "0"
		if [ $? != 0 ] ; then
			let ErrorFlag++
		fi
	done	
	
fi

#RemoveRecord
if [ $ErrorFlag != 0 ] ; then 
	echoFail "Write the LAN MAC(s) address"
	GenerateErrorCode
	exit 1
else
	echoPass "Write the LAN MAC(s) address"
fi
exit 0
