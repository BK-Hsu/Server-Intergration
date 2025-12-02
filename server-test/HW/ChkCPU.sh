#!/bin/bash
#FileName : ChkCPU.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.3"
	local CreatedDate="2018-06-11"
	local UpdatedDate="2020-12-29"
	local Description="Get the specifications of the CPU "
	
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
	printf "%16s%-s\n" "" "2020-11-17,更新cache的檢查"
	printf "%16s%-s\n" "" "2020-12-29,更新物理个数的檢查"
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
	ExtCmmds=(xmlstarlet dmidecode lscpu)
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
`basename $0` [-x lConfig.xml] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml	
	-V : Display version number and exit(1)
	
	return code:
		0 : Get and compare cpu pass
		1 : Get and compare cpu fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<HW>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXCP2|Check the speed of CPU fail</ErrorCode>
			<!--ChkCPU.sh: CPU型號信息等檢測-->
			<!--PhysicalNumber: CPU的物理个数,缺省默认为1-->
			<!--Model: 用於區分板載不同的CPU測試,以防錯料-->
			<!--Frequency: 當前最小頻率-->
			<!--Stepping(僅針對SOC有效)/L#Cache缺省時不測試-->
			<PhysicalNumber>1</PhysicalNumber>
			<Case>
				<Model>609-S1511-010</Model>
				<Model>609-S1401-010</Model>
				<Name>Intel(R) Celeron(R) CPU 4205U @ 1.80GHz</Name>
				<Cores>2</Cores>
				<Frequency>1600 MHz</Frequency>
				<Stepping>C</Stepping>
				<L1Cache>128 KB</L1Cache>
				<L2Cache>512 KB</L2Cache>
				<L3Cache>2048 KB</L3Cache>
			</Case>
			
			<Case>
				<Model>609-S1511-020</Model>
				<Name>Intel(R) Xeon(R) Bronze 3104 CPU @ 1.70GHz</Name>
				<Cores>12</Cores>
				<Frequency>1700 MHz</Frequency>
				<Stepping>C</Stepping>
				<L1Cache>32 KB</L1Cache>
				<L2Cache>512 KB</L2Cache>
				<L3Cache>8196 KB</L3Cache>
			</Case>
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
	PhysicalNumber=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/PhysicalNumber" -n "${XmlConfigFile}")
	PhysicalNumber=${PhysicalNumber:-1}
	return 0
}

