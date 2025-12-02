#!/bin/bash
#FileName : eeprom_c.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.2"
	local CreatedDate="2018-05-28"
	local UpdatedDate="2020-12-31"
	local Description="Compare eeprom version on line"
	
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
	printf "%16s%-s\n" "" "2020-12-29,Support serial test mode"
	printf "%16s%-s\n" "" "2020-12-30,支持版本指定为null不检查,以便在I340/E810等網卡測試中節約測試時間"
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
`basename $0` [-x lConfig.xml] [-DV]
`basename $0` -D
	eg.: `basename $0` -x lConfig.xml
		 `basename $0` -D
		 `basename $0` -V

	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Compare eeprom version pass
		1 : Compare eeprom version fail
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
			<ProgramName TestMode="Parallel">${BaseName}</ProgramName>
			<ErrorCode>EXF17|LAN function test fail</ErrorCode>
			<!--範例說明
				<NicIndex>1:不接任何網卡時其Nic號</NicIndex>
				<Chipset>I354</Chipset>
				<EepromVer>1.8,不需要检查的填写null</EepromVer>
			-->	
			<Card>
				<NicIndex>1</NicIndex>
				<Chipset>I354</Chipset>
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
	NicIndex=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/NicIndex" -n "${XmlConfigFile}" 2>/dev/null))
	LanChipset=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/Chipset" -n "${XmlConfigFile}" 2>/dev/null))
	TestMode=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ProgramName[.=\"${BaseName}\"]/@TestMode" -n "${XmlConfigFile}" 2>/dev/null | tr "[A-Z]" "[a-z]")
	TestMode=${TestMode:-"parallel"}	
	TotalAmount="${#NicIndex[@]}"

	if [ ${#NicIndex} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

ShowTitle()
{
	echo 
	local BlankCnt=0
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

Wait4nSeconds()
 {
	local second=$1
	local Items=$2

	#如果查看的當前項目不是fail項則不再提示如下信息
	if [ $(cat -v ./logs/${ShellNameSawLog}.log 2>/dev/null | grep -ic "${ShellNameSawLog}.sh test fail") == 1 ] && [ $(cat ./logs/${ShellNameSawLog}.temp 2>/dev/null | tail -n 1 |  grep -ic "1") == 1 ] ; then
		ShowMsg --b  "[R/r] To retest: ${Items}"
		ShowMsg --e  "Other any key to continue."
	fi

	# Wait for OP n secondes,and auto to run
	for ((p=${second};p>=0;p--))
	do
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]; then	
			if [ $(echo "R" | grep -ic "${Ans}" ) == 1 ] && [ $(cat -v ./logs/${ShellNameSawLog}.log 2>/dev/null | grep -ic "${ShellNameSawLog}.sh test fail") == 1 ] && [ $(cat ./logs/${ShellNameSawLog}.temp 2>/dev/null | tail -n 1 |  grep -ic "1") == 1 ] ; then
				rm -rf ./logs/${ShellNameSawLog}.temp 2>/dev/null
				break
			else
				break
			fi
		else
			continue
		fi
	done
	echo ''

	#如果在倒計時20秒內查看log,退出后需要再顯示一次測試結果
	if [ $t -le 0 ] ; then
		ShowMTProcess | tee ${WorkPath}/logs/${BaseName}.log
	fi
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

#在命令行下運行，也可以在圖形介面下運行
#需要和ShowTestResultOnScreem搭配
MTinCommandline()
{
	for ((s=0;s<${#ShellsSet[@]};s++))
	do
		#${ShellsSet[$s]}=../ast2500/hwmon.sh ==> ShellName[$s]=hwmon.sh
		ShellName[$s]=$(echo ${ShellsSet[$s]} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
		ExecuteBackground=$(ps ax | grep -w "${ShellName[$s]}\|celo64e\|eeupdate64e" | grep -v "grep" )
		
		if [ "$t" == "${CycleTime}" ] && [ "${RemoveRecord}"x == 'enable'x ]; then
			rm -rf ./logs/${ShellName[$s]}.log ./logs/${ShellName[$s]}.temp 2>/dev/null
			echo 'test' > ./logs/${ShellName[$s]}.temp
			RemoveRecord='disable'
		fi
		
		#按測試項目測試,所有的測試項目測試完成1個cycle就退出
		if [ "${TestMethod}"x == 'byitem'x ] ; then
			if [ $(echo "${ExecuteBackground}" | grep -ic "${ShellName[$s]}" ) != 0 ] || [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null |  grep -c "0\|1") != 0 ] ; then  
				:
			else
				
				`{
					{ 
						echo -n "${ShellName[$s]}.sh start to run in: "
						date "+%Y-%m-%d %H:%M:%S  %z"
						if [ "${OSType}"x == "ubuntu"x ]; then
							bash ${ShellsSet[$s]} -x ${XmlConfig}
						else
							sh ${ShellsSet[$s]} -x ${XmlConfig}
						fi
						
						if [ $? == 0 ] ; then
							echo 0 > ./logs/${ShellName[$s]}.temp
							echo -n "${ShellsSet[$s]} test pass in: "
							date "+%Y-%m-%d %H:%M:%S %Z"
						else
							echo 1 > ./logs/${ShellName[$s]}.temp
							echo -n "${ShellsSet[$s]} test fail in: "
							date "+%Y-%m-%d %H:%M:%S %Z"
							
							# for failure Locking or Upload
							grep -wq "${ShellName[$s]}.sh" "../PPID/FAILITEM.TXT" 2>/dev/null || echo "${ShellName[$s]}.sh" > ../PPID/FAILITEM.TXT
						fi
						echo "----------------------------------------------------------------------"
						sync;sync;sync;
					} > ./logs/${ShellName[$s]}.log 2>&1 
				}` &
			fi
		fi

		#按測試時間循環測試
		if [ "${TestMethod}"x == 'byct'x ] ; then
			if [ $(echo "${ExecuteBackground}" | grep -ic "${ShellName[$s]}" ) == 0 ] && [ $t -gt 0 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | tail -n1 | grep -ic '1') != 1 ] ; then
			
				#NCIS,燒錄的程式只需要運行一次即可
				if [ $(echo ${ShellName[$s]} | grep -ic "_w") -gt 0 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp | grep -ic "0\|1") ] ; then
					continue
				fi
				
				#回路測試要提前100秒結束
				if [ $(echo ${ShellName[$s]} | grep -ic "lan") -gt 0 ] && [ $t -le 100 ] ; then
					continue
				fi
				
				`{
					{ 					
						echo -n "${ShellName[$s]}.sh start to run in: "
						date "+%Y-%m-%d %H:%M:%S  %z"
						echo 'test' >> ./logs/${ShellName[$s]}.temp
						
						if [ "${OSType}"x == "ubuntu"x ]; then
							bash ${ShellsSet[$s]} -x ${XmlConfig}
						else
							sh ${ShellsSet[$s]} -x ${XmlConfig}
						fi
						
						if [ $? == 0 ] ; then
							echo 0 >> ./logs/${ShellName[$s]}.temp
							echo -n "${ShellsSet[$s]} test pass in: "
							date "+%Y-%m-%d %H:%M:%S %Z"
						else
							echo 1 >> ./logs/${ShellName[$s]}.temp
							echo -n "${ShellsSet[$s]} test fail in: "
							date "+%Y-%m-%d %H:%M:%S %Z"
							
							# for failure Locking or Upload
							grep -wq "${ShellName[$s]}.sh" "../PPID/FAILITEM.TXT" 2>/dev/null || echo "${ShellName[$s]}.sh" > ../PPID/FAILITEM.TXT
						fi
						
						echo
						OKCnt=$(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | grep -ic '0' )
						NGCnt=$(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | grep -ic '1' )
						let TTLCnt=${OKCnt}+${NGCnt}
						echo "${ShellsSet[$s]} test cycle: ${TTLCnt}, pass: ${OKCnt}, fail: ${NGCnt}"
						echo "----------------------------------------------------------------------"
						echo
						sync;sync;sync;
					} > ./logs/${ShellName[$s]}.log 2>&1 
				}` &
			else
				:
			fi
		fi
	done
}

# ShowPartLog 1-32
#測試過程中顯示特定的log檔案，檔案存在於./logs/下
ShowPartLog()
{
	local LogIndex=$1
	local TargetShellName=$(grep -v "#" ${MTConfigFile} 2>/dev/null | grep -v "^$" | sed -n ${LogIndex}p)
	ShellNameSawLog=$(echo ${TargetShellName} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
	if [ ${#ShellNameSawLog} == 0 ] ; then
		echo
		echo -e "\033[1;31mTry again, invalid index: ${Interrupt}\e[0m"
		sleep 2
		return 0
	fi

	if [ ! -f "./logs/${ShellNameSawLog}.log" ] ; then
		echo
		echo -e "\033[1;31mWait a moment and try again, no found any log: ./logs/${ShellNameSawLog}.log\e[0m"
		sleep 2
		return 0
	fi
	echo
	echo "======================================================================"
	more ./logs/${ShellNameSawLog}.log 2>/dev/null
	Wait4nSeconds 20 ${TargetShellName}
	echo
}

#需要和ShowTestResultOnScreem搭配
ShowMTProcess ()
{
	clear
	NowTimeVal=$(date +%s)
	let t=$CycleTime-${NowTimeVal}+${StartTimeVal}

	TotalTime=$(date -d @${CycleTime} +"00:%M:%S")
	if [ ${t} -le 0 ]; then
		RemainingTime='00:00:00'
	else
		RemainingTime=$(date -d @${t} +"00:%M:%S")
	fi

	let ElapsedTime=${CycleTime}-${t}
	ElapsedTime=$(date -d @${ElapsedTime} +"00:%M:%S")

	#         Multithreading test tool for linux V1.0.0
	#----------------------------------------------------------------------
	#Real Time: 2018-11-20 15:02:56              Start: 2018-11-20 15:02:56             
	#  Elapsed: 00:02:04   Total: 00:04:00   Remaining: 00:02:56 
	#   Items#: 10     Test Mode: ByItem  Dispaly Mode: Commandline
	#   Config: /TestAP/Multithreading/Config/MT.conf
	#      XML: /TestAP/Config/S2121.xml
	#No      Test Items                         Cycle(OK/NG)        Result
	#----------------------------------------------------------------------
	#01  /TestAP/lan/chkeepver.sh               005(003/002)        Fail
	#02  /TestAP/ast2500/hwmon.sh               017(017/000)        Pass		
	#03  /TestAP/com/com_test.sh                019(018/000)        Cycling	
	#----------------------------------------------------------------------
		
	ShowTitle "Multithreading tool for LAN EEPROM test"
	printf "%-11s%-33s%-7s%-20s\n" "Real Time: " "`date "+%Y-%m-%d %H:%M:%S"`" "Start: " "${StartTime}"
	printf "%11s\e[33m%-11s\e[0m%-7s%-11s%-11s\e[1;33m%-19s\e[0m\n" "Elapsed: "  "${ElapsedTime}"  "Total: "   "${TotalTime}"  "Remaining: " "${RemainingTime}"   
	printf "%11s%-7s%-11s%-8s%-14s%-19s\n" "Items#: " "${#ShellsSet[@]}" "Test Mode: " "${TestMethod}" "Dispaly Mode: " "$OSDisplayMode"
	printf "%11s%-59s\n" "Config: " "${MTConfigFile}"
	printf "%11s%-59s\n" "XML: " "`[ ${#XmlConfig} != 0 ] && echo "${XmlConfig}" || echo "N/A"`"
	printf "\e[1m%-8s%-35s%-20s%-7s\e[0m\n" "No." "Test Items" "Cycle(OK/NG)" "Result"
	echo "----------------------------------------------------------------------"

	for ((s=0;s<${#ShellsSet[@]};s++))
	do
		let S=$s+1
		case $S in
		[1-9])	
			:
		;;
		
		*)
			let S=$S+87
			S=$(awk -v Char=$S 'BEGIN{printf"%c",Char;}')
		;;
		esac
		
		
		ShellName[$s]=$(echo ${ShellsSet[$s]} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
		Result=$(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | tail -n1 |tr [A-Z] [a-z] )
		

		CycleCnt=0
		OKCnt=$(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | grep -ic '0' )
		NGCnt=$(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | grep -ic '1' )
		let CycleCnt=${OKCnt}+${NGCnt}
		
		printf "%-4s%-39s%3d" "[${S}]" "${ShellsSet[$s]}" "${CycleCnt}"
		printf "%-1s" "("
		printf "\e[1;32m%3d\e[0m" "${OKCnt}"
		printf "%-1s" "/"
		printf "\e[1;31m%-3d\e[0m" "${NGCnt}"
		printf "%-9s" ")"
		
		case ${NGCnt} in
		0)
			if [ ${OKCnt} -ge 1 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | tail -n1 | grep -ivc 'test' ) == 1 ] && [ "${#ExecuteBackground}"X == "0X" ] ; then
				printf "\e[1;32m%-7s\e[0m\n"  "Pass"
			else
				printf "\e[1;30m%-7s\e[0m\n"  "Cycling"
			fi
		;;
		
		*)
			let ErrorFlag++
			if [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | tail -n1 | grep -ivc 'test' ) == 1 ] && [ ${#ExecuteBackground} == 0 ] ; then
				printf "\e[1;31m%-7s\e[0m\n"  "Fail"
			else
				printf "\e[1;31m%-7s\e[0m\n"  "Cycling"
			fi
		;;
		esac
	done
	echo "----------------------------------------------------------------------"
	echo -e "\033[1;33mWarning !! Please do not interrupt these processing ...\033[0m"
	echo -e "\033[1;33mPress the key [X/x] to interrupt if necessary.\033[0m"
	echo -ne "\033[1;33mPress the key [1-${S}] to view the test log.\033[0m"
	read -t 0.95 -n1 Interrupt
	Interrupt=$(echo ${Interrupt} | tr [a-z] [A-Z])
	Interrupt=${Interrupt:-"Z"}
	case $Interrupt in
		X|x)
			echo
			read -p "Confirm to interrupt this processing? [Y/N]" -n1 Confirm
			if [ "$Confirm"x == "Y"x ] ||  [ "$Confirm"x == "y"x ] ; then
				echo
				KillProcess="xml\|celo64e\|eeupdate64e"
				ps ax | grep -w "${KillProcess}" | grep -v "grep" | awk '{print $1}' | while read PID
				do
					echo ${PID} | grep -iq '[a-z][[:punct:]]'  && continue
					kill -9 "${PID}" >& /dev/null
				done
		
				echo -n "Please wait a moment ..."
				wait
				echo -ne "\e[1;33m`printf "\r                             \n" `\e[0m"
				echo

				return 3
			fi
		;;

		[1-9])
			#輸入相應的序號查看測試log,fail的時候閱讀
			ShowPartLog "${Interrupt}"
		;;
		
		[A-W])
			local CurIndex=$(printf "%d" "'${Interrupt}")
			let CurIndex=${CurIndex}-55
			ShowPartLog "${CurIndex}"
		;;
		
		*)
			:
		;;
		esac
	echo
}	

ShowTestResultOnScreem ()
{
	for((t=${CycleTime};t>0;))
	do
		case ${OSDisplayMode} in 
		Commandline|C) MTinCommandline;;
		Xserver|G|X) MTinXserver;;
		*)
			Process 1 "Invalid argument: ${OSDisplayMode}"
			printf "%-10s%-60s\n" "" "OS Display Mode should be: 'Commandline' or 'Xserver' "
			exit 3
		;;
		esac
		
		if [ $t == ${CycleTime} ] ; then
			# Start in: 2018-10-15 14:25:45  Now: 2018-10-15 14:25:45  Items#: 16
			#  Elapsed: 00:05:45  Time Remaining: 00:00:15          Total: 00:06:00
			local StartTime=$(date "+%Y-%m-%d %H:%M:%S")
			StartTimeVal=$(date -d "$StartTime" +%s)
			sleep 2
		fi
		
		ShowMTProcess 
		if [ $? !=  0 ]; then
			let ErrorFlag++
			
			#人為中斷退出測試fail
			let BreakFlag++
			break
		fi
		
		# Break out
		TTLCycleCnt=0
		for iTemp in `ls ./logs/*.temp 2>/dev/null`
		do
			let TTLCycleCnt=${TTLCycleCnt}+$(cat -v ${iTemp} 2>/dev/null | tail -n1 | grep -ic "0\|1" )	
		done

		if [ "${TestMethod}"x == 'byitem'x ] && [ ${TTLCycleCnt} -ge ${#ShellsSet[@]} ]; then
			ShowMTProcess
			sleep 1
			ShowMTProcess | tee ${WorkPath}/logs/${BaseName}.log
			echo
			break
		fi
		
	done

	#按測試時間循環測試時間結束后的加時測試——確保後臺運行的程式測試完整
	SoleShellName=($(echo ${ShellName[@]} | tr ' ' '\n' | sort -u ))
	SoleShellName=$(echo ${SoleShellName[@]} | sed 's/ /\\|/g')
	while [ $(ps ax | grep -i "${SoleShellName}\|celo64e\|eeupdate64e" | grep -vc "grep" ) != 0 ]
	do
		ShowMTProcess | tee ${WorkPath}/logs/${BaseName}.log
	done

	echo -n "Please wait a moment ..."
	wait
	echo -ne "\e[1;33m`printf "\r                             \n" `\e[0m"
	echo

	if [ $t -le 0 ] && [ "${TestMethod}"x != 'byitem'x ] ; then
		ShowMTProcess | tee ${WorkPath}/logs/${BaseName}.log
	fi

	#考慮到重測的功能，檢查.temp文件，其不含“1”則說明全部pass，然後將ErrorFlag置0
	DefaultErrorFlag=${#ShellName[@]}
	for((q=0;q<${#ShellName[@]};q++))
	do
		if [ $(cat -v ./logs/${ShellName[$q]}.temp 2>/dev/null | grep -c '1') == 0 ] && [	$(cat -v ./logs/${ShellName[$q]}.temp 2>/dev/null | grep -c '0') -ge 1 ] && [	$(cat -v ./logs/${ShellName[$q]}.log 2>/dev/null | grep -ic "${ShellName[$q]}.sh test pass") -ge 1 ] ; then
			let DefaultErrorFlag=${DefaultErrorFlag}-1
		fi
	done
	if [ ${DefaultErrorFlag} -le 0 ] ; then
		ErrorFlag=0
	fi

	# 僅限於按測試項目的測試，不限於按測試時間的測試方法
	if [ $t -le 0 ] && [ "${TestMethod}"x == 'byitem'x ]   ; then
		Process 1 "Time out, Multithreading test fail."
		let ErrorFlag++
	fi
}

#合併多線程測試log
MergeLog()
{
	echo "=======================================================================================================================" >> ./logs/${BaseName}.log
	echo >> ./logs/${BaseName}.log
	sync;sync;sync

	echo "Multithreading test tool for LAN EEPROM test, all test logs" >> ./logs/${BaseName}.log
	for((i=0;i<${#ShellName[@]};i++))
	do
		cat -v ./logs/${ShellName[$i]}.log 2>/dev/null | grep -iq "${ShellName[$i]}.sh test pass"
		if [ $? != 0 ] ; then
			let ErrorFlag++
			Process 1 "No found: ${ShellName[$i]}.sh tested pass. Logs check" 		
		fi
		
		#不管是否有測試pass記錄都要合併測試記錄
		{
		let I=${i}+1
		echo "=========================================="
		echo " ${I}/${#ShellName[@]} ${ShellsSet[$i]}"
		echo "==========================================" ;
		} >> ./logs/${BaseName}.log
		
		cat ./logs/${ShellName[$i]}.log 2>/dev/null >> ./logs/${BaseName}.log
	done

	if [ ${#pcb} != 0 ] ; then
		cat ./logs/${BaseName}.log >> ${logpath}/${pcb}.log
	fi

	for EachShell in `cat ${MTConfigFile}`
	do
		rm -rf ${EachShell} 2>/dev/null
	done

	sync;sync;sync
	[ ${ErrorFlag} != 0 ] && exit 1
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

CreatedCompareEepromVersion ()
{
	for ((m=0;m<${#NicIndexArray[@]};m++))
	do
		EepromVersion[$m]=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card[NicIndex=\"${NicIndex[m]}\"]/EepromVer" -n "${XmlConfigFile}" 2>/dev/null)
		rm -rf "${BaseName}${NicIndexArray[$m]}.sh" 2>/dev/null
		cat <<-CompareEepromVersionFile > ${BaseName}${NicIndexArray[$m]}.sh
		Process()
		{ 	
			local Status="\$1"
			local String="\$2"
			case \$Status in
				0)
					printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "\${String}"
				;;

				*)
					printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "\${String}"
					return 1
				;;
				esac
		}

		GenerateErrorCode()
		{
		if [ "\${#pcb}" == 0 ] ; then
			return 0
		fi

		local ErrorCodeFile='../PPID/ErrorCode.TXT'
		local ErrorCode=\$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
		if [ "\${#ErrorCode}" != 0 ] ; then
			cat \${ErrorCodeFile} 2>/dev/null | grep -wq "\${ErrorCode}"
			if [ \$? != 0 ] ; then
				echo "\${ErrorCode}|${BaseName}.sh" >> \${ErrorCodeFile}	
			fi
		else
			echo "NULL|NULL|${BaseName}.sh" >> \${ErrorCodeFile}
		fi
		sync;sync;sync
		return 0
		}
		
		CompareEepromVersion ()
		{
		local TargetNicIndex=\$1
		local StandardVersion=\$2
		local TargetChipName=\$3
		echo "\$StandardVersion" | grep -iwq "null"
		if [ "\$?" == "0" ] ; then
			Process 0 "LAN\${TargetNicIndex} do not need to check the eeprom version."
			exit 0
		fi
		
		#Compare the eeprom version first
		case \$TargetChipName in
			[Ii]211)
				${ProgramTool} /nic=\$TargetNicIndex /invmversion | tee ${WorkPath}/logs/${BaseName}${NicIndexArray[$m]}.log
				sync;sync;sync
				CurVersion=\$(cat ${WorkPath}/logs/${BaseName}${NicIndexArray[$m]}.log | tail -1 | awk '{print \$6}')
			;;

			*)
				${ProgramTool} /nic=\$TargetNicIndex /eepromver | tee ${WorkPath}/logs/${BaseName}${NicIndexArray[$m]}.log
				sync;sync;sync
				CurVersion=\$(cat ${WorkPath}/logs/${BaseName}${NicIndexArray[$m]}.log | grep 'EEPROM Image Version' | awk '{print \$5}' | tail -n1)  
			;;
			esac
			
			if [ "\$CurVersion"x == "\$StandardVersion"x ] ; then
				Process 0 "LAN\${TargetNicIndex} eeprom version(\$CurVersion) Verify"
				exit 0
			else
				Process 1 "LAN\${TargetNicIndex} eeprom version Verify"
				echo "  Current eeprom version: \$CurVersion"
				echo " Standard eeprom version: \$StandardVersion"
				GenerateErrorCode
				exit 1
			fi
		}
		#=======================================================
		CompareEepromVersion ${NicIndexArray[$m]} "${EepromVersion[$m]}" "${LanChipset[$m]}"
	CompareEepromVersionFile

		if [ ! -s "${BaseName}${NicIndexArray[$m]}.sh" ] ; then
			Process 1 "No such shell or 0 KB size of file: ${BaseName}${NicIndexArray[$m]}.sh"
			let ErrorFlag++	
		else
			# For Multi-thread test in X server mode
			chmod 777 ${WorkPath}/${BaseName}${NicIndexArray[$m]}.sh 2>/dev/null
			echo "${WorkPath}/${BaseName}${NicIndexArray[$m]}.sh" >> ${MTConfigFile}
			sync;sync;sync
		fi
	done
}

main ()
{
	rm -rf ${WorkPath}/logs/${BaseName}* 2>/dev/null
	mkdir -p ${WorkPath}/logs 2>/dev/null
	mkdir -p Config 2>/dev/null 

	#確認備置參數符合要求
	if [ $(echo "${TestMethod}" | grep -iwc "ByItem\|ByCT") == 0 ] ; then
		Process 1 "Invalid argument: ${TestMethod}"
		printf "%-10s%-60s\n" "" 'Test Method should be: "ByItem" or "ByCT"'
		exit 3
	else
		TestMethod=$(echo "${TestMethod}" | tr [A-Z] [a-z])
	fi

	#OSType: ubuntu(bash)/linux(sh)
	if [ $(uname -a | grep -ic 'ubuntu') -ge 1 ] ; then
		#用bash執行shell
		OSType="ubuntu"
	else
		#用sh執行shell
		OSType="linux"
	fi

	#--->Get and process the parameters
	#XML檔案是給對應的子程式的，可以沒有，但不能大於1個文件
	XmlConfig="${XmlConfigFile}"

	GetNicIndexArray

	rm -rf ${MTConfigFile} 2>/dev/null
	CreatedCompareEepromVersion

	#確認備置當
	if [ ! -s "${MTConfigFile}" ] ; then
		Process 1 "No such file or 0 KB size of file: ${MTConfigFile}"
		exit 2
	else
		ShellsSet=($(cat -v ${MTConfigFile} | grep -v "#"))
	fi
	
	if [ "${TestMode}"x == "serial"x ] ; then
		for((f=0;f<${#ShellsSet[@]};f++))
		do
			bash ${ShellsSet[$f]}
			local SubTestResult=$?
			let ErrorFlag=${ErrorFlag}+${SubTestResult}
			rm -rf ${ShellsSet[$f]} 2>/dev/null
		done
	else
		MTExecuteBackground=($(ps ax | grep -w "Multithreading" | grep -v "grep" ))

		#確保所有的程式文件均存在
		for((f=0;f<${#ShellsSet[@]};f++))
		do
			if [ ! -s "${ShellsSet[$f]}" ] ; then
				Process 1 "No such file: ${ShellsSet[$f]}"
				let ErrorFlag++
			else
				#如果是放在多線程程式運行，則使用單線程的方式運行程式本程式
				if [ ${#MTExecuteBackground[@]} != 0 ] ; then
					if [ "${OSType}"x == "ubuntu"x ]; then
						bash ${ShellsSet[$f]} -x ${XmlConfig}
					else
						sh ${ShellsSet[$f]} -x ${XmlConfig}
					fi
				fi
				
				if [ $? != 0 ] ; then
					let ErrorFlag++
				fi
			fi	
		done
		[ ${ErrorFlag} != 0 ] && exit 2

		#如果不是放在多線程程式運行，則使用多線程的方式運行程式本程式
		if [ ${#MTExecuteBackground[@]} == 0 ] ; then
			ShowTestResultOnScreem
			#把總的測試結果記錄到log內
			MergeLog 
		fi
	fi
	
	echo
	if [ "${TestMode}"x == "serial"x ] && [ ${#pcb} != 0 ] ; then
		if [ ${ErrorFlag} != 0 ] ; then
			echoFail "Compare EEPROM firmware version"
		else
			echoPass "Compare EEPROM firmware version"
		fi >> ${logpath}/${pcb}.log
		sync;sync;sync 
	fi	
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Compare EEPROM firmware version"
		GenerateErrorCode
		exit 1
	else
		echoPass "Compare EEPROM firmware version"
	fi	
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare XmlConfigFile PortConfigFile NicIndexArray TotalAmount EepromFiles LanChipset ChkSum NicIndex 
declare EepromVersion ApVersion
declare DoubleFlash=disable 
declare CompelFlash=disable
declare ErrorFlag=0
declare ProgramTool='eeupdate64e'

#For MT
declare XmlConfig iniConfigFile OSType 
declare ExecuteBackground=1
declare MTExecuteBackground
declare OSDisplayMode='Commandline'
declare MTConfigFile="./Config/${BaseName}.conf"
declare TestMethod="ByItem"
declare TestMode='parallel'
declare RemoveRecord='enable'
declare -i BreakFlag=0
declare -i TTLCycleCnt=0
declare CycleTime='360'
declare ShellsSet=()
declare ShellName=()
declare logpath="/TestAP/PPID"
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:MVDx: argv
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

		M)
			declare logpath="/TestAP/Test/logs"
			
		;;	

		P)
			XmlConfigFile=${OPTARG}
			xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ProgramName/@TestMode" -n "${XmlConfigFile}" 2>/dev/null | grep -iwq "Parallel"
			if [ $? == 0 ] ; then
				printf "%-s\n" "ParallelTest,CheckEEPROM"
			else
				printf "%-s\n" "SerialTest,CheckEEPROM"
			fi
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
