#!/bin/bash
#FileName : MemStress.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2020-07-27"
	local UpdatedDate="2020-07-27"
	local Description="Stress test for memory"
	
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
	#printf "%16s%-s\n" "" " , "
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
	ExtCmmds=(xmlstarlet memtester )
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
	   0 : Memory stress test pass
	   1 : Memory stress test fail
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
				<ErrorCode>TXVIC|memory test fail</ErrorCode>
				
				<!--測試內存的容量大小,單位M或G,請勿使用全部內存測試否則可能造成宕機或FAIL；也可以填寫百分比如60%-->
				<Size>60%</Size>
				<!--測試循環次數，Loop和CycleTime只能任選其一，同時填寫Loop有效；置空CycleTime有效-->
				<Loop>1</Loop>
				<!--CycleTime:測試時間，h/m/s: 小時/分鐘/秒，Loop和CycleTime只能任選其一，同時填寫Loop有效-->
				<CycleTime>1m</CycleTime>
				
				<!--運行多少個memtester,建議填寫為CPU核心個數值的約數值,置空則自動使用CPU最大核心數量-->
				<Copies>1</Copies>
				<FunctionList>
					<!--memtester自定義功能測試列表; 1:表示該項目測試; 0: 不測試-->
					<StuckAddress>1</StuckAddress>
					<RandomValue>1</RandomValue>
					<CompareXOR>1</CompareXOR>
					<CompareSUB>1</CompareSUB>
					<CompareMUL>1</CompareMUL>
					<CompareDIV>1</CompareDIV>
					<CompareOR>1</CompareOR>
					<CompareAND>1</CompareAND>
					<SequentialIncrement>1</SequentialIncrement>
					<SolidBits>1</SolidBits>
					<BlockSequential>1</BlockSequential>
					<Checkerboard>1</Checkerboard>
					<BitSpread>1</BitSpread>
					<BitFlip>1</BitFlip>
					<WalkingOnes>1</WalkingOnes>
					<WalkingZeroes>1</WalkingZeroes>
					<_8bitWrites>1</_8bitWrites>
					<_16bitWrites>1</_16bitWrites>
				</FunctionList>
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
	Size=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Size" -n "${XmlConfigFile}" 2>/dev/null)
	Loop=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Loop" -n "${XmlConfigFile}" 2>/dev/null)
	CycleTime=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/CycleTime" -n "${XmlConfigFile}" 2>/dev/null)
	Copies=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/Copies" -n "${XmlConfigFile}" 2>/dev/null)
	Function=(StuckAddress RandomValue CompareXOR CompareSUB CompareMUL CompareDIV CompareOR CompareAND SequentialIncrement SolidBits BlockSequential Checkerboard BitSpread BitFlip WalkingOnes WalkingZeroes _8bitWrites _16bitWrites)
	for((f=0;f<${#Function[@]};f++))
	do
		local TestOrNot=$(xmlstarlet sel -t -v "//HW/TestCase[ProgramName=\"${BaseName}\"]/FunctionList/${Function[f]}" -n "${XmlConfigFile}" 2>/dev/null)
		if [ ${#TestOrNot} != 1 ] ; then
			Process 1 "Invalid ${Function[f]} setting: ${TestOrNot}"
			let ErrorFlag++
			continue
		fi
		FunctionList=${FunctionList}${TestOrNot:-"0"}	
	done
	[ ${ErrorFlag} != 0 ] && exit 3
	if [ ${#FunctionList} -lt 18 ] ; then
		Process 1 "Error function list in xml config file"
		exit 3
	fi
	
	if [ ${#Size} == 0 ] ; then
		Process 1 "Size is not defined in the xml file"
		exit 3
	fi

	return 0			
}

ShowHelp ()
{
	cat <<-EOFshow_HELP >&2
	Usage: $(basename ${0})
	-c NUMBER: the copies of memtester should be run
	-m NUMBER: how many memory should be tested totally (in MB) -t TIME: duration mode, how long will the tests go
	-l NUMBER: loops mode,how many loops will each memtester should go
	   The option -t and -l are exclusive, which means tests could work only with 1. duration mode or 2. loops mode
	   
	RUN 4 copies memtester with in 24 hours, to test total 4000 MB memory:
	StressTest -t 24h -c 4 -m 4000

	RUN 2 copies memtester with in 1 hours, to test total 4000 MB memory:
	StressTest -t 1h -c 4 -m 4000

	RUN 4 copies memtester with in 2 loops, to test total 3600 MB memory:
	StressTest -l 2 -c 4 -m 3600

	-V/-h/-H: show this info.
	EOFshow_HELP
	exit 255
}

StressTest()
{
	printf "%s\n" "**********************************************************************"
	printf "%s\n" "*****                Memory stress test for linux                *****"
	printf "%s\n" "**********************************************************************"
	MEMTESTER=$(which memtester | head -n1)
	chmod 777 ${MEMTESTER}
	PPIDKILL=$$
	SIDKILL=$$
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" INT
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" KILL

	CORE_NUM=$(grep -ic "^processor" /proc/cpuinfo) 
	MEMTESTERCOPY=${CORE_NUM}
	MEM_TOTAL_K=$(awk '/^MemTotal/{print $2}' /proc/meminfo) 
	MEM_RESERVE_PERCENTAGE=$((1000*50/1024)) # 95%
	MEM_RESERVED=$((MEM_TOTAL_K/1024*MEM_RESERVE_PERCENTAGE/1000)) 
	MEM_TOTAL_TOBETESTED=$((MEM_TOTAL_K/1024-MEM_RESERVED))
	MEM_PER_COPY=$((MEM_TOTAL_TOBETESTED/MEMTESTERCOPY))
	RUN_DURATION_TIME=0
	RUN_LOOPS=-1
	RUN_DURATION_TIME_FLAG=0
	RUN_LOOPS_FLAG=0
	DDPERCOPY_TIME=0.2s
	LOGDIR=./memtester-Log
	mkdir -p ${LOGDIR}

	while getopts :d:c:m:t:l:hHV OPTION
	do
		case ${OPTION} in
			c)
				#echo "-c ${OPTARG}"
				MEMTESTERCOPY=${OPTARG}
			;;
			
			m)
				#echo "-m ${OPTARG} MB"
				MEM_TOTAL_TOBETESTED=${OPTARG}
				MEM_RESERVED=$((MEM_TOTAL_K/1024-MEM_TOTAL_TOBETESTED))
			;;
			
			t)
				#echo "-t ${OPTARG}"
				[ 0 -ne ${RUN_LOOPS_FLAG} ] && echo "-t and -l are exclusive." && exit 222
				RUN_DURATION_TIME=${OPTARG}
				RUN_DURATION_TIME_FLAG=1
			;;
			
			l)
				#echo "-l ${OPTARG}"
				[ 0 -ne ${RUN_DURATION_TIME_FLAG} ] && echo && echo "-t and -l are exclusive." && ShowHelp && echo && exit 223
				RUN_LOOPS=${OPTARG};
				RUN_LOOPS_FLAG=1
			;;
			
			V|h|H)
				ShowHelp
			;;
			
			?) echo "Error...";
				echo "?Unknown args..."
				exit 224
			;;
			
			*) #echo "*Unknown args..."
			esac
	done

	#exit
	if [ 0 -eq ${RUN_DURATION_TIME_FLAG} ] && [ 0 -eq ${RUN_LOOPS_FLAG} ] ; then
		echo 
		echo "Please specified which mode should we run... -t or -l" 
		ShowHelp 
		exit 225
	fi
	
	MEM_PER_COPY=$((MEM_TOTAL_TOBETESTED/MEMTESTERCOPY))
	printf "%-23s%-2s%-s\n" "Mem total" ":" "$((MEM_TOTAL_K/1024)) MB"
	printf "%-23s%-2s%-s\n" "Core total" ":" "${CORE_NUM} PCs"
	printf "%-23s%-2s%-s\n" "Memtester copys" ":" "${MEMTESTERCOPY}"
	printf "%-23s%-2s%-s\n" "Mem per copy" ":" "${MEM_PER_COPY} MB"
	printf "%-23s%-2s%-s\n" "Mem total to used" ":" "${MEM_TOTAL_TOBETESTED} MB"
	if [ ${MEM_RESERVED} -lt 1 ];then
		printf "%-23s%-2s%-s\n" "Mem reserved" ":" "-- No more memory reserved..."
	else
		printf "%-23s%-2s%-s\n" "Mem reserved" ":" "${MEM_RESERVED} MB"
	fi
	
	#exit
	# GOGOGO
	if [ 0 -ne ${RUN_DURATION_TIME_FLAG} ]; then
		printf "%-23s%-2s%-s\n" "Run within a duration" ":" "${RUN_DURATION_TIME}"
	elif [ 0 -ne ${RUN_LOOPS_FLAG} ]; then
		printf "%-23s%-2s%-s\n" "Run within a loop" ":" "${RUN_LOOPS}"
	fi
	
	printf "%-23s%-2s%-s\n" "PID" ":" "$$"
	printf "%-23s%-2s%-s\n" "Working directory" ":" "${PWD}"
	printf "%-23s%-2s%-s\n" "Memtester" ":" "${MEMTESTER}"
	printf "%-23s%-2s%-s\n" "LOGs directory" ":" "${PWD}/`basename ${LOGDIR}`"
	echo
	printf "%-23s%-2s"      "Jobs started at date" ":"
	date "+%Y/%m/%d %H:%M:%S"
	echo
	#exit
	########################
	# Run testing within a duration time.
	if [ 0 -ne ${RUN_DURATION_TIME_FLAG} ] ; then
		# prepareing the sleeping killers
		sleep ${RUN_DURATION_TIME}
		echo
		echo -n "End of testing(TIMEOUT)... "
		echo "KILL CHILD" && kill -9 $(pgrep -P ${PPIDKILL} memtester) && echo "Childen processes - KILLED."
		# attention to how the memtesters are forked...
		#echo "KILL PARENT" && kill $$ && echo "KILLED." &  
		echo "Finished the memtester"
		printf "%-23s%-2s" "Jobs finished at date" ":"
		date "+%Y/%m/%d %H:%M:%S"
	fi &
	echo -n "Waiting (PID: $$) for ${MEMTESTERCOPY} memtesters(${MEM_PER_COPY}MB for each). "
	if [ 0 -ne ${RUN_DURATION_TIME_FLAG} ]; then
		echo -n "For time: ${RUN_DURATION_TIME} "
	fi
	if [ 0 -ne ${RUN_LOOPS_FLAG} ];then
		echo -n "For loops: ${RUN_LOOPS} "
	fi
	echo "..."
	while true
	do
		MEMTESTER_NUM=0
		echo -n "Memtester number: {"
		while [ ${MEMTESTER_NUM} -lt ${MEMTESTERCOPY} ]
		do
			echo -n " ${MEMTESTER_NUM} "
			if [ 0 -ne ${RUN_DURATION_TIME_FLAG} ];then
				RUN_LOOPS=0
			fi
			${MEMTESTER} ${MEM_PER_COPY} ${RUN_LOOPS} "${FunctionList}" 2>&1 >> ${LOGDIR}/${MEMTESTER_NUM}.log &
			# set loops = 0 to make memtester run loop infinitely... # .pogo version will run only one loop by default
			sleep ${DDPERCOPY_TIME}
			MEMTESTER_NUM=$(expr $MEMTESTER_NUM + 1)
		done
		echo -n "}"
		
		printf "\n%s\n" "Please wait a moment ..."
		for((s=1;s>0;s++))
		do
			memtesterPID=($(pgrep -P ${PPIDKILL} memtester))
			if [ ${#memtesterPID[@]} == 0 ]; then
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
		[ 0 -ne ${RUN_LOOPS_FLAG} ] && break
		[ 0 -ne ${RUN_DURATION_TIME_FLAG} ] && break
		# memtesters' loops...
	done
	
	########################
	echo
	if [ 0 -ne ${RUN_LOOPS_FLAG} ] ; then
		echo -n "End of testing(Excution ended)... "
		#pkill -9 -P ${PPIDKILL}
		#kill $$
		echo "Finished the memtester"
		printf "%-23s%-2s" "Jobs finished at date" ":"
		date "+%Y/%m/%d %H:%M:%S"
	fi
}

main()
{
	rm -rf memtester-Log 2>/dev/null
	if [ ${#CycleTime} != 0 ] ; then
		echo ${CycleTime} | tr -d "[0-9]" | grep -iwq "[HMS]"
		if [ $? != 0 ]; then
			Process 1 "Invalid test time for memtester ..."
			exit 3
		fi
	fi

	if [ ${#Copies} == 0 ] ; then
		Copies=$(grep -ic "^processor" /proc/cpuinfo)
	fi
	
	local SizeUnit=$(echo ${Size} | tr -d '[0-9]' | tr '[a-z]' '[A-Z]')
	TotalSize=$(free -h | grep -iw "^Mem" |sed 's/i//g' | awk '{print $2}')
	SizeVale=$(echo ${Size} | tr -d '[[:alpha:]][[:punct:]]')
	case ${SizeUnit} in
		'M')
			:
		;;
		
		'G')SizeVale=$((${SizeVale}*1024));;
		
		'%')
			
			Unit=$(echo ${TotalSize} | tr -d '[0-9]' | tr '[a-z]' '[A-Z]')
			if [ $(echo ${Unit} | grep -ic "G" ) == 1 ] ; then
				TotalSize=$(echo ${TotalSize} | tr -d '[[:alpha:]]')
				TotalSize=$((${TotalSize}*1024))
			elif [ $(echo ${Unit} | grep -ic "M" ) == 1 ] ; then
				TotalSize=$(echo ${TotalSize} | tr -d '[[:alpha:]]')
			else
				Process 1 "Error total size of memory: ${TotalSize}"
				exit 3
			fi
			#總容量x60÷100(即60%)
			SizeVale=$((${TotalSize}*${SizeVale}/100))
		;;
		
		*)
			Process 1 "Invalid test size: ${Size}"
			exit 3
		;;
	esac
	
	if [ ${#Loop} == 0 ] ; then
		StressTest -d DEBUG -t ${CycleTime:-"1m"} -c ${Copies} -m ${SizeVale}
		let OkCount=${Copies}*1
	else
		StressTest -d DEBUG -l ${Loop:-"1"} -c ${Copies} -m ${SizeVale}
		let OkCount=${Copies}*${Loop}
	fi
	
	echo "Verify the test items:"
	for((t=0;t<${#FunctionList};t++))
	do
		FunctionListBit=${FunctionList:$t:1}
		if [ ${FunctionListBit} == 0 ]; then
			printf "%-10s\e[37m%-60s\e[0m\n" "" "${CheckList[t]} not test ..."
			continue
		else
			TestOkCount=$(cat ./memtester-Log/*.log | grep -iw "${CheckList[t]}" | grep -iwc "ok")
			if [ ${TestOkCount} -ge ${OkCount} ] ; then
				Process 0 "${CheckList[t]} test pass ..."
			else
				Process 1 "${CheckList[t]} test fail ..."
				let ErrorFlag++				
			fi
		fi
	done
	
	echo	
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "Memory stress test"
	else
		echoFail "Memory stress test"
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
declare Size Loop CycleTime Copies Function FunctionList ApVersion
declare CheckList=('Stuck Address' 'Random Value' 'Compare XOR' 'Compare SUB' 'Compare MUL' 'Compare DIV' 'Compare OR' 'Compare AND' 'Sequential Increment' 'Solid Bits' 'Block Sequential' 'Checkerboard' 'Bit Spread' 'Bit Flip' 'Walking Ones' 'Walking Zeroes' '8-bit Writes' '16-bit Writes')
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
			printf "%-s\n" "SerialTest,MemoryStressTest"
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
