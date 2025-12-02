#!/bin/bash
#FileName : CpuStress.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-07-31"
	local UpdatedDate="2020-11-18"
	local Description="Stress test for processors"
	
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
	printf "%2s%-12s%2s%-s\n" "" "Environment" ": " "Linux and ubuntu"
	printf "%2s%-12s%2s%-s\n" "" "History" ": " ""
	# 日期,修改内容
	printf "%16s%-s\n" "" "2020-11-18,exclude \"Not installed\" "
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
	ExtCmmds=(xmlstarlet pi md5sum basename)
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
`basename $0` [-x lConfig.xml] [-D]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V

	-D : Dump the sample xml config file	
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
		
	return code:
	   0 : CPU stress test pass
	   1 : CPU stress test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

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

			<!--计算到2的多少次方位数,需填写不大于26的正整数-->
			<NumBitsPI>24</NumBitsPI>
			<!--最大耗时,单位为秒-->
			<MaxRealTime>50</MaxRealTime>
			<!--超過這個時間(秒)則終止計算-->
			<TimeOut>60</TimeOut>
			<!--运行多少个程式-->
			<Copies>1</Copies>
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
	NumBitsPI=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/NumBitsPI" -n "${XmlConfigFile}" 2>/dev/null)
	MaxRealTime=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/MaxRealTime" -n "${XmlConfigFile}" 2>/dev/null)
	TimeOut=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/TimeOut" -n "${XmlConfigFile}" 2>/dev/null)
	Copies=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Copies" -n "${XmlConfigFile}" 2>/dev/null)
	
	if [ ${#NumBitsPI} == 0 ] ; then
		Process 1 "Digits of PI is not defined in the xml file"
		exit 3
	fi
	
	if [ ${NumBitsPI} -gt 26 ] ; then
		Process 1 "Number bits of PI is too great, NumBitsPI應該小於27..."
		exit 3
	fi
	
	if [ ${#TimeOut} == 0 ] ; then
		TimeOut=$((MaxRealTime+10))
	fi

	return 0			
}

VerifyPI()
{
	NumBits[0]='90d121718953ecf7f7cbc38ba3110504'
	NumBits[1]='90d121718953ecf7f7cbc38ba3110504'
	NumBits[2]='90d121718953ecf7f7cbc38ba3110504'
	NumBits[3]='90d121718953ecf7f7cbc38ba3110504'
	NumBits[4]='9fd68a216c4b589dcb94ee477a3ff9a2'
	NumBits[5]='d13878de056fd29d8f579948ceb86eb0'
	NumBits[6]='d1aa9bbba34b85b5ef580aa9f1e7559e'
	NumBits[7]='9c815ee360d9a2005a44fac03534978a'
	NumBits[8]='082be819fbfc94a3abf758ca33658075'
	NumBits[9]='2edc54f283ecd5f152e11a64834eb238'
	NumBits[10]='654db0fc1616766db2850a8fa8bf97e6'
	NumBits[11]='ec094d0657505dc69c142782a8949a82'
	NumBits[12]='3114f49056bc543501ff9e94a6ceb730'
	NumBits[13]='cf0d4c98090c4e6839874479dce55fe2'
	NumBits[14]='d2fe814fb3d1f05c3ef3297e1f44d188'
	NumBits[15]='e1f6d78544285cb92e47e095c2220988'
	NumBits[16]='02c212115bb98776656edacb1d4ac3b8'
	NumBits[17]='db8cd251d5e91768eb126e43248da73d'
	NumBits[18]='e4acc0d60f58b853e8c9810b5d017844'
	NumBits[19]='b776d71ac937a7823691183b04a2a424'
	NumBits[20]='af1e4f5523e33e68b1314809ea27e797'
	NumBits[21]='18906c4312902c29c2527f0fb636ec71'
	NumBits[22]='991b4a16f21ee23b145507bfd896b489'
	NumBits[23]='bc16695aeeda0e30c4ccdbaae9709190'
	NumBits[24]='36f4df5065b2384d5e3c21de91677304'
	NumBits[25]='400ab7e2e810599dd8e3a4f8f8ed53b9'
	NumBits[26]='798ca6f60ffb72a04734ceabb461e453'
	printf "%s\n" ""${NumBits[$1]}
}

GetCpuInfo()
{
	CurName=$(dmidecode -s processor-version | sort -u | grep -v "Not Installed" )
	CpuTypeCnt=$(dmidecode -s processor-version | grep -v "Not Installed" | sort -u | wc -l )
	CurCores=$(cat /proc/cpuinfo | grep -ic "processor")
	CurFrequency=$(dmidecode -t processor | grep -i "Current Speed:" | awk -F': ' '{print $2}'| tr -d '[[:alpha:]][[:punct:]] '| head -n1)
	FrequencyUnit=$(dmidecode -s processor-frequency | awk '{print $NF}' | head -n1 )
	CurL1Cache=$(lscpu | grep -iwE 'L1[A-Z] cache' | head -n 2 | awk -F ":" '{print $NF}' | tr -d "[[:alpha:]]" | awk '{print $1}' | awk '{sum+=$1}END{print sum}')
	CurL2Cache=$(lscpu | grep -iwE 'L2 cache' | head -n 1 | awk -F ":" '{print $NF}' | tr -d "[[:alpha:]]" | awk '{print $1}')
	CurL3Cache=$(lscpu | grep -iwE 'L3 cache' | head -n 1 | awk -F ":" '{print $NF}' | tr -d "[[:alpha:]]" | awk '{print $1}')
	
	#Cores和CPU的數量相對應
	PhysicalCnt=$(cat /proc/cpuinfo | grep -i "physical id" | sort -u | wc -l )
	
	if [ ${CpuTypeCnt} -ge 2 ]; then
		Process 1 "Found too many type of CPU ..."
		dmidecode -s processor-version | sort -u | grep -v "Not Installed"
		exit 1
	fi
	CurName=$(echo ${CurName} | awk '$1=$1')
	printf "%-23s%-2s%-s\n" "CPU model name" ":" "${CurName}"
	printf "%-23s%-2s%-s\n" "Physical CPU count" ":" "${PhysicalCnt} PCs"
	printf "%-23s%-2s%-s\n" "Processor count" ":" "${CurCores} PCs"
	printf "%-23s%-2s%-s\n" "Current Speed" ":" "${CurFrequency} ${FrequencyUnit}"
	printf "%-23s%-2s%-s\n" "L1 Cache Size" ":" "${CurL1Cache} MB"
	printf "%-23s%-2s%-s\n" "L2 Cache Size" ":" "${CurL2Cache} MB"
	printf "%-23s%-2s%-s\n" "L3 Cache Size" ":" "${CurL3Cache} MB"
	echo
	return 0
}

StressTest()
{
	local NumBitsPI=$1
	local Copies=$2
	
	printf "%s\n" "**********************************************************************"
	printf "%s\n" "*****              Processors stress test for linux              *****"
	printf "%s\n" "**********************************************************************"
	GetCpuInfo
	superPI=$(which pi | head -n1)
	chmod 777 ${superPI}
	PPIDKILL=$$
	SIDKILL=$$
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" INT
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" KILL
	printf "%-23s%-2s%-s\n" "PID" ":" "$$"
	CORE_NUM=$(grep -ic "^processor" /proc/cpuinfo) 
	LOGDIR=./superPI-Log
	DDPERCOPY_TIME=0.2s
	NumberOfBits=$(printf "%s\n" "2^${NumBitsPI}" | bc)
	mkdir -p ${LOGDIR}
	
	
	printf "%-23s%-2s%-s\n" "Working directory" ":" "${PWD}"
	printf "%-23s%-2s%-s\n" "Super PI" ":" "${superPI}"
	printf "%-23s%-2s%-s\n" "LOGs directory" ":" "${PWD}/`basename ${LOGDIR}`"
	printf "%-23s%-2s%-s\n" "Number bits of PI" ":" "${NumberOfBits}"
	echo
	printf "%-23s%-2s"      "Jobs started at date" ":"
	date "+%Y/%m/%d %H:%M:%S"
	echo

	########################
	# Run testing within a duration time.
	if [ 0 -ne ${TimeOut} ] || [ 0 -ne ${#TimeOut} ] ; then
	 	# prepareing the sleeping killers
		for((t=0;t<${TimeOut};t++))
		do
			ChildenProcesses=($(pgrep -P ${PPIDKILL} pi))
			if [ ${#ChildenProcesses[@]} != 0 ] ; then
				sleep 1s
			fi
		
			if [ ${t} -ge $((TimeOut-2)) ] && [ ${#ChildenProcesses[@]} != 0 ] ;then
				echo
				echo -n "End of testing(TIMEOUT)... "
				echo "KILL CHILD" && kill -9 $(pgrep -P ${PPIDKILL} pi) >/dev/null 2>&1 && echo "Childen processes - KILLED."
				# attention to how the pi are forked...
				#echo "KILL PARENT" && kill $$ && echo "KILLED." &  
				echo "Finished the calculating PI"
				printf "%-23s%-2s" "Jobs finished at date" ":"
				date "+%Y/%m/%d %H:%M:%S"
				echo TIMEOUT > ${LOGDIR}/TIMEOUT.txt
				sync;sync;sync
			fi
		done
	fi &
	
	echo -n "Waiting (PID: $$) for calculating PI"
	echo "..."
	while true
	do
		Processor_NUM=0
		echo -n "Super PI number: {"
		while [ ${Processor_NUM} -lt ${Copies} ]
		do
			echo -n " ${Processor_NUM} "

			${superPI} $((1<<${NumBitsPI})) 2>&1 >> ${LOGDIR}/${Processor_NUM}.log &
			sleep ${DDPERCOPY_TIME}
			Processor_NUM=$(expr $Processor_NUM + 1)
		done
		echo -n "}"
		
		printf "\n%s\n" "Please wait a moment ..."
		for((s=1;s>0;s++))
		do
			ChildenProcesses=($(pgrep -P ${PPIDKILL} pi))
			if [ ${#ChildenProcesses[@]} == 0 ] || [ ${s} -ge ${TimeOut} ]; then
				break
			else
				sleep 1s
				printf "%s" ">"
				if [ $((s%70)) == 0 ] ; then
					printf "\r%s\r" "                                                                       "
				fi
			fi
		
		done
		wait
		[ 0 -ne ${Copies} ] && break
	done
	
	########################
	echo	
	if [ 0 -ne ${Copies} ] && [ $(cat "${LOGDIR}/TIMEOUT.txt" 2>/dev/null | grep -iwc "TIMEOUT" ) == 0 ]  ; then
		echo -n "End of testing(Excution ended)... "
		#pkill -9 -P ${PPIDKILL}
		#kill $$
		echo "Finished the super PI"
		printf "%-23s%-2s" "Jobs finished at date" ":"
		date "+%Y/%m/%d %H:%M:%S"
	fi

	Result=($(md5sum pi*.txt 2>/dev/null))
	cp -rf ${Result[1]} /${Result[1]}  2>/dev/null
	rm -rf pi*.txt 2>/dev/null
	if [ ${#Result[@]} != 0 ] ; then
		printf "%s\n" "計算結果在/${Result[1]}, md5: ${Result[0]}"
		VerifyPI ${NumBitsPI} | grep -iwq "${Result[0]}"
		if [ $? == 0 ] ; then
			Process 0 "計算結果正確..."
		else
			Process 1 "計算結果錯誤..."
		fi
	fi
	
}

main()
{
	rm -rf superPI-Log  *.txt 2>/dev/null

	if [ ${#Copies} == 0 ] ; then
		Copies=$(grep -ic "^processor" /proc/cpuinfo)
	fi
	
	StressTest ${NumBitsPI} ${Copies}
	LogFilesCount=$(ls ${LOGDIR}/*.log | grep -iwc "log" )
	if [ ${LogFilesCount} != ${Copies} ] ; then
		Process 1 "Missing some log ..."
		let ErrorFlag++	
	fi
	
	echo -e "\n檢查real time是否小於${MaxRealTime}秒..."
	for((j=0;j<${Copies};j++))
	do
		if [ ! -f "${LOGDIR}/${j}.log" ] ; then
			Process 1 "No such file: ${LOGDIR}/${j}.log"
			let ErrorFlag++	
		else
			CurRealTime=$(grep -iw "real time" "${LOGDIR}/${j}.log" | awk '{print $1}')
			CurRealTimeUnit=$(grep -iw "real time" "${LOGDIR}/${j}.log" | awk '{print $2}')
			printf "%s\n" "${CurRealTime:-999999}-${MaxRealTime}<0" | bc | grep -iwq "1"
			Process $? "Super PI(${j})的real time 是: ${CurRealTime:-TimeOut} ${CurRealTimeUnit}" || let ErrorFlag++
		fi
	
	done
	
	echo	
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "CPU stress test"
	else
		echoFail "CPU stress test"
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
declare XmlConfigFile
declare NumBitsPI MaxRealTime Copies ApVersion
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
			printf "%-s\n" "SerialTest,CPUStressTest"
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