GetModel()
{
	if [ ${#ModelName} == 0 ] ; then
		CurProductModelName=$(cat ../PPID/MODEL.TXT 2>/dev/null | head -n1 )
	fi
	
	if [ ${#CurProductModelName} == 0 ] ; then
		CurProductModelName=$(dmidecode -s baseboard-product-name | sort -u )	
	fi
	return 0
}

GetCpuInfo()
{
	CurName=$(dmidecode -s processor-version | sort -u | grep -vi "Not installed")
	CpuTypeCnt=$(dmidecode -s processor-version | sort -u | grep -vi "Not installed" | wc -l )
	CurCores=$(cat /proc/cpuinfo | grep -ic "processor")
	CurFrequency=$(dmidecode -t processor | grep -i "Current Speed:" | awk -F': ' '{print $2}'| tr -d '[[:alpha:]][[:punct:]]'| head -n1)
	FrequencyUnit=$(dmidecode -s processor-frequency | awk '{print $NF}' | head -n1 )
	# L1,L2,L3 Cache caculation is different between ubuntu and centos
	#CurL1Cache=$(lscpu | grep -iwE 'L1[A-Z] cache' | head -n 2 | awk '{print $NF}' | tr -d "[[:alpha:]]" | awk '{sum+=$1}END{print sum}')
	#CurL2Cache=$(lscpu | grep -iwE 'L2 cache' | head -n 1 | awk '{print $NF}' | tr -d "[[:alpha:]]")
	#CurL3Cache=$(lscpu | grep -iwE 'L3 cache' | head -n 1 | awk '{print $NF}' | tr -d "[[:alpha:]]")
	
	#Cores和CPU的數量相對應
	PhysicalCnt=$(cat /proc/cpuinfo | grep -iw "physical id" | sort -u | wc -l )
	PhysicalCPUs=($(cat /proc/cpuinfo | grep -iw "physical id" | sort -u | awk -F': ' '{print $NF}'))
	CpuInstalled=CPU${PhysicalCPUs[0]}
	for((p=1;p<${#PhysicalCPUs[@]};p++))
	do
		CpuInstalled=$(echo "${CpuInstalled},CPU${PhysicalCPUs[p]}")
	done
	#僅對SoC有效
	CurStepping=$(lspci -s 00:00.0 | awk '{print $NF}' | tr -d '[[:punct:]]'| head -n1 )
	
	if [ ${CpuTypeCnt} -ge 2 ]; then
		Process 1 "Found too many type of CPU ..."
		dmidecode -s processor-version | sort -u | grep -vi "Not installed" 
		exit 1
	fi
	
	# 2020/11/16 update
	CurName=$(printf "%s\n" "${CurName}" | awk '$1=$1')
	
	printf "%s\n" "---------------"
	printf "%s\n" "CPU Information"
	printf "%s\n" "---------------"
	return 0
}

CpuInfoVerify()
{
	Cores=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[Name=\"${CurName}\"]/Cores" -n "${XmlConfigFile}" | head -n1)
	#主板Model型號
	if [ ${#Cores} != 0 ] ; then
		printf "%-20s%-2s" "Base board model" ":"
		StdProductModelName=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[Name=\"${CurName}\"]/Model" -n "${XmlConfigFile}" | head -n1)
		if [ ${#StdProductModelName} != 0 ] ; then
			xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[Name=\"${CurName}\"]/Model" -n "${XmlConfigFile}" | grep -iwq "${CurProductModelName:-NULL}"
			if [ $? == 0 ] ; then
				printf "\e[32m%s\e[0m\n" "${CurProductModelName}"
			else
				printf "\e[31m%s\e[0m%s\n" "${CurProductModelName}" " (${StdProductModelName})"
				let ErrorFlag++
			fi
		else
			printf "%s\n" "${CurProductModelName}"
		fi
	fi
	
	#物理个数
	printf "%-20s%-2s" "Physical number" ":"
	if [ "${PhysicalCnt}" == "${PhysicalNumber}" ] ; then
		printf "\e[32m%s\e[0m%s\n" "${PhysicalNumber} PCS" " (${CpuInstalled})"
	else
		printf "\e[31m%s\e[0m%s\n" "${PhysicalCnt} PCS (${CpuInstalled})" " (Expect: ${PhysicalNumber} PCS)"
		let ErrorFlag++
	fi
	
	#比對CPU名稱
	printf "%-20s%-2s%s\n" "Actual CPU Name" ":" "${CurName}"
	if [ ${#Cores} == 0 ] ; then
		Process 1 "CPU is out of specify ..."
		printf "%10s%s\n" "" "All below CPU models are supported:"
		for((i=1;i<=99;i++))
		do
			local CPUName=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[$i]/Name" -n "${XmlConfigFile}")
			[ ${#CPUName} == 0 ] && break
			printf "%10s%s%s\n" "" "<${i}>" " ${CPUName}"
			let ErrorFlag++
		done
		exit 1
	fi
	
	#Cores
	printf "%-20s%-2s" "Cores" ":"
	StdCores=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[Name=\"${CurName}\"]/Cores" -n "${XmlConfigFile}" | head -n1)
	echo ${StdCores} | grep -iwq "${CurCores:-'999'}"
	if [ $? == 0 ] ; then
		printf "\e[32m%s\e[0m%s\n" "${CurCores:-'null'} cores" " (${StdCores} cores)"	
	else
		printf "\e[31m%s\e[0m%s\n" "${CurCores:-'null'} cores" " (${StdCores} cores)"
		let ErrorFlag++
	fi
	
	#frequency
	StdFrequency=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[Name=\"${CurName}\"]/Frequency" -n "${XmlConfigFile}" | head -n1 | tr -d ' [[:alpha:]][[:punct:]]')
	CurFrequencySet=($(dmidecode -t processor | grep -i "Current Speed:" | awk -F': ' '{print $2}' | tr -d '[[:alpha:]][[:punct:]]'))
	FrequencyTest=0
	for((f=0;f<${#CurFrequencySet[@]};f++))
	do
		if [ ${CurFrequencySet[$f]} -lt ${StdFrequency:-99999999} ] ; then
			local SocketDesignation=$(dmidecode -t processor | grep -iw "Socket Designation" | sed -n $(($f+1))p | awk -F': ' '{print $NF}')
			if [ $f == 0 ] ; then
				printf "%-20s%-2s" "Frequency of Socket" ":"
				printf "%s\e[31m%s\e[0m%s\n" "${SocketDesignation}," " ${CurFrequencySet} ${FrequencyUnit}" " (${StdFrequency:-Undefined} ${FrequencyUnit})"
			else
				printf "%22s%s\e[31m%s\e[0m%s\n" "" "${SocketDesignation}," " ${CurFrequencySet} ${FrequencyUnit}" " (${StdFrequency:-Undefined} ${FrequencyUnit})"
			fi
			let ErrorFlag++
			let FrequencyTest++
		fi
	done
	if [ ${FrequencyTest} == 0 ] ; then
		printf "%-20s%-2s\e[32m%s\e[0m%s\n" "Frequency" ":" "${CurFrequencySet} ${FrequencyUnit}" " (${StdFrequency} ${FrequencyUnit})"
	fi
	
	#Stepping
	StdStepping=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Case[Name=\"${CurName}\"]/Stepping" -n "${XmlConfigFile}" | head -n1)
	if [ ${#StdStepping} != 0 ] ; then
		printf "%-20s%-2s" "Stepping" ":"
		echo "${StdStepping}" | grep -iwq "${CurStepping:-'null'}"
		if [ $? == 0 ] ; then
			printf "\e[32m%s\e[0m%s\n" "${CurStepping}" " (${StdStepping})"
		else
			printf "\e[31m%s\e[0m%s\n" "${CurStepping}" " (${StdStepping})"
			let ErrorFlag++
		fi
	fi
	
	#Hyperthreading
	SiblingsCnt=$(cat /proc/cpuinfo | grep -iw "siblings" | sort -u | awk -F':' '{print $2}' | tr -d ' ')
	CpuCoreCnt=$(cat /proc/cpuinfo  | grep -iw "cpu cores" | sort -u | awk -F':' '{print $2}' | tr -d ' ')
	if [ ${#SiblingsCnt} != 0 ] && [ ${SiblingsCnt} != 0 ] ; then
			printf "%-20s%-2s" "Hyperthreading" ":"
		let Gap=${SiblingsCnt}-${CpuCoreCnt}*2
		if [ "${Gap}"x == "0"x ]; then
			printf "%s\n" "Yes"
		else
			printf "%s\n" "No"
		fi	
	fi
	echo
}

main()
{
	GetModel
	GetCpuInfo
	CpuInfoVerify
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "CPU verify"
	else
		echoFail "CPU verify"
		GenerateErrorCode
		exit 1
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare CpuInstalled=''
declare XmlConfigFile ApVersion 
declare CurName CurCores CurFrequency FrequencyUnit CurL1Cache CurL2Cache CurL3Cache PhysicalCnt PhysicalNumber CurStepping 

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
			printf "%-s\n" "SerialTest,CheckCPU"
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
