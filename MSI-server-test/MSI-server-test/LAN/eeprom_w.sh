#!/bin/bash
#FileName : eeprom_w.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.0"
	local CreatedDate="2018-05-28"
	local UpdatedDate="2020-12-31"
	local Description="Burn the eeprom  firmware online"
	
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
	printf "%16s%-s\n" "" "2020-12-31,支持多線程的方式燒錄EEPROM, EEPROM或版本為NULL則跳過燒錄"
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
	ExtCmmds=(xmlstarlet ${ProgramTool} checksum)
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
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-p : Enter the password to compel flash eeprom again
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : flash eeprom on line pass
		1 : flash eeprom on line fail
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
			
			<!--範例說明LAN Index="1">
				此部份配置信息for eeprom_w.sh/eeprom_c.sh/lan_w.sh/lan_c.sh/ChkPXE.sh
				<NicIndex>1:不接任何網卡時其Nic號</NicIndex>
				<Chipset>I354</Chipset>
				<EepromFile>I3540101.eep：在線燒錄時填寫，無則一定要填寫NULL</EepromFile>
				<CheckSum>0cd0 CheckSum最後四位</CheckSum>
				<EepromVer>1.8</EepromVer>
			</LAN-->
			

			<!-- enable: EEPROM file/MAC address can flash more than twice if necessary; disable: Only flash one time -->
			<DoubleFlash>disable</DoubleFlash>
			<Password>abcf314e470e139bf3c06c859761d560</Password>					
			<Card>
				<NicIndex>1</NicIndex>
				<Chipset>I354</Chipset>
				<EepromFile>I3540101.eep</EepromFile>
				<CheckSum>3C98</CheckSum>
				<EepromVer>1.8</EepromVer>
			</Card>

			<Card>
				<NicIndex>2</NicIndex>
				<Chipset>I354</Chipset>
				<EepromFile>I3540101.eep</EepromFile>
				<CheckSum>3C98</CheckSum>
				<EepromVer>1.8</EepromVer>
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
	DoubleFlash=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/DoubleFlash" -n "${XmlConfigFile}" 2>/dev/null)
	Password=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Password" -n "${XmlConfigFile}" 2>/dev/null)
	NicIndex=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/NicIndex" -n "${XmlConfigFile}" 2>/dev/null))
	LanChipset=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/Chipset" -n "${XmlConfigFile}" 2>/dev/null))
	EepromFiles=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/EepromFile" -n "${XmlConfigFile}" 2>/dev/null))
	ChkSum=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/CheckSum" -n "${XmlConfigFile}" 2>/dev/null))
	TotalAmount="${#NicIndex[@]}"
	TestMode=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ProgramName[.=\"${BaseName}\"]/@TestMode" -n "${XmlConfigFile}" 2>/dev/null | tr "[A-Z]" "[a-z]")
	TestMode=${TestMode:-"serial"}
	
	if [ ${#NicIndex} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

CheckEepromFiles()
{
	for((i=0;i<${#EepromFiles[@]};i++))
	do
		if [ "${EepromFiles[$i]}" != "NULL" ] && [ ! -s "${EepromFiles[$i]}" ] ; then
			Process 1 "No such file or 0 KB size of file: ${CurDir}/${EepromFiles[$i]}"
			let ErrorFlag++	
		fi
	done
	[ $ErrorFlag != 0 ] && exit 2

	#---> Check the MD5 of eeprom file,ignore the "NULL",which flashed off line
	for ((k=0;k<${#EepromFiles[@]};k++))
	do
		local CurChkSum=$(checksum ${EepromFiles[$k]} | awk '{print $NF}')
		echo "${CurChkSum}" | grep -iwq "${ChkSum[$k]}"
		if [ "$?" != 0 ] ; then
			Process 1 "Check the checksum of ${EepromFiles[$k]} fail, Current:${CurChkSum}, expect:${ChkSum[$k]}" 
			let ErrorFlag++
		else
			Process 0 "Verify the checksum of ${EepromFiles[$k]}(${ChkSum[$k]:-NULL}) pass ..."
		fi
	done
	[ $ErrorFlag != 0 ] && exit 2
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

FlashEepromFilesOnline ()
{
	local TargetNicIndex=$1
	local TargetEepromFile=$2
	local StandardVersion=$3
	local TargetChipset=$4

	#Compare the eeprom version first	
	case $TargetChipset in
		[Ii]211)
			GetVerArg=invmversion
			CurVersion=$(${ProgramTool} /nic=$TargetNicIndex /$GetVerArg | tail -1 | awk '{print $6}')
		;;

		*)
			GetVerArg=eepromver  
			CurVersion=$(${ProgramTool} /nic=$TargetNicIndex /$GetVerArg | grep 'EEPROM Image Version' | awk -F'Version: ' '{print $NF}' | tail -n1 )  
		;;
		esac
		
		if [ "$CurVersion"x == "$StandardVersion"x ] && [ "$CompelFlash"x == "disable"x ] && [ "$DoubleFlash"x == "disable"x ] ; then
			printf "%-2s\e[1;33m%-4s\e[0m%-4s%-60s\n" "[ " "SKIP" " ]  " "LAN$TargetNicIndex has burned the eeprom firmware, skip update!"
			[ "${TestMode}x" == 'parallel'x ] && echo "0" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
			sleep 1
			return 0
		fi

	# Burn Eeprom on line
	case $TargetChipset in
		[Ii]211)
			${ProgramTool} /nic=$TargetNicIndex /invmupdate  /file=$TargetEepromFile
		;;
		
		*)
			${ProgramTool} /nic=$TargetNicIndex /d $TargetEepromFile
		;;
		esac

	Process "$?" "Burn the LAN$TargetNicIndex EEPROM($TargetEepromFile) firmware ..." 
	if [ $? == 0 ] ; then
		[ "${TestMode}x" == 'parallel'x ] && echo "0" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
		sleep 1
		return 0
	else
		[ "${TestMode}x" == 'parallel'x ] && echo "1" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
		sleep 1
		return 1
	fi	
}

RemoveRecord ()
{
	echo
	[ ${ErrorFlag} != 0 ] && return 0
	rm -rf .temp/${BaseName}*.* 2>/dev/null
	rm -rf ${BaseName}*.log 2>/dev/null
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare XmlConfigFile NicIndexArray TotalAmount EepromFiles LanChipset ChkSum NicIndex 
declare EepromVersion
declare DoubleFlash=disable 
declare CompelMode=disable
declare ErrorFlag=0
declare CompelFlash='disable'
declare TestMode="serial"
declare Password
declare ProgramTool='eeupdate64e'
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
			printf "%-s\n" "SerialTest,WirteEEPROM"
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


CheckEepromFiles
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
	EepromVersion[$m]=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card[NicIndex=\"${NicIndex[m]}\"]/EepromVer" -n "${XmlConfigFile}" 2>/dev/null)
	# Input correct Password,flash eeprom again!
	if [ "$CompelMode"x == "enable"x ] && [ $DoubleFlash == "disable" ] ; then
		while :
		do
			echo -e "\033[0;30;43m--Input the correct password,flash eeprom again!--\033[0m"
			read -p "Please input password: " -s psw
			pswmd5=$(echo -n $psw  | md5sum | cut -c 1-32)
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

	echo "${EepromVersion[$m]}" | grep -iwq "null"
	if [ $? == 0 ] || [ "${EepromFiles[$m]}" == "NULL" ] ; then
		printf "%-2s\e[1;33m%-4s\e[0m%-4s%-60s\n" "[ " "SKIP" " ]  " "LAN$((m+1))(Nic=${NicIndexArray[$m]}) does not need to burn firmware online"
		[ "${TestMode}x" == 'parallel'x ] && echo "0" > ./logs/${BaseName}${NicIndexArray[$m]}.temp 2>/dev/null
 		continue
	fi
	
	if [ "${TestMode}x" == 'serial'x ] ; then
		FlashEepromFilesOnline "${NicIndexArray[$m]}" "${EepromFiles[$m]}" "${EepromVersion[$m]}" "${LanChipset[$m]}"
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
		printf "%s\n" "NIC=${NicIndexArray[$m]}, burn the EEPROM firmware=${EepromFiles[$m]}"
		cat .temp/${BaseName}.log 2>/dev/null | grep -iw "${LanChipset[$m]}" | awk '{print $4}' | sort -u | wc -l | grep -iwq "1"
		if [ $? == 0 ] ; then
			#網卡芯片和網孔數量一一對應
			`FlashEepromFilesOnline "${NicIndexArray[$m]}" "${EepromFiles[$m]}" "${EepromVersion[$m]}" "${LanChipset[$m]}" 2>&1 > ./logs/${BaseName}${NicIndexArray[$m]}.log` &
			Pid=$(echo "${Pid}|$!")
		else
			#一分多
			FlashEepromFilesOnline "${NicIndexArray[$m]}" "${EepromFiles[$m]}" "${EepromVersion[$m]}" "${LanChipset[$m]}"
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
			[ ${s} == 1 ] && printf "%s\n" "The LAN EEPROM firmware are in the burning, please wait ... "
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

RemoveRecord
if [ $ErrorFlag != 0 ] ; then 
	echoFail "Burn the eeprom firmware online"
	GenerateErrorCode
	exit 1
else
	echoPass "Burn the eeprom firmware online"
fi

exit 0
