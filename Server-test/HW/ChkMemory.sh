#!/bin/bash
#FileName : ChkMemory.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.4"
	local CreatedDate="2018-06-11"
	local UpdatedDate="2023-08-18"
	local Description="Get the specifications of the memory"
	
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
	printf "%16s%-s\n" "" "2020-11-02,可指定規格（容量/頻率/廠家）的內存條進行測試; 替換MT/s為MHz"
	printf "%16s%-s\n" "" "2020-11-17,新增ECC检查"
	printf "%16s%-s\n" "" "2023-02-22,新增内存容量单位依据读取实际单位设定，因为ubuntu下面显示单位为GB，Centos7.8下显示为MB "
	printf "%16s%-s\n" "" "2023-02-22,Centos8.4 下内存容量也显示为GB "
	printf "%16s%-s\n" "" "2023-08-18,ECC totalwidth 填实际的带宽，ECC 的totalwidth比datawidth 一般大8的倍数"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet )
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
Usage: 
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml	
	-V : Display version number and exit(1)
	
	return code:
		0 : Get and compare memory pass
		1 : Get and compare memory fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

ShowTitle()
{
	echo
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<HW>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXVIC|memory test fail</ErrorCode>
			<!-- ChkMemory.sh: 內存槽功能測試-->
			<!-- 填寫DDR2~4 -->
			<Generation>DDR4</Generation>
			
			<!--Single-bit ECC, Multi-bit ECC為ECC內存，None為non-ECC；其他值：Reserve/Other/Unknown/Parity/CRC-->
			<ErrorCorrectionType>Single-bit ECC</ErrorCorrectionType>
			<Specify>
				<!--以下定義後,程式將檢測實際所用的是否和定義的一致,不一致的判Fail-->
				<Capacity>2048</Capacity>
				<Frequency>2133</Frequency>
				<Manufacturer>Samsung</Manufacturer>
				<!--TotalWidth/DataWidth一般為8的倍數,寬度可被3整除的一般為ECC內存,反之為non-ECC;能被3整除的填0，否則填非0數值-->
				<TotalWidth>0</TotalWidth> 
				<DataWidth>0</DataWidth>
			</Specify>
			
			<!--Locator=BIOS或dmidecode設置的名稱,PcbMarking=[PCB絲印名稱]缺省的時候顯示dmidecode設置的名稱-->
			<!--LocatorItem: 使用哪個item定位，一般使用Bank Locator，或Locator(默認)-->
			<!--Locator(不能使用空格,帶有的空格的直接刪除空格如RAM slot #1應該寫為RAMslot#1)|PcbMarking-->
			<LocatorItem>Locator</LocatorItem>
			<DimmSlot>
				<LocatorPcbMarking>CPU1_DIMM_A1|CPU0_DIMM1</LocatorPcbMarking>
				<LocatorPcbMarking>CPU1_DIMM_A2|CPU0_DIMM2</LocatorPcbMarking>
			</DimmSlot>
		</TestCase>	
	</HW>
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
	SlotConfigFile=${BaseName}.ini
	rm -rf ${SlotConfigFile} 2>/dev/null
	xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/DimmSlot/LocatorPcbMarking" -n "${XmlConfigFile}" >${SlotConfigFile} 2>/dev/null
	DDRn=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Generation" -n "${XmlConfigFile}" 2>/dev/null)
	ErrorCorrectionType=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/ErrorCorrectionType" -n "${XmlConfigFile}" 2>/dev/null)
	LocatorItem=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/LocatorItem" -n "${XmlConfigFile}" 2>/dev/null)
	
	SpecCapacity=($(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Specify/Capacity" -n "${XmlConfigFile}" 2>/dev/null | tr -d "[[:alpha:]]" ))
	SpecFrequency=($(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Specify/Frequency" -n "${XmlConfigFile}" 2>/dev/null | tr -d "[[:alpha:]]" ))
	SpecManufacturer=($(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Specify/Manufacturer" -n "${XmlConfigFile}" 2>/dev/null))
	
	TotalWidth=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Specify/TotalWidth" -n "${XmlConfigFile}" 2>/dev/null)
	DataWidth=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Specify/DataWidth" -n "${XmlConfigFile}" 2>/dev/null)
	#if [ "${TotalWidth}"x != "0"x ] && [ ${#TotalWidth} != 0 ];then
	#	TotalWidth="1\|2"
	#fi
	if [ ${#DataWidth} != 0 ] && [ "${DataWidth}"x != "0"x ];then
		if [ "${DataWidth}"x != "64"x ];then
			Process 1 "DataWidth setting is wrong"
			exit 3
		fi
	fi
	if [ ${#TotalWidth} != 0 ] && [ "${TotalWidth}"x != "0"x ];then
		if [ $(echo $(((TotalWidth-64)%8)) | grep -iwc "0" ) != 1 ];then
			Process 1 "TotalWidth setting is wrong"
			exit 3
		fi
	fi

 	#if [ "${DataWidth}"x != "0"x ] && [ ${#DataWidth} != 0 ];then
	#	DataWidth="1\|2"
	#fi
	
	if [ ${#DDRn} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	
	return 0
}

ErrorCorrectionTypeCheck()
{
	#不設定則不需要測試
	[ ${#ErrorCorrectionType} == 0 ] && return 0
	
	#需要測試一致性
	local CurErrorCorrectionType=$(dmidecode -t 16 | grep -iw "Error Correction Type" | head -n1 | awk -F': ' '{print $NF}')
	if [ $(echo ${CurErrorCorrectionType} | grep -iwc "${ErrorCorrectionType}") == 0 ] ; then
		Process 1 "Error Correction Type is not match ..."
		printf "%10s%-s\n" "" "Expect: ${ErrorCorrectionType}, detected: ${CurErrorCorrectionType}"
		let ErrorFlag++
		exit 1
	else
		Process 0 "Error Correction Type is: ${ErrorCorrectionType}, verify pass" 
	fi
	return 0
}

DmidecodeTMemory ()
{
	local tempFolder=".${BaseName}"
	[ ! -d ${tempFolder} ] && mkdir -p ${tempFolder} 2>/dev/null 
	echo -e "\e[33m Get the memory infomation, please wait ...\e[0m"
	ErrorCorrectionTypeCheck
	
	<<-DIMM_Msg
	# dmidecode 3.0
	Scanning /dev/mem for entry point.
	SMBIOS 2.8 present.

	Handle 0x001A, DMI type 16, 23 bytes
	Physical Memory Array
		Location: System Board Or Motherboard
		Use: System Memory
		Error Correction Type: Single-bit ECC
		Maximum Capacity: 16 GB
		Error Information Handle: Not Provided
		Number Of Devices: 2

	Handle 0x001C, DMI type 17, 34 bytes
	Memory Device
		Array Handle: 0x001A
		Error Information Handle: Not Provided
		Total Width: 72 bits
		Data Width: 72 bits
		Size: 1024 MB
		Form Factor: DIMM
		Set: None
		Locator: CHANNEL0
		Bank Locator: BANK 0
		Type: DDR3
		Type Detail: Synchronous Unbuffered (Unregistered)
		Speed: 1333 MHz
		Manufacturer: Samsung
		Serial Number: 13121011
		Asset Tag:  BANK 0 CHANNEL0 AssetTag
		Part Number:                  
		Rank: 1
		Configured Clock Speed: 1333 MHz
	DIMM_Msg

	#########################################################
	<<-CostTooMuchTime
	FileID=0
	dmidecode -t MEMORY | while read LINE
	do
		if [ ${#LINE} == 0 ] ; then
			let FileID++
			rm -rf ${tempFolder}/${BaseName}-${FileID}.log
		else
			echo "${LINE}" >>${tempFolder}/${BaseName}-${FileID}.log
			sync;sync;sync
		fi
	done
	CostTooMuchTime
	#########################################################

	# Get the blank line number
	BlankLineID=($(dmidecode -t MEMORY | grep -n "^$" | tr -d ":" | tr "\n" " " ))
	for ((x=0,y=1;y<${#BlankLineID[@]};x++,y++))
	do
		rm -rf ${tempFolder}/${BaseName}-${y}.log 2>/dev/null
		dmidecode -t MEMORY | sed "s/MT\/s/MHz/g" | sed -n "${BlankLineID[$x]},${BlankLineID[$y]}"p >${tempFolder}/${BaseName}-${y}.log
		sync;sync;sync
	done

	# Remove the same file ${tempFolder}/${BaseName}-${y}.log
	rm -rf ${tempFolder}/*.list
	find ${WorkPath}/${tempFolder}  -maxdepth 1 -type f -print0 | xargs -0 md5sum | sort > ${WorkPath}/${tempFolder}/allfiles.list
	cat ${WorkPath}/${tempFolder}/allfiles.list | uniq -w 32 > ${WorkPath}/${tempFolder}/uniqfiles.list
	comm ${WorkPath}/${tempFolder}/allfiles.list ${WorkPath}/${tempFolder}/uniqfiles.list -2 -3 | cut -c 35- | tr '\n' '\0' | xargs -0 rm -rf 2>/dev/null 


	for EachLog in `ls ${tempFolder}/${BaseName}-*.log`
	do 
		grep -iq "Memory Device"  ${EachLog} || rm -rf ${EachLog}
	done

	<<-DIMM_Log
	Total Memory: 7791 MB
	Available Memory: 7532 MB
	Memory Devices:
	ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2133 MHz
	ChannelA-DIMM1 : <OUT OF SPEC>, 4096 MB, 2133 MHz
	ChannelB-DIMM0 : Unknown, No Module Installed, Unknown
	ChannelB-DIMM1 : Unknown, No Module Installed, Unknown
	DIMM_Log

	rm -rf ${BaseName}.log 2>/dev/null
	for EachLog in `ls ${tempFolder}/${BaseName}-*.log`
	do
		BiosMarking=$(grep -i "${LocatorItem:-Locator}"  ${EachLog} | head -n1 |awk -F':' '{print $2}'| tr -d ' ')
		BiosCapacity=$(grep -i "Size"  ${EachLog} | head -n1 | awk -F':' '{print $2}')
		BiosFrequency=$(grep -i "Speed"  ${EachLog} | head -n1 | awk -F':' '{print $2}')
		BiosManufacturer=$(grep -i "Manufacturer" ${EachLog} | head -n1 | awk -F':' '{print $2}')
		#2020/09/14 update
		BiosTotalWidth=$(grep -i "Total Width"  ${EachLog} | head -n1 | awk -F':' '{print $2}' | tr -d ' [[:alpha:]]')
		BiosDataWidth=$(grep -i "Data Width"  ${EachLog} | head -n1 | awk -F':' '{print $2}' | tr -d ' [[:alpha:]]')
		
		#ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2133 MHz
		echo "${BiosMarking} : <Dump in BIOS>, ${BiosCapacity},${BiosFrequency},${BiosManufacturer}, ${BiosTotalWidth:-nul}, ${BiosDataWidth:-nul}" >>${BaseName}.log
		sync;sync;sync
	done

	if [ ! -s ${BaseName}.log ] ; then
		Process 1 "No such file or 0 KB size of file: ${BaseName}.log"
		exit 2
	fi
}

DefineDDRSpec ()
{
	local DDRGen=$1
	# Usage: DefineDDRSpec [DDR2|2|DDR3|3|DDR4|4|DDR5|5]

	# Capacity : Unit GB
	# Frequency: Unit MHz
	case ${DDRGen:-"2"} in
		2|DDR2)
			Capacity=(512 1024 2048) 
			Frequency=(533 667 800)  
		;;

		3|DDR3)
			Capacity=(1024 2048 4096 8192) 
			Frequency=(800 1066 1333 1600 1866 2000)  
		;;

		4|DDR4)
			Capacity=(4 8 16 32) 
			Frequency=(2133 2400 2666 2667 2933 3000 3200) 
		;;

		5|DDR5)
			Capacity=(8 16 32 64) 
			Frequency=(3200 4800 5200 5400 6000 6400) 
		;;
		
		*)
			echo "Error parameters: $DDRGen"
			echo "DefineDDRSpec [ DDR2|2|DDR3|3|DDR4|4|DDR5|5 ]"
			exit 3
		;;
		esac
	
	if [ ${#SpecCapacity[@]} != 0 ] ; then
		Capacity=()
		Capacity=($(echo ${SpecCapacity[@]}))
	fi	
	
	if [ ${#SpecFrequency[@]} != 0 ] ; then
		Frequency=()
		Frequency=($(echo ${SpecFrequency[@]}))
	fi
		
	if [ ${#SpecManufacturer[@]} != 0 ] ; then
		Manufacturer=()
		Manufacturer=($(echo ${SpecManufacturer[@]}))
	fi
	
}

CheckMemoryAmount()
{
	DefineDDRSpec "${DDRn}"
	#去掉限制條件 grep -v "#" ,SlotConfigFile可以存在#的slot name
	LogMarking=($(cat -v ${SlotConfigFile} | grep -viE "^DDR[2-9]+$" | grep -ivw "Generation" | awk -F'|' '{print $1}'| tr -d ' '))
	PcbMarking=($(cat -v ${SlotConfigFile} | grep -viE "^DDR[2-9]+$" | grep -ivw "Generation" | awk -F'|' '{print $2}'))
	if [ ${#PcbMarking[@]} == 0 ] ; then
		PcbMarking=(echo ${PcbMarking[@]})
	fi

	<<-BiTLOG
	MEMORY
	Total Memory: 7791 MB
	Available Memory: 7532 MB
	Memory Devices:
	ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2133 MHz
	ChannelA-DIMM1 : <OUT OF SPEC>, 4096 MB, 2133 MHz
	ChannelB-DIMM0 : Unknown, No Module Installed, Unknown
	ChannelB-DIMM1 : Unknown, No Module Installed, Unknown
	BiTLOG
	
	
	# Initialize the DDRInstalled array
	DDRInstalled=()
	for ((a=0;a<${#LogMarking[@]};a++))
	do

		Found='NG'
		cat -v ${BaseName}.log | grep -iwq "${LogMarking[$a]}" 2>/dev/null
		if [ $? != 0 ] ; then
			DDRInstalled[$a]="${LogMarking[$a]}: NULL"
			Process 1 "No such name of DIMM slot: ${LogMarking[$a]}"
			let ErrorFlag++
			continue
		fi

		# LogMarking[0]=ChannelA-DIMM0"
		for ((b=0;b<${#Capacity[@]};b++))
		do
		
			for((c=0;c<${#Frequency[@]};c++))
			do
				
				# For this case: the same name of LogMarking, eg.: S1401
				# ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2133 MHz
				# ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2133 MHz			
				# DDRInstalled[$a]=ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2133 MHz
				let cnt=$(echo "${DDRInstalled[@]}" | sed s/': '/\\n/g | grep -ic "${LogMarking[$a]}")
				case ${cnt} in
				0)
					TempResult=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n 1p  | grep "${Capacity[$b]} [M|G]B, ${Frequency[$c]} MHz")
					CurCapacity=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n 1p | awk -F', ' '{print $2}' | tr -d ' [[:alpha:]]')
					CurFrequency=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n 1p | awk -F', ' '{print $3}' | tr -d ' [[:alpha:]]')
					CurManufacturer=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n 1p | awk -F', ' '{print $4}')
					CurTotalWidth=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n 1p | awk -F', ' '{print $5}')
					CurDataWidth=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n 1p | awk -F', ' '{print $6}')
				;;
				*)
					let cnt++
					TempResult=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n ${cnt}p  | grep "${Capacity[$b]} [M|G]B, ${Frequency[$c]} MHz")
					CurCapacity=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n ${cnt}p | awk -F', ' '{print $2}' | tr -d ' [[:alpha:]]')
					CurFrequency=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n ${cnt}p | awk -F', ' '{print $3}' | tr -d ' [[:alpha:]]')
					CurManufacturer=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n ${cnt}p | awk -F', ' '{print $4}')
					CurTotalWidth=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n ${cnt}p | awk -F', ' '{print $5}')
					CurDataWidth=$(cat -v ${BaseName}.log | grep -iw "${LogMarking[$a]}" | sed -n ${cnt}p | awk -F', ' '{print $6}')
				;;
				esac

				if [ "${TempResult}"x != "x" ] ; then
					Found='OK'
					break 2
				fi			
			done
		done

		if [ "${Found}" != "OK" ] ; then
			DDRInstalled[$a]="${LogMarking[$a]}: NULL, ${CurCapacity:-null} GB, ${CurFrequency:-null} MHz, ${CurManufacturer:-null}, ${CurTotalWidth}, ${CurDataWidth}"
			let OutOfSpecify++
		else
			DDRInstalled[$a]=${TempResult}
			let InstallAmount++
		fi			
	done
	#从正常侦测到的内存里面来确认内存容量的单位是MB还是GB，如果没有侦测到，则默认使用GB
	CapUnit=$(echo "${DDRInstalled[0]}" | awk -F',' '{print $2}' | awk '{print $2}')
	CapUnit=${CapUnit:-GB}
	if [ "$CapUnit" == "MB" ];then
		for ((i=0;i<${#Capacity[@]};i++))
		do
			Capacity[$i]=$((${Capacity[$i]}*1024))
		done
	fi	
	SoleCapacity=$(echo ${Capacity[@]} | sed 's/ /'${CapUnit}', /g')
	SoleFrequency=$(echo ${Frequency[@]} | sed 's/ /MHz, /g')
	printf "%s\n" "指定使用的內存條容量: ${SoleCapacity}${CapUnit}"
	printf "%s\n" "指定使用的內存條頻率: ${SoleFrequency}MHz"
	if [ ${InstallAmount} != ${#LogMarking[@]} ] ; then
		let ErrorFlag++
	else
		CheckAmount='pass'
	fi

	[ ${CheckAmount} == 'fail' ] && Process 1 "Check memory amount (installed: ${InstallAmount} PCs)"
	
	if [ ${#Manufacturer[@]} -gt 0 ] ; then
		SoleManufacturer=$(echo ${Manufacturer[@]} | sed 's/ /, /g')
		printf "%s\n" "指定使用的內存條廠家: ${SoleManufacturer}"
		AmountByManufacturer=0
		SoleManufacturer=$(echo "${Manufacturer[@]} QT" | sed 's/ /\\|/g')
		AmountByManufacturer=$(cat -v ${BaseName}.log | grep -iwc "${SoleManufacturer}")
		if [ ${AmountByManufacturer} != ${#LogMarking[@]} ] ; then				
			ExpectManufacturer=($(cat -v ${BaseName}.log | grep -iwv "${SoleManufacturer}" | awk -F', ' '{print $4}' | sort -u | grep -v "^$" | tr '\n' ',' ))		
			Process 1 "本次測試使用的內存條是指定以外的廠家: ${ExpectManufacturer} ..."
			let ErrorFlag++
		else
			Process 0 "本次測試使用了指定廠家的內存條: ${Manufacturer[@]}"
		fi
	fi
	
}

CheckMemorySpec ()
{
	for ((a=0;a<${#DDRInstalled[@]};a++))
	do
		# CurSpec[$a]="4096MB2133MHz"
		CurSpec[$a]=$(echo "${DDRInstalled[$a]}" | awk -F',' '{print $2$3}'| tr -d ' ')
	done

	<<-Tip
	4 4096MB2400MHz
	2 4096MB2133MHz
	2 8192MB2133MHz
	StdSpec=4096MB2400MHz
	Tip
	StdSpecAmount=$(echo "${CurSpec[@]}" | tr ' ' '\n'| sort -r | uniq -c | sort -nr | sed -n 1p | awk '{print $1}')
	if [ $StdSpecAmount == 1 ]  ; then
		StdSpec=$(echo "${CurSpec[@]}" | tr ' ' '\n'| sort -r | uniq -c | sort -ns | grep -i "Hz" | sed -n 1p | awk '{print $2}')

	else
		StdSpec=$(echo "${CurSpec[@]}" | tr ' ' '\n'| sort -s | uniq -c | sort -nr | grep -i "Hz" | sed -n 1p | awk '{print $2}')
	fi
	StdCap=$(echo "${StdSpec}" | awk -F"${CapUnit}" '{print $1}')  #4096
	StdFreq=$(echo "${StdSpec}" | awk -F"${CapUnit}" '{print $2}' | tr -d [A-Za-z]) #2400

	# No  Location       Cap.(MB)  Freq.(MHz)  Width(Bits) Manufacturer      P/F  
	# ---------------------------------------------------------------------------
	# 01  CPU0_DIMM1       4096       2133      72 / 72     Hynix            Pass
	# 02  CPU0_DIMM1       4096       2133      72 / 72     Hynix            Pass
	# 03  CPU0_DIMM1       4096       2133      72 / 72     Hynix            Pass
	# ---------------------------------------------------------------------------
	# Width(Bits): Total Width/Data Width
	local CurLogMarking=()
	if [ ${#DDRInstalled[@]} == 0 ] ; then
		Process 1 "No memory device(s) found, check the \"Locator\" setting ..."
		let ErrorFlag++
		exit 1
	fi
	
	ShowTitle "Memory function test"
	printf "%-4s%-15s%-10s%-12s%-12s%-18s%-4s\n" "No" "Location" "Cap.($CapUnit)" "Freq.(MHz)" "Width(Bits)" "Manufacturer" "P/F"
	echo "---------------------------------------------------------------------------"
	for ((a=0;a<${#DDRInstalled[@]};a++))
	do
		local SubFlag=0
		#ChannelA-DIMM0 : <OUT OF SPEC>, 8192 MB, 2133 MHz
		CurLogMarking[$a]=$(echo "${DDRInstalled[$a]}" | awk -F':' '{print $1}' | tr -d ' ')
		let CurLogMarkingCnt=$(echo ${CurLogMarking[@]} | tr ' ' '\n' | grep -ic "${CurLogMarking[$a]}")
		if [ ${CurLogMarkingCnt} -le 2 ]; then
			CurPcbMarking=$(cat -v ${SlotConfigFile} | tr -d ' ' | grep -iw "${CurLogMarking[$a]}" | awk -F'|' '{print $2}' | tr -d ' ' | sed -n ${CurLogMarkingCnt}p )
		else
			CurPcbMarking=$(cat -v ${SlotConfigFile} | tr -d ' ' | grep -iw "${CurLogMarking[$a]}" | awk -F'|' '{print $2}' | tr -d ' ' | sed -n $((a+1))p )
		fi

		if [ ${#CurPcbMarking} == 0 ] ; then
			CurPcbMarking=${CurLogMarking[$a]}
		fi
		
		# 1. DDRInstalled[$a]="${LogMarking[$a]}: NULL"
		echo "${DDRInstalled[$a]}" | grep -w "$CapUnit" | grep -wq "MHz"   
		if [ $? != 0 ] ; then
			printf "%02d%-2s\e[1;31m%-17s\e[0m%-11s%-10s%-12s%-17s%-4s\n" "$((a+1))"  "" "${CurPcbMarking}" "NULL"  "NULL"  "NUL/NUL" "NULL" "----"
			let ErrorFlag++
			let SubFlag++
			continue
		fi
		CurCap=$(echo "${DDRInstalled[$a]}" | awk -F',' '{print $2}'| tr -d ' [A-Za-z]')
		CurFreq=$(echo "${DDRInstalled[$a]}" | awk -F',' '{print $3}'| tr -d ' [A-Za-z]')
		CurManufacturer=$(echo "${DDRInstalled[$a]}" | awk -F', ' '{print $4}')
		CurTotalWidth=$(echo "${DDRInstalled[$a]}" | awk -F', ' '{print $5}')
		CurDataWidth=$(echo "${DDRInstalled[$a]}" | awk -F', ' '{print $6}')

		echo "${DDRInstalled[$a]}" | grep -iwq "${StdCap} $CapUnit, ${StdFreq} MHz"
		if [ $? != 0 ] ; then

			# 2.DDRInstalled[$a]="ChannelA-DIMM0 : <OUT OF SPEC>, 8192 MB, 2133 MHz"
			printf "%02d%-2s%-17s%-11s%-10s"  "$((a+1))"  "" "${CurPcbMarking}" "${CurCap:-Null}"  "${CurFreq:-Null}"
			let SubFlag++
		else
			# 3.DDRInstalled[$a]="ChannelA-DIMM0 : <OUT OF SPEC>, 4096 MB, 2400 MHz"
			printf "%02d%-2s%-17s%-11s%-10s" "$((a+1))"  "" "${CurPcbMarking}" "${CurCap:-Null}"  "${CurFreq:-Null}"
		fi
		
		# 4.Width verify
		if [ ${#TotalWidth} != 0 ] ; then
			if [ "${CurTotalWidth}"x != "nul"x ] ; then
				#if [ $(echo $((CurTotalWidth%3)) | grep -iwc "${TotalWidth}" ) == 1 ] ; then
				# ECC内存会比正常内存多8的倍数，所以对3取余这个方案不可行
				if [ "${CurTotalWidth}"x  == "${TotalWidth}"x ] ; then
					printf "%-3s" "${CurTotalWidth}"
				else
					printf "\e[31m%-3s\e[0m" "${CurTotalWidth}"
					let SubFlag++
				fi
			else
				printf "%-3s" "nul"
			fi
		else
			printf "%-3s" "${CurTotalWidth}"
		fi
		
		printf "%1s" "/"
		if [ ${#DataWidth} != 0 ] ; then
			if [ "${CurDataWidth}"x != "nul"x ] ; then
				#if [ $(echo $((CurDataWidth%3)) | grep -iwc "${DataWidth}" ) == 1 ] ; then
				if [ "${CurDataWidth}"x  == "${DataWidth}"x ] ; then
					printf "%3s" "${CurDataWidth}"
				else
					printf "\e[31m%3s\e[0m" "${CurDataWidth}"
					let SubFlag++
				fi
			else
				printf "%3s" "nul"	
			fi
		else
			printf "%3s" "${CurDataWidth}"
		fi	
		printf "%-5s" ""		
		
		# 5.CurManufacturer verify
		if [ ${#Manufacturer[@]} == 0 ] ; then
			printf "%-17s"  "${CurManufacturer:0:16}"
		else
			SoleManufacturer=$(echo "${Manufacturer[@]} QT" | sed 's/ /\\|/g')
			local Inlcude=$(echo "${CurManufacturer}" | grep -iwc "${SoleManufacturer}")
			if [ ${Inlcude} -gt 0 ] ; then
				printf "%-17s"  "${CurManufacturer:0:16}"
			else
				printf "\e[1;31m%-17s\e[0m"  "${CurManufacturer:0:16}"
				let SubFlag++
			fi
		fi
		
		if [ ${SubFlag} == 0 ] && [ ${OutOfSpecify} == 0 ]; then
			printf "\e[1;32m%-4s\e[0m\n" "Pass"
		else
			printf "\e[1;31m%-4s\e[0m\n" "Fail"
			let ErrorFlag++
		fi
		
	done
	echo "---------------------------------------------------------------------------"
	echo "Width(Bits): Total Width/Data Width"
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "The memory detection check"
		GenerateErrorCode
	else
		echoPass "The memory detection check"
		rm -rf ${BaseName}.log  ${BaseName}.ini  .${BaseName} 2>/dev/null
	fi
}

main()
{	
	DmidecodeTMemory
	CheckMemoryAmount
	CheckMemorySpec
	[ ${ErrorFlag} != 0 ] && exit 1
}	

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -i InstallAmount=0
declare -i OutOfSpecify=0
declare CheckAmount='fail'
declare XmlConfigFile SlotConfigFile DDRn LocatorItem SpecCapacity SpecFrequency SpecManufacturer ApVersion
declare PcbMarking LogMarking Capacity Frequency Manufacturer TotalWidth DataWidth ErrorCorrectionType
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
			printf "%-s\n" "SerialTest,CheckMemory"
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
