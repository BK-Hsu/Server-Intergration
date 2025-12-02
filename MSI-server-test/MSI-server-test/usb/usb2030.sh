#!/bin/bash
#FileName : usb2030.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.2"
	local CreatedDate="2019-03-07"
	local UpdatedDate="2020-11-18"
	local Description="USB2.0 and USB3.0 detected and read-write functional test"
	
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
	printf "%16s%-s\n" "" "2020-08-25,重複的配置信息提示"
	printf "%16s%-s\n" "" "2020-10-18,新增讀+寫功能測試"
	printf "%16s%-s\n" "" "2020-11-18,Support USB3.0(10Gbps)"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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

ShowTitle()
{
	local BlankCnt=0
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

Wait4nSeconds()
 {
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do 
		printf "\r\e[1;33mAfter %02d seconds will auto continue, press [Y] to test to test at once ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			if [ ${Ans} == "y" ] || [ ${Ans} == "Y" ] ; then
				return 1
			fi
			break
		fi
	done

	echo
}


ForDebugGetUsbAddress ()
{
	while :
	do
	# While the argument is -d
	# Get USB address

		echo -e "\033[0;30;43m ********************************************************************* \033[0m"
		echo -e "\033[0;30;43m *  Please remove all USB2.0/3.0 devices: USBtoCOM or USB3.0 disks   * \033[0m"
		echo -e "\033[0;30;43m ********************************************************************* \033[0m"
		read -p "Press any Key to continue..." -t 10 -n 1 ask
		echo
		# remove all dmesg record
		dmesg -c  > /dev/null 2>&1
		
		echo -e "\033[0;30;42m ********************************************************************* \033[0m"
		echo -e "\033[0;30;42m *   Please plug in all USB2.0/3.0 devices: TL587 card               * \033[0m"
		echo -e "\033[0;30;42m ********************************************************************* \033[0m"
		read -p "Press any Key to continue..." -t 50 -n 1 ask
		echo
		clear 
		FoundAmount=($(dmesg | grep -E "usb [1-9]{1,3}-" | tr ' ' '\n' | grep -E "[1-9]{1,3}-"| sort -u))
		if [ ${#FoundAmount[@]}  != 0 ] ; then		
			echo -e "\033[0;32m Found the USB2.0/3.0 device as below:\033[0m"
			echo "----------------------------------------------------------------------"
			AddressSet=($(dmesg | grep -E "usb [1-9]{1,3}-" | tr ' ' '\n' | grep -E "[1-9]{1,3}-"| sort -u | tr -d ':' ))
			for((a=0;a<${#AddressSet[@]};a++))
			do
				dmesg | grep -iw "${AddressSet[$a]}" | grep -iwq "SuperSpeed"
				if [ $? == 0 ] ; then
					echo -e " USB3.0 Device address: \e[1;32m${AddressSet[$a]}\e[0m"
					continue
				fi

				dmesg | grep -iw "${AddressSet[$a]}" | grep -iwq "SuperSpeedPlus"
				if [ $? == 0 ] ; then
					echo -e " USB3.0+ Device address: \e[1;32m${AddressSet[$a]}\e[0m"
					continue
				fi
				
				dmesg | grep -iw "${AddressSet[$a]}" | grep -iwq "High.Speed"
				if [ $? == 0 ] ; then
					echo -e " USB2.0 Device address: \e[1;32m${AddressSet[$a]}\e[0m"
					continue
				fi
				
				echo -e "Unknown USB Device address: \e[1;32m${AddressSet[$a]}\e[0m"
			done
			echo "----------------------------------------------------------------------"
		else
			echo -e "\033[0;31mNo found any USB2.0/3.0 devices\e[0m"
		fi
		
		read -p "Press [Enter] to continue,[Ctrl]+[C] to exit ... " -n 1 Ask
		Ask=${Ask:-Y}
		case $Ask in
			Y|y)
				break
			;;
		  
			*)
				:
			esac
		echo 
	done
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
	-d : Get the usb devices ports' address, eg.: 3-1.1
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)

	return code:
		0 : USB2.0 and USB3.0 functional test pass
		1 : USB2.0 and USB3.0 functional test fail
		2 : File is not exist
		3 : Parameters error
		Other : Fail
		
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<USB>	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXUS2|USB test fail</ErrorCode>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>4</ParallelNumber>
			<!--測試模式TestMode: Read(R)/RW/Detect-->
			<TestMode>RW</TestMode>
			<!--延時多少秒後測試，對全部為USB3.0的主板預移除鍵盤掃碼槍和U盤等的切換時間-->
			<DelayTime>5</DelayTime>
			<!--讀寫單位均是MB/s-->
			<USB20>
				<MinReadSpeed>20</MinReadSpeed>
				<MinWriteSpeed>20</MinWriteSpeed>
			</USB20>
			<USB30>
				<MinReadSpeed>40</MinReadSpeed>
				<MinWriteSpeed>40</MinWriteSpeed>
			</USB30>
			
			<!--解析FW信息-->
			<ParseInfo>Disable</ParseInfo>
			
			<!--使用TL587-03S/04S小卡測試, TL587,TL679不支持RW測試 -->
			<!--某接口僅沒有USB2.0/USB3.0功能的時候，其address置NULL-->
			<!--usb2030.sh USB2.0 & USB3.0 detect test together-->
			<!-- usb2.0 address | usb3.0 address | pcb marking -->
			<PortID>3-1|4-1|R_USB1-F3</PortID>
			<PortID>3-2|4-2|R_USB1-F4</PortID>
			<PortID>3-3|4-3|F_USB1-F1</PortID>
			<PortID>3-4|4-4|F_USB1-F2</PortID>
			<PortID>3-9|4-5|R_USB1-F1</PortID>
			<PortID>3-10|4-6|R_USB1-F2</PortID>
			<PortID>3-6|NULL|LAN_USB1-F1</PortID>
			<PortID>3-5|NULL|LAN_USB1-F2</PortID>
		</TestCase>
	</USB>
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
	ParseInfo=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/ParseInfo" -n "${XmlConfigFile}" 2>/dev/null )
	USB20Addr=($(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/PortID" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $1}'))
	USB30Addr=($(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/PortID" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $2}'))
	PcbMarking=($(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/PortID" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $3}'))
	USB2030Amount="${#USB30Addr[@]}"
	TestMode=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/TestMode" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]' )
	DelayTime=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/DelayTime" -n "${XmlConfigFile}" 2>/dev/null )
	ParallelNumber=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/ParallelNumber" -n "${XmlConfigFile}" 2>/dev/null | tr -d '[[:alpha:]][[:punct:]]' )
	Usb20MinReadSpeed=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/USB20/MinReadSpeed" -n "${XmlConfigFile}" 2>/dev/null )
	Usb30MinReadSpeed=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/USB30/MinWriteSpeed" -n "${XmlConfigFile}" 2>/dev/null )
	Usb20MinWriteSpeed=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/USB20/MinReadSpeed" -n "${XmlConfigFile}" 2>/dev/null )
	Usb30MinWriteSpeed=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/USB30/MinWriteSpeed" -n "${XmlConfigFile}" 2>/dev/null )

	if [ ${#USB30Addr[@]} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi

	local USB20AddrCnt=0
	local USB30AddrCnt=0
	let USB20AddrCnt=$(echo "${USB20Addr[@]}" | tr ' ' '\n' | grep -viw "null" |sort -u | wc -l )+$(echo "${USB20Addr[@]}" | tr ' ' '\n' | grep -iwc "null" )
	let USB30AddrCnt=$(echo "${USB30Addr[@]}" | tr ' ' '\n' | grep -viw "null" | sort -u | wc -l )+$(echo "${USB30Addr[@]}" | tr ' ' '\n' | grep -iwc "null" )
	local PcbMarkingCnt=$(echo "${PcbMarking[@]}" | tr ' ' '\n' | sort -u | wc -l )
	if [ ${USB20AddrCnt} != ${#USB30Addr[@]} ] || [ ${PcbMarkingCnt} != ${#USB30Addr[@]} ] ; then
		Process 1 "XML配置檔中發現了重複的Port ID或位置(NULL已除外)..."
		let ErrorFlag++
	fi
	
	if [ ${#TestMode} != 0 ] ; then
		
		echo ${TestMode} | grep -iwq "R\|read\|RW\|detect"
		if [ $? != 0 ] ; then
			Process 1 "Invalid USB2.0/3.0 test mode: ${TestMode}"
			exit 3
		fi
		
		if [ "${#ParallelNumber}" == "0" ] || [ ${ParallelNumber} -le 0 ] ; then
			ParallelNumber=$(cat /proc/cpuinfo | grep -ic "processor")
		fi	
		
		echo ${TestMode} | grep -iwq "r\|read\|RW"
		if [ $? == 0 ] ; then
			echo ${Usb20MinReadSpeed} | grep -iwEq "[0-9]{1,5}"
			if [ $? != 0 ] ; then
				Process 1 "Invalid USB2.0 min read speed: ${Usb20MinReadSpeed}"
				let ErrorFlag++
			fi
			
			echo ${Usb30MinReadSpeed} | grep -iwEq "[0-9]{1,5}"
			if [ $? != 0 ] ; then
				Process 1 "Invalid USB3.0 min read speed: ${Usb30MinReadSpeed}"
				let ErrorFlag++
			fi
		fi
		
		echo ${TestMode} | grep -iwq "RW"
		if [ $? == 0 ] ; then
			echo ${Usb20MinWriteSpeed} | grep -iwEq "[0-9]{1,5}"
			if [ $? != 0 ] ; then
				Process 1 "Invalid USB2.0 min write speed: ${Usb20MinWriteSpeed}"
				let ErrorFlag++
			fi
			
			echo ${Usb30MinWriteSpeed} | grep -iwEq "[0-9]{1,5}"
			if [ $? != 0 ] ; then
				Process 1 "Invalid USB3.0 min write speed: ${Usb30MinWriteSpeed}"
				let ErrorFlag++
			fi
		fi
	fi
	
	if [ ${#DelayTime} != 0 ] ; then
		echo ${DelayTime} | grep -wEq "[0-9]{1,3}"
		if [ $? != 0 ] ; then
			Process 1 "Invalid Delay Time: ${DelayTime}"
			let ErrorFlag++			
		fi
	else
		DelayTime=1
	fi 
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0
}

CheckAmount ()
{
	SoleUSB30Addr=($(echo ${USB30Addr[@]} | tr ' ' '\n' | sort -u | grep -iv "NULL"))
	SoleUSB30Addr1=$(echo ${SoleUSB30Addr[@]} | sed 's/ /\.\\|/g' | sed 's/$/\./g' | sed s/\\./\\\\./g)
	SoleUSB30Addr2=$(echo ${SoleUSB30Addr[@]} | sed 's/ /:\\|/g' | sed 's/$/:/g' | sed s/\\./\\\\./g)
	SoleUSB30Addr=$(echo ${SoleUSB30Addr[@]} | sed 's/ /\\|/g' | sed s/\\./\\\\./g)
	# Get the USB3.0 U disk amount by dmesg log
	# SoleUSB20Addr="1-1.1\|1-1.2\|1-1.3"

	#USB30AmountByAddr=($(dmesg | grep -E "usb [1-9]{1,3}-*" | tr ' ' '\n' | grep -E "[1-9]{1,3}-*" | grep "${SoleUSB30Addr}" | sort -u | tr -d ': ' ))

	SoleUSB20Addr=($(echo ${USB20Addr[@]} | tr ' ' '\n' | sort -u | grep -iv "NULL"))
	SoleUSB20Addr1=$(echo ${SoleUSB20Addr[@]} | sed 's/ /\.\\|/g' | sed 's/$/\./g' | sed s/\\./\\\\./g)
	SoleUSB20Addr2=$(echo ${SoleUSB20Addr[@]} | sed 's/ /:\\|/g' | sed 's/$/:/g' | sed s/\\./\\\\./g)
	SoleUSB20Addr=$(echo ${SoleUSB20Addr[@]} | sed 's/ /\\|/g' | sed s/\\./\\\\./g)

	while :
	do
		# Speed Description:
		# 1.5  Mbit/s for low speed USB
		# 12   Mbit/s for full speed USB
		# 480  Mbit/s for high speed USB (added for USB 2.0);also used for Wireless USB, which has no fixed speed
		# 5000 Mbit/s for SuperSpeed USB (added for USB 3.0)

		# USB30BlockAddr=(../devices/pci0000:00/0000:00:16.0/usb1/1-1/1-1.2/1-1.2:1.0/host3/target3:0:0/3:0:0:0/block/sdb .... )
		USB30BlockAddr=($(ls /sys/bus/usb/devices/  | grep -w "$SoleUSB30Addr" | grep -v "${SoleUSB30Addr2}" |grep -v "${SoleUSB30Addr1}" | tr -d ' '))
		USB20BlockAddr=($(ls /sys/bus/usb/devices/  | grep -w "$SoleUSB20Addr" | grep -v "${SoleUSB20Addr2}" | grep -v "${SoleUSB20Addr1}" | tr -d ' '))

		# DetectUSB30Addr=(1-1.2 1-1.3 1-1.4 ...)
		DetectUSB30Addr=($(dmesg | grep -iw "SuperSpeed\|SuperSpeedPlus" | grep -E "usb [1-9]{1,4}-*" | tr ' ' '\n' | grep -E "[1-9]{1,4}-*" | grep -v "${SoleUSB30Addr1}" | grep "${SoleUSB30Addr}" | sort -u | tr -d ': ' ))
		DetectUSB20Addr=($(dmesg | grep -iw "high.speed" | grep -E "usb [1-9]{1,4}-*" | tr ' ' '\n' | grep -E "[1-9]{1,4}-*" | grep -v "${SoleUSB20Addr1}" | grep "${SoleUSB20Addr}" | sort -u | tr -d ': ' ))
		
		# Get the Amount of USB3.0 that uninsert ;
		# Created CurRelationship file
		#GetUSB2030DevPath
		
		#NO  Location           USB2.0 - Detect       USB3.0 - Detect     Result
		#-----------------------------------------------------------------------
		#01  USB2               1-11: /dev/sdb        2-1:  /dev/sdc      Pass
		#02  USB3               1-2: /dev/sdd         2-12: No Device     Fail
		#-----------------------------------------------------------------------
		
		#GetResult=($(cat ${CurRelationship}))
		#ShowTitle "Detect USB2.0&3.0 Device test"
		#printf "%-4s%-19s%-23s%-20s%-6s\n" "NO" "Location" "USB2.0 - Detect" "USB3.0 - Detect" "Result"
		#echo "-----------------------------------------------------------------------"
		#for ((j=0;j<${#GetResult[@]};j++))
		#do
			# USB1-UP|1-1.1|/dev/sda|2-1|/dev/sda|Pass --> ${CurRelationship}	
		#	DeviceMark=$(echo ${GetResult[$j]} | awk -F'|' '{print $1}')
		#	Device20Addr=$(echo ${GetResult[$j]} | awk -F'|' '{print $2}')
		#	Device20Name=$(echo ${GetResult[$j]} | awk -F'|' '{print $3}')
		#	Device30Addr=$(echo ${GetResult[$j]} | awk -F'|' '{print $4}')
		#	Device30Name=$(echo ${GetResult[$j]} | awk -F'|' '{print $5}')
		#	TestResult=$(echo ${GetResult[$j]} | awk -F'|' '{print $6}')
			
		#	printf "%-4s%-19s%7s%-16s%7s%-13s" "$((j+1))" "${DeviceMark}" "${Device20Addr}: " "${Device20Name}" "${Device30Addr}: " "${Device30Name}"
		#	if [ "${TestResult}"x == 'Pass'x ] ; then
		#		printf "\e[1;32m%-5s\e[0m\n" "${TestResult}"
		#	else
		#		printf "\e[1;31m%-5s\e[0m\n" "${TestResult}"
		#		let ErrorFlag++
		#	fi	
		#done
		#echo "-----------------------------------------------------------------------"

		if [ ${#USB30BlockAddr[@]}x != ${#DetectUSB30Addr[@]}x ]; then
			if [ $(echo ${USB30Addr[@]} | tr ' ' '\n' | grep -ivc 'null') != 0 ] ; then
				let ErrorFlag++
			fi
		fi
		
		if [ ${#USB20BlockAddr[@]}x != ${#DetectUSB20Addr[@]}x ]; then
			if [ $(echo ${USB20Addr[@]} | tr ' ' '\n' | grep -ivc 'null') != 0 ] ; then
				let ErrorFlag++
			fi
		fi
		
		break	
	done
}

GetUSB2030DevPath ()
{
	mkdir .temp 2>/dev/null
	CurRelationship=".temp/Relationship${BaseName}.LOG"
	rm -rf ${CurRelationship} 2>/dev/null

	# USB30BlockAddr=(../devices/pci0000:00/0000:00:16.0/usb1/1-1/1-1.2/1-1.2:1.0/host3/target3:0:0/3:0:0:0/block/sdb .... )
	USB20BlockAddr=($(ls -l /sys/block/ | grep -wE "usb[0-9]{1,3}" | grep -w "$SoleUSB20Addr" | awk -F'->' '{print $2}'| tr -d ' '  ))
	USB30BlockAddr=($(ls -l /sys/block/ | grep -wE "usb[0-9]{1,3}" | grep -w "$SoleUSB30Addr" | awk -F'->' '{print $2}'| tr -d ' '  ))

	for ((q=0;q<${USB2030Amount};q++))
	do
		PathErrorFlag=0
		let Q=${q}+1
		PartPath30=$(echo "${USB30BlockAddr[@]}" | tr ' ' '\n' | grep -wF "${USB30Addr[$q]}" | head -n1 | awk -F'/' '{print $NF}' 2>/dev/null)
		PartPath30=${PartPath30:-"NoDevice"}
		
		PartPath20=$(echo "${USB20BlockAddr[@]}" | tr ' ' '\n' | grep -wF "${USB20Addr[$q]}" | head -n1 | awk -F'/' '{print $NF}' 2>/dev/null)
		PartPath20=${PartPath20:-"NoDevice"}
		
		if [ $(echo ${USB20Addr[$q]} | grep -iwc "null") == 1 ] ; then
			UsbMesg="${PcbMarking[$q]}|${USB20Addr[$q]}|${PartPath20}"
		else
			if [ $(echo ${PartPath20} | grep -iwc "NoDevice") == 1 ] ; then
				UsbMesg="${PcbMarking[$q]}|${USB20Addr[$q]}|${PartPath20}"
				let PathErrorFlag++
			else
				UsbMesg="${PcbMarking[$q]}|${USB20Addr[$q]}|/dev/${PartPath20}"
			fi
		fi

		if [ $(echo ${USB30Addr[$q]} | grep -iwc "null") == 1 ] ; then
			UsbMesg="${UsbMesg}|${USB30Addr[$q]}|${PartPath30}"
		else
			if [ $(echo ${PartPath30} | grep -iwc "NoDevice") == 1 ] ; then
				UsbMesg="${UsbMesg}|${USB30Addr[$q]}|${PartPath30}"
				let PathErrorFlag++
			else
				UsbMesg="${UsbMesg}|${USB30Addr[$q]}|/dev/${PartPath30}"
			fi
		fi	
		
		# USB1-UP|1-1.1|/dev/sda|2-1|/dev/sda|Pass --> ${CurRelationship}
		if [ ${PathErrorFlag} == 0 ] ; then 
			echo "${UsbMesg}|Pass" >> ${CurRelationship}
		else
			echo "${UsbMesg}|Fail" >> ${CurRelationship}
		fi

		sync;sync;sync
	done
}

ReadFirmware()
{
clear
<<INFO
[ 2121.101644] usb 3-2: USB disconnect, device number 7
[ 2121.212145] usb 4-2: USB disconnect, device number 6
[ 2123.175108] usb 3-1: USB disconnect, device number 6
[ 2123.279192] usb 4-1: USB disconnect, device number 5
[ 2126.149260] usb 4-2: new SuperSpeed USB device number 7 using xhci_hcd
[ 2126.160679] usb 4-2: New USB device found, idVendor=174c, idProduct=55aa
[ 2126.160682] usb 4-2: New USB device strings: Mfr=2, Product=3, SerialNumber=1
[ 2126.160684] usb 4-2: Product: ASMT1051
[ 2126.160685] usb 4-2: Manufacturer: asmedia
[ 2126.160687] usb 4-2: SerialNumber: 1234567890AAAAB4
[ 2126.161389] usb-storage 4-2:1.0: USB Mass Storage device detected
[ 2126.161889] usb-storage 4-2:1.0: Quirks match for vid 174c pid 55aa: 400000
[ 2126.161909] scsi host20: usb-storage 4-2:1.0
[ 2126.794258] usb 3-2: new high-speed USB device number 8 using xhci_hcd
[ 2127.653500] usb 3-2: New USB device found, idVendor=174c, idProduct=55aa
[ 2127.653504] usb 3-2: New USB device strings: Mfr=2, Product=3, SerialNumber=1
[ 2127.653506] usb 3-2: Product: ASMT1051
[ 2127.653507] usb 3-2: Manufacturer: asmedia
[ 2127.653508] usb 3-2: SerialNumber: 1234567890AAAAB8
[ 2127.653840] usb-storage 3-2:1.0: USB Mass Storage device detected
[ 2127.653899] usb-storage 3-2:1.0: Quirks match for vid 174c pid 55aa: 400000
[ 2127.653919] scsi host21: usb-storage 3-2:1.0
[ 2292.112852] usb 3-2: USB disconnect, device number 8
[ 2292.216146] usb 4-2: USB disconnect, device number 7
[ 2618.150633] usb 4-2: new SuperSpeed USB device number 8 using xhci_hcd
[ 2618.162049] usb 4-2: New USB device found, idVendor=174c, idProduct=55aa
[ 2618.162052] usb 4-2: New USB device strings: Mfr=2, Product=3, SerialNumber=1
[ 2618.162054] usb 4-2: Product: ASMT1051
[ 2618.162056] usb 4-2: Manufacturer: asmedia
[ 2618.162057] usb 4-2: SerialNumber: 1234567890AAAAB4
[ 2618.163411] usb-storage 4-2:1.0: USB Mass Storage device detected
[ 2618.164002] usb-storage 4-2:1.0: Quirks match for vid 174c pid 55aa: 400000
[ 2618.164023] scsi host22: usb-storage 4-2:1.0
[ 2618.794626] usb 3-2: new high-speed USB device number 9 using xhci_hcd
[ 2619.653898] usb 3-2: New USB device found, idVendor=174c, idProduct=55aa
[ 2619.653902] usb 3-2: New USB device strings: Mfr=2, Product=3, SerialNumber=1
[ 2619.653904] usb 3-2: Product: ASMT1051
[ 2619.653906] usb 3-2: Manufacturer: asmedia
[ 2619.653907] usb 3-2: SerialNumber: 1234567890AAAAB8
[ 2619.654316] usb-storage 3-2:1.0: USB Mass Storage device detected
[ 2619.654389] usb-storage 3-2:1.0: Quirks match for vid 174c pid 55aa: 400000
[ 2619.654406] scsi host23: usb-storage 3-2:1.0
INFO

	#Location  PCBMarking    Spec.      Get-Product   Get-Manuf.    Get-S/N   
	#----------------------------------------------------------------------
	# 3-1      USB2-UP       USB2.0        Pass         Pass          Pass
	# 4-1      USB2-UP       USB3.0        Pass         Pass          Pass
	# 4-2      JUSB1-down    Uninstall     ----         ----          ----   
	#----------------------------------------------------------------------
	
	USBinfo="UsbInfo"
	rm -rf ${USBinfo}.log 2>/dev/null

	ShowTitle "Read the USB2.0&3.0 device information"
	echo "Location  PCBMarking    Spec.      Get-Product   Get-Manuf.    Get-S/N"
	echo "----------------------------------------------------------------------"
	for((u=0;u<${#USB20Addr[@]};u++))
	do
		echo "${USB20Addr[$u]}" | grep -iwq 'null' && continue
		
		printf "%-10s%-14s" " ${USB20Addr[$u]}" "${PcbMarking[$u]}"
		#Check exist
		LastDetectMsg=$(dmesg | grep -iw "${USB20Addr[$u]}" |grep -v "${USB20Addr[$u]}\." |grep -v "${USB20Addr[$u]}:[1-9]" | grep -i "new.*speed USB device number" | tail -n1 )
		LastDetectMsg=${LastDetectMsg:-"NoExistDevice"}
		
		dmesg | grep -iw "${USB20Addr[$u]}" | grep -v "${USB20Addr[$u]}\." |grep -v "${USB20Addr[$u]}:[1-9]" | grep -iwFA20 "${LastDetectMsg}" | grep -iwq "USB disconnect"
		if [ $? == 0 ] || [ "${LastDetectMsg}"x == "NoExistDevice"x ] ; then
			printf "\e[1;31m%-14s\e[0m%-13s%-14s%-5s\n"  "Uninstall" "----" "----" "----"
			let ErrorFlag++
			continue
		fi
		
		#Get USB Spec.
		USB20Spec=$(dmesg | grep -iw "${USB20Addr[$u]}" | grep -v "${USB20Addr[$u]}\." |grep -v "${USB20Addr[$u]}:[1-9]" | grep -i "new.*speed USB device number" | tail -n1 | tr ' ' '\n' | grep -i 'high\|speed' | tr '\n' ' ')
		echo ${USB20Spec} | grep -iwq "high.speed"
		if [ $? == 0 ] ; then
			printf "%-14s" "USB2.0"
		else
			
			if [ $(echo ${USB20Spec} | grep -iwc "SuperSpeed") == 1 ] ; then
				printf "\e[1;31m%-14s\e[0m" "USB3.0"
			elif [ $(echo ${USB20Spec} | grep -iwc "SuperSpeedPlus") == 1 ] ; then
				printf "\e[1;31m%-14s\e[0m" "USB3.0+"
			else
				printf "\e[1;31m%-14s\e[0m" "USB1.x"
			fi
			let ErrorFlag++
		fi
		
		#Get Product
		USB20Product=$(dmesg | grep -iw "${USB20Addr[$u]}" | grep "Product" | tail -n1 | awk -F':' '{print $NF}')
		if [ ${#USB20Product} != 0 ] ; then
			printf "%-13s" "Pass"
		else
			printf "\e[1;31m%-13s\e[0m" "Fail"
			let ErrorFlag++
		fi
		
		#Get Manufacturer
		USB20Manufacturer=$(dmesg | grep -iw "${USB20Addr[$u]}" | grep "Manufacturer" | tail -n1 | awk -F':' '{print $NF}')
		if [ ${#USB20Manufacturer} != 0 ] ; then
			printf "%-14s" "Pass"
		else
			printf "\e[1;31m%-14s\e[0m" "Fail"
			let ErrorFlag++
		fi
		
		#Get S/N
		USB20SerialNumber=$(dmesg | grep -iw "${USB20Addr[$u]}" | grep "SerialNumber" | tail -n1 | awk -F':' '{print $NF}')
		if [ ${#USB20SerialNumber} != 0 ] ; then
			printf "%-5s\n" "Pass"
		else
			printf "\e[1;31m%-5s\e[0m\n" "Fail"
			let ErrorFlag++
		fi
		
		LastDetect=$(echo ${LastDetectMsg} | awk -F']' '{print $NF}')
		echo -e '--------------------------------------------------------------------------------' >> ${USBinfo}.log
		${DMESG} | grep -iw "${USB20Addr[$u]}" | grep -iwFA20 "${LastDetect}" >> ${USBinfo}.log
		echo -e '--------------------------------------------------------------------------------\n\n' >> ${USBinfo}.log
		sync;sync;sync
		
	done

	for((u=0;u<${#USB30Addr[@]};u++))
	do
		echo "${USB30Addr[$u]}" | grep -iwq 'null' && continue
		
		printf "%-10s%-14s" " ${USB30Addr[$u]}" "${PcbMarking[$u]}"
		#Check exist
		LastDetectMsg=$(dmesg | grep -iw "${USB30Addr[$u]}" | grep -v "${USB30Addr[$u]}\." |grep -v "${USB30Addr[$u]}:[1-9]" | grep -i "new.*speed .*USB device number\|new.*speedPlus .*USB device number" | tail -n1  )
		LastDetectMsg=${LastDetectMsg:-"NoExistDevice"}
		dmesg | grep -iw "${USB30Addr[$u]}" | grep -v "${USB30Addr[$u]}\." | grep -v "${USB30Addr[$u]}:[1-9]" | grep -iwFA20 "${LastDetectMsg}" | grep -iwq "USB disconnect"
		if [ $? == 0 ] || [ "${LastDetectMsg}"x == "NoExistDevice"x ] ; then
			printf "\e[1;31m%-14s\e[0m%-13s%-14s%-5s\n"  "Uninstall" "----" "----" "----"
			let ErrorFlag++
			continue
		fi
		
		#Get USB Spec.
		USB30Spec=$(dmesg | grep -iw "${USB30Addr[$u]}" | grep -v "${USB30Addr[$u]}\." |grep -v "${USB30Addr[$u]}:[1-9]" | grep -i "new.*speed .*USB device number\|new.*speedPlus .*USB device number" | tail -n1 | tr ' ' '\n' | grep -i 'speed')
		
		if [ $(echo ${USB30Spec} | grep -iwc "SuperSpeed") == 1 ] ; then
			printf "%-14s" "USB3.0"
		elif [ $(echo ${USB30Spec} | grep -iwc "SuperSpeedPlus") == 1 ] ; then
			printf "%-14s" "USB3.0+"
		else
			printf "\e[1;31m%-14s\e[0m" "USB2.0"
			let ErrorFlag++
		fi
		
		#Get Product
		USB30Product=$(dmesg | grep -iw "${USB30Addr[$u]}" | grep -v "${USB30Addr[$u]}\." |grep -v "${USB30Addr[$u]}:[1-9]" | grep "Product" | tail -n1 | awk -F':' '{print $NF}')
		if [ ${#USB30Product} != 0 ] ; then
			printf "%-13s" "Pass"
		else
			printf "\e[1;31m%-13s\e[0m" "Fail"
			let ErrorFlag++
		fi
		
		#Get Manufacturer
		USB30Manufacturer=$(dmesg | grep -iw "${USB30Addr[$u]}" | grep -v "${USB30Addr[$u]}\." |grep -v "${USB30Addr[$u]}:[1-9]" | grep "Manufacturer" | tail -n1 | awk -F':' '{print $NF}')
		if [ ${#USB20Manufacturer} != 0 ] ; then
			printf "%-14s" "Pass"
		else
			printf "\e[1;31m%-14s\e[0m" "Fail"
			let ErrorFlag++
		fi
		
		#Get S/N
		USB30SerialNumber=$(dmesg | grep -iw "${USB30Addr[$u]}" | grep -v "${USB30Addr[$u]}\." |grep -v "${USB30Addr[$u]}:[1-9]" | grep "SerialNumber" | tail -n1 | awk -F':' '{print $NF}')
		if [ ${#USB30SerialNumber} != 0 ] ; then
			printf "%-5s\n" "Pass"
		else
			printf "\e[1;31m%-5s\e[0m\n" "Fail"
			let ErrorFlag++
		fi
		
		LastDetect=$(echo ${LastDetectMsg} | awk -F']' '{print $NF}')
		echo -e '--------------------------------------------------------------------------------' >> ${USBinfo}.log
		${DMESG} | grep -iw "${USB30Addr[$u]}" | grep -iwFA20 "${LastDetect}" >> ${USBinfo}.log
		echo -e '--------------------------------------------------------------------------------\n\n' >> ${USBinfo}.log
		sync;sync;sync
		
	done
	echo "----------------------------------------------------------------------"
	echo " The information has been save in file: ${WorkPath}/${USBinfo}.log"

	if [ ${#pcb} != 0 ] ; then
		cat ${USBinfo}.log >> ../PPID/${pcb}.log
		sync;sync;sync
	fi

	echo -e '\n\n'
}

GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457

	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" | awk '{print $1}'| sed -n 1p | awk '{print $1}' | tr -d ': ')
	#BootDiskVolume=$( echo $BootDiskVolume | cut -c 1-$((${#BootDiskVolume}-1))) 
	BootDiskVolume=$(lsblk | grep -wB30 "`basename ${BootDiskVolume}`" | grep -iw "disk" | tail -n1 | awk '{print $1}')
	BootDiskVolume=$(echo "/dev/${BootDiskVolume}" )
	
	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $NF}')
}

ReadWriteTest ()
{
	local Mode=${1}
	PPIDKILL=$$
	rm -rf sd*.log NoDovice 2>/dev/null
	# USB1-UP|1-1.1|/dev/sda|2-1|/dev/sda|Pass --> ${CurRelationship}
	local DeviceAmount=$(cat ${CurRelationship} | wc -l )


	
	if [ ${ParallelNumber} != 1 ] ; then
		if [ ${Mode} == 'r' ] ; then
			printf "\e[1m%s\e[0m\n" "Begin to read test ..."
		else
			printf "\e[1m%s\e[0m\n" "Begin to write test ..."
		fi
		
		for ((c=1;c<=${DeviceAmount};c++))
		do
			local continueFlag=0
			local Usb20DeviceName=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $3}')
			local Usb30DeviceName=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $5}')
			if [ $(echo ${Usb20DeviceName} | grep -iwc "dev") == 0 ] || [ "${Usb20DeviceName}"x == "${BootDiskVolume}"x ] ; then
				let continueFlag++
			else
				local LogName=$(basename ${Usb20DeviceName})
				if [ ${Mode} == 'r' ] ; then
					rm -rf  ${LogName}_read.log 2>/dev/nul
					`dd if=${Usb20DeviceName} of=/dev/null bs=16k count=1000 iflag=direct > ${LogName}_read.log 2>&1` &
				else
					rm -rf  ${LogName}_write.log 2>/dev/nul
					`dd if=/dev/zero of=${Usb20DeviceName} bs=16k count=1000 oflag=direct > ${LogName}_write.log 2>&1` &
				fi
				printf "%s" "${Usb20DeviceName} "
			fi

			if [ $(echo ${Usb30DeviceName} | grep -iwc "dev") == 0 ] || [ "${Usb30DeviceName}"x == "${BootDiskVolume}"x ] ; then
				let continueFlag++
			else
				local LogName=$(basename ${Usb30DeviceName})
				rm -rf  ${LogName}.log 2>/dev/nul
				if [ ${Mode} == 'r' ] ; then
					`dd if=${Usb30DeviceName}  of=/dev/null bs=16k count=1000 iflag=direct > ${LogName}_read.log 2>&1` &
				else
					`dd if=/dev/zero of=${Usb30DeviceName} bs=16k count=1000 oflag=direct > ${LogName}_write.log 2>&1` &
				fi
				printf "%s" "${Usb30DeviceName} "
			fi
			
			[ ${continueFlag} == 2 ] && continue
			
			if [ $((c%ParallelNumber)) == 0 ] ; then
				for((s=1;s>0;s++))
				do
					#ChildenProcesses=($(pgrep -P ${PPIDKILL} hdparm))
					ChildenProcesses=($(pgrep -P ${PPIDKILL} dd))
					if [ ${#ChildenProcesses[@]} == 0 ] ; then
						echo
						break
					else
						sleep 1s
						printf "%s" ">"
						if [ $((s%70)) == 0 ] ; then
							printf "\r%s\r" "                                                                       "
						fi
					fi
				done
			fi
		done
		
		printf "\n%s\n" "Please wait a moment ..."
		for((s=1;s>0;s++))
		do
			ChildenProcesses=($(pgrep -P ${PPIDKILL} dd))
			if [ ${#ChildenProcesses[@]} == 0 ] ; then
				echo
				break
			else
				sleep 1s
				printf "%s" ">"
				if [ $((s%70)) == 0 ] ; then
					printf "\r%s\r" "                                                                       "
				fi
			fi
		done
		sync;sync;sync
		wait
	fi	
	
	if [ ${Mode} == 'r' ] ; then
		ShowTitle "USB Read function test"
	else
		ShowTitle "USB Write function test"
	fi
	#NO  Location           USB2.0 - ReadSpd       USB3.0 - ReadSpd   Result
	#-----------------------------------------------------------------------
	#01  USB2               1-11:  15 MB/s          2-1:  75 MB/s      Pass
	#02  USB3                1-2:  15 MB/s         2-12:  75 MB/s      Fail
	#-----------------------------------------------------------------------
	if [ ${Mode} == 'r' ] ; then
		printf "%-4s%-19s%-23s%-19s%-6s\n" "No" "Location"  "USB2.0 - ReadSpd"  "USB3.0 - ReadSpd" "Result"
	else
		printf "%-4s%-19s%-23s%-19s%-6s\n" "No" "Location"  "USB2.0 - WriteSpd"  "USB3.0 - WriteSpd" "Result"
	fi
	echo "------------------------------------------------------------------------"
	for ((c=1;c<=${DeviceAmount};c++))
	do
		local SubErrorFlag=0
		# USB1-UP|1-1.1|/dev/sda|2-1|/dev/sda|Pass --> ${CurRelationship}
		local UsbLocation=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $1}')
		local Usb20Addr=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $2}')
		local Usb20DeviceName=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $3}')
		local Usb30Addr=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $4}')
		local Usb30DeviceName=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $5}')
	
		printf "%02d%-2s%-19s" "${c}" "" "${UsbLocation}"
		local usbType=2
		for TestDeviceName in ${Usb20DeviceName} ${Usb30DeviceName}
		do
			local LogName=$(basename ${TestDeviceName})
			if [ $(echo ${TestDeviceName} | grep -iwc "dev") == 0 ] ; then
				if [ ${usbType} == 2 ] ; then
					printf "%7s%-16s" "${Usb20Addr}: " "0.00 MB/s"
					let usbType++
				else
					if [ ${SubErrorFlag} == 0 ] ; then
						printf "%7s%-13s\e[1;32m%-5s\e[0m\n" "${Usb30Addr}: " "0.00 MB/s" "Pass"
					else
						printf "%7s%-13s\e[1;31m%-5s\e[0m\n" "${Usb30Addr}: " "0.00 MB/s" "Fail"
						let ErrorFlag++
					fi
				fi
				continue
			fi
			
			if [ ${usbType} == 2 ] ; then
				printf "%7s" "${Usb20Addr}: "
			else
				printf "%7s" "${Usb30Addr}: "
			fi
				
			# Get the speed
			if [ ${ParallelNumber} != 1 ] ; then
				if [ ${Mode} == 'r' ] ; then
					cp -rf ${LogName}_read.log ${LogName}.log 2>/dev/null
				else
					cp -rf ${LogName}_write.log ${LogName}.log 2>/dev/null
				fi
			fi
			
			if [ ! -f "${LogName}.log" ] ; then
				#CurReadSpeed=$(hdparm -t ${TestDeviceName} 2>/dev/null | grep "MB/sec" | awk -F'=' '{print $2}' | awk -F'.' '{print $1}' | tr -d ' ')
				if [ ${Mode} == 'r' ] ; then
					CurSpeedUnit=$(dd if=${TestDeviceName} of=/dev/null bs=16k count=1000 iflag=direct 2>&1 | grep "copied" | awk -F', ' '{print $NF}')
				else
					CurSpeedUnit=$(dd if=/dev/zero of=${TestDeviceName} bs=16k count=1000 oflag=direct 2>&1 | grep "copied" | awk -F', ' '{print $NF}')
				fi
				CurSpeed=$(echo ${CurSpeedUnit} | awk '{print $1}')
				CurUnit=$(echo ${CurSpeedUnit} | awk '{print $NF}')
			else
				#CurReadSpeed=$(cat ${LogName}.log 2>/dev/nul | grep "MB/sec" | awk -F'=' '{print $2}' | awk -F'.' '{print $1}' | tr -d ' ')
				CurSpeed=$(cat ${LogName}.log 2>/dev/nul | grep "copied" | awk -F', ' '{print $NF}' | awk '{print $1}')
				CurUnit=$(cat ${LogName}.log 2>/dev/nul | grep "copied" | awk -F', ' '{print $NF}' | awk '{print $NF}')
			fi
			CurUnit=${CurUnit:-"MB/s"}
			
			if [ $(echo ${CurUnit} | grep -wc "MB/s") != 1 ] ; then
				let ErrorFlag++
			fi
			
			CurSpeed=${CurSpeed:-0.00}
			local StdSpeed_c=0
			if [ "${usbType}"x = "2x" ] ; then
				if [ ${Mode} == 'r' ] ; then
					StdSpeed_c=${Usb20MinReadSpeed}
				else
					StdSpeed_c=${Usb20MinWriteSpeed}
				fi
			else
				if [ ${Mode} == 'r' ] ; then
					StdSpeed_c=${Usb30MinReadSpeed}
				else
					StdSpeed_c=${Usb30MinWriteSpeed}	
				fi
			fi
			echo "${CurSpeed}>=${StdSpeed_c}" | bc | grep -wq "1"
			if [ $? == 0 ] ; then
				if [ ${usbType} == 2 ] ; then
					printf "%-16s" "${CurSpeed} ${CurUnit}"
					let usbType++
					continue
				else
					printf "%-13s\e[1;32m%-5s\e[0m\n" "${CurSpeed} ${CurUnit}" "Pass"
				fi	
			else
				if [ ${usbType} == 2 ] ; then
					printf "\e[1;31m%-16s\e[0m"  "${CurSpeed} ${CurUnit}"
					let SubErrorFlag++
					let usbType++
					continue
				else
					printf "\e[1;31m%-13s\e[0m\e[1;31m%-5s\e[0m\n" "${CurSpeed} ${CurUnit}" "Fail"
					let ErrorFlag++
				fi
			fi	
		done
	done
	echo "------------------------------------------------------------------------"
	[ ${ErrorFlag} != 0 ] && return 1
	rm -rf *.log 2>/dev/null
	return 0
}

main()
{	
	if [ ${DelayTime} -ge 2 ] ; then
		printf "%s\n" "Please plug in all USB test devices ..." 
		for((s=1;s<=$((DelayTime+3));s++))
		do
			read -t1 -n1 Wait
			[ ${#Wait} != 0 ] && break
			printf "%s" ">"
			if [ $((s%70)) == 0 ] ; then
				printf "\r%s\r" "                                                                       "
			fi

		done
		echo	
	fi

	for((t=1;t<=3;t++))
	do	
		# for Hot-plug, wait 5+ seconds
		ErrorFlag=0
		if [ $(echo "${ParseInfo}" | grep -iwc "enable") == 1 ] ; then
			ReadFirmware
		fi

		CheckAmount
		[ ${ErrorFlag} == 0 ] && break
		[ ${t} -lt 3 ] && Wait4nSeconds 5
	done
	
	if [ ${TestMode} == 'rw' ] ; then
		echo -e "\033[0;30;43m ******************************************************************** \033[0m"
		echo -e "\033[0;30;43m ***  USB 寫功能測試可能會破壞U 盤內的資料，請勿插上個人U 盤測試  *** \033[0m"
		echo -e "\033[0;30;43m ******************************************************************** \033[0m"
	fi
	
	if [ ${ErrorFlag} == 0 ] ; then
		case ${TestMode} in
		'r'|'read')
			ReadWriteTest 'r'
		;;
		
		'rw')
			ReadWriteTest 'r'
			ReadWriteTest 'w'
		;;
		*)
			:
		;;
		esac
	fi
	
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "USB2.0 & USB3.0 test"
		GenerateErrorCode
		exit 1
	else
		echoPass "USB2.0 & USB3.0 test"
	fi
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile
declare BootDiskSd BootDiskVolume
declare TestMode Usb20MinReadSpeed Usb30MinReadSpeed Usb20MinWriteSpeed Usb30MinWriteSpeed
declare USB2030Amount USB20Addr USB30Addr PcbMarking DetectUSB30Amount CurRelationship ParallelNumber
declare	USB20BlockAddr DetectUSB20Addr DelayTime
if [ "$(uname -r | grep -ic "^2")" == 1 ] ; then
	#Linux 6.x, old dmesg
	DMESG='dmesg'
else
	#Linux 7.x new dmesg, support the parameters 'T'
	DMESG='dmesg -T'
fi

#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:VdDx: argv
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
		
		d)
			while :
			do
				ForDebugGetUsbAddress
			done
		;;

		P)
			printf "%-s\n" "SerialTest,USB20andUSB30Test"
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
