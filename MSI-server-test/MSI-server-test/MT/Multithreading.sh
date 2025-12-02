#!/bin/bash
#FileName : Multithreading.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="4.1.1"
	local CreatedDate="2018-10-11"
	local UpdatedDate="2020-12-07"
	local Description="Run the shell at the same time"
	
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
	printf "%16s%-s\n" "" "2019-07-04,新增支持命令行模式"
	printf "%16s%-s\n" "" "2020-12-07,更新以適用於2進制程式"
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

ChkExternalCommands ()
{
	if [ $# == 0 ] ; then
	ExtCmmds=(xmlstarlet )
	else
	ExtCmmds=(xmlstarlet $@)
	fi
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
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
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

Wait4nSeconds()
{
	local second=$1
	local Items=$2

	#如果查看的當前項目不是fail項則不再提示如下信息
	if [ $(cat -v ./logs/${ShellNameSawLog}.log 2>/dev/null | grep -iw "${ShellNameSawLog}" | grep -iwc "test fail") == 1 ] && [ $(cat ./logs/${ShellNameSawLog}.temp 2>/dev/null | tail -n 1 |  grep -ic "1") == 1 ] ; then
		ShowMsg --b  "[R/r] To retest: ${Items}"
		ShowMsg --e  "Other any key to continue."
	fi

	# Wait for OP n secondes,and auto to run
	for ((p=${second};p>=0;p--))
	do
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]; then	
			if [ $(echo "R" | grep -ic "${Ans}" ) == 1 ] && [ $(cat -v ./logs/${ShellNameSawLog}.log 2>/dev/null | grep -iw "${ShellNameSawLog}" | grep -iwc "test fail") == 1 ] && [ $(cat ./logs/${ShellNameSawLog}.temp 2>/dev/null | tail -n 1 |  grep -ic "1") == 1 ] ; then
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
		ShowMainMTProcess | tee ${WorkPath}/logs/${BaseName}.log
	fi
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
		0 : All shells test pass
		1 : Some shell(s) test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Multithreading>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			
			<!--Multithreading.sh: 多線程測試配置信息-->
			<!--OSDisplayMode: Commandline(C)/Xserver(G)-->
			<OSDisplayMode>Commandline</OSDisplayMode>
			
			<!--TestMethod: ByItem/ByCT(default: 360s)-->
			<TestMethod>ByItem</TestMethod>
			
			<!--List of shell file指定同時測試的程式清單-->			
			<ConfigFile>/TestAP/Multithreading/Config/MT.conf</ConfigFile>
		</TestCase>
	</Multithreading>
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
	OSDisplayMode=$(xmlstarlet sel -t -v "//Multithreading/TestCase[ProgramName=\"${BaseName}\"]/OSDisplayMode" -n "${XmlConfigFile}" 2>/dev/null)
	MTConfigFile=$(xmlstarlet sel -t -v "//Multithreading/TestCase[ProgramName=\"${BaseName}\"]/ConfigFile" -n "${XmlConfigFile}" 2>/dev/null)
	TestMethod=$(xmlstarlet sel -t -v "//Multithreading/TestCase[ProgramName=\"${BaseName}\"]/TestMethod" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#MTConfigFile} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

CreateMTRun()
{
	rm -rf .MTRun 2>/dev/null
	cat<<-MTRUN > .MTRun
	#!/bin/bash
	#-------------------------------------------------------------------------
	#        File: MTRun.sh
	#    Function: Run More than one Sub-Shell
	#     Version: 4.0.0
	#      Author: Cody,qiutiqin@msi.com
	#     Created: 2018-11-22
	#     Updated: 
	#  Department: Application engineering course
	# 		 Note: Modify this file is forbiden
	# Environment: Linux/CentOS/Ubuntu
	#-------------------------------------------------------------------------
	#ExecuteShell=/TestAP/ast2500/hwmon.sh ==> ExecuteShellName=hwmon.sh
	ExecuteShell="\$1"
	ExecuteShellName=\$(echo \${ExecuteShell} | awk -F'/' '{print \$NF}' | awk -F'.' '{print \$1}')
	{ 
		echo -n "\${ExecuteShell} start to run in: "
		date "+%Y-%m-%d %H:%M:%S  %z"
		echo "\${ExecuteShell##*.}" | grep -iwq "py"
		if [ $? == 0 ] ; then
			python3 \${ExecuteShell}
		else
			if [ "${OSType}"x == "ubuntu"x ]; then
				bash \${ExecuteShell} -x ${XmlConfig}
			else
				sh \${ExecuteShell} -x ${XmlConfig}
			fi
		fi
		
		if [ \$? == 0 ] ; then
			echo 0 >> ./logs/\${ExecuteShellName}.temp
			echo -n "\${ExecuteShell} test pass in: "
			date "+%Y-%m-%d %H:%M:%S %Z"
		else
			echo 1 >> ./logs/\${ExecuteShellName}.temp
			echo -n "\${ExecuteShell} test fail in: "
			date "+%Y-%m-%d %H:%M:%S %Z"
			
			# for failure Locking or Upload
			grep -wq "\${ExecuteShell}" "../PPID/FAILITEM.TXT" 2>/dev/null || echo "\${ExecuteShell}" >> ../PPID/FAILITEM.TXT
		fi
		echo
		
		OKCnt=\$(cat -v ./logs/\${ExecuteShellName}.temp 2>/dev/null | grep -ic '0' )
		NGCnt=\$(cat -v ./logs/\${ExecuteShellName}.temp 2>/dev/null | grep -ic '1' )
		let TTLCnt=\${OKCnt}+\${NGCnt}
		echo "\${ExecuteShell} test cycle: \${TTLCnt}, pass: \${OKCnt}, fail: \${NGCnt}"			
		echo "----------------------------------------------------------------------"
		sync;sync;sync;
	} | tee ./logs/\${ExecuteShellName}.log 2>&1 
	if [ "\$(cat -v ./logs/\${ExecuteShellName}.temp 2>/dev/null | grep -ic '1')A" != "0A" ] ; then
		read -p "Press any key to exit ...." -t60 -n1 OPReply
		echo	
	fi
	MTRUN

	if [ ! -s ".MTRun" ] ; then
		Process 1 "Create MTRun file"
		exit 2
	else
		chmod 777 .MTRun 2>/dev/null
	fi
}

#圖形介面模式，將會打開很多的測試窗口并進行測試
MTinXserver()
{
	ChkExternalCommands "gnome-terminal"
	CreateMTRun
	for ((s=0;s<${#ShellsSet[@]};s++))
	do
		#${ShellsSet[$s]}=/TestAP/ast2500/hwmon.sh ==> ShellName[$s]=hwmon.sh
		FullShellName[$s]=$(basename ${ShellsSet[$s]})				
		ShellName[$s]=$(echo ${ShellsSet[$s]} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')

		ExecuteBackground=$(ps ax | grep -w "${ShellName[$s]}\|celo64e\|eeupdate64e" | grep -v "grep" )
		
		if [ "$t" == "${CycleTime}" ] && [ "${RemoveRecord}"x == 'enable'x ]; then
			rm -rf ./logs/${ShellName[$s]}.log ./logs/${ShellName[$s]}.temp 2>/dev/null
			echo 'test' > ./logs/${ShellName[$s]}.temp
			RemoveRecord='disable'
		fi
		
		#按測試項目測試，所有的測試項目測試完成1個cycle就退出
		if [ "${TestMethod}"x == 'byitem'x ] ; then
			if [ $(echo "${ExecuteBackground}" | grep -ic "${FullShellName[$s]}" ) != 0 ] || [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null |  grep -c "0\|1") != 0 ] ; then  
				:
			else
				gnome-terminal --geometry="90"x"30"+10000+10000 -x bash -c "${WorkPath}/.MTRun ${ShellsSet[$s]}"	
			fi
		fi

		#按測試時間循環測試
		if [ "${TestMethod}"x == 'byct'x ] ; then
			if [ $(echo "${ExecuteBackground}" | grep -ic "${FullShellName[$s]}" ) == 0 ] && [ $t -gt 0 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | tail -n1 | grep -ic '1') != 1 ] ; then
			
				#NCIS,燒錄的程式只需要運行一次即可
				if [ $(echo ${FullShellName[$s]} | grep -ic "NCSI\|_w") -gt 0 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp | grep -ic "0\|1") ] ; then
					continue
				fi
				
				#回路測試要提前100秒結束
				if [ $(echo ${FullShellName[$s]} | grep -ic "lan\|sata") -gt 0 ] && [ $t -le 100 ] ; then
					continue
				fi
				gnome-terminal --geometry="90"x"30"+10000+10000 -x bash -c "${WorkPath}/.MTRun ${ShellsSet[$s]}"	
			else
				:
			fi
		fi
	done
}

#在命令行下運行，也可以在圖形介面下運行
#需要和ShowTestResultOnScreem搭配
MTinCommandline()
{
	for ((s=0;s<${#ShellsSet[@]};s++))
	do
		#${ShellsSet[$s]}=/TestAP/ast2500/hwmon.sh ==> ShellName[$s]=hwmon.sh
		FullShellName[$s]=$(basename ${ShellsSet[$s]})
		ShellName[$s]=$(echo ${ShellsSet[$s]} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
		ExecuteBackground=$(ps ax | grep -w "${ShellName[$s]}\|celo64e\|eeupdate64e" | grep -v "grep" )
		
		if [ "$t" == "${CycleTime}" ] && [ "${RemoveRecord}"x == 'enable'x ]; then
			rm -rf ./logs/${ShellName[$s]}.log ./logs/${ShellName[$s]}.temp 2>/dev/null
			echo 'test' > ./logs/${ShellName[$s]}.temp
			RemoveRecord='disable'
		fi
		
		#按測試項目測試,所有的測試項目測試完成1個cycle就退出
		if [ "${TestMethod}"x == 'byitem'x ] ; then
			if [ $(echo "${ExecuteBackground}" | grep -ic "${FullShellName[$s]}" ) != 0 ] || [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null |  grep -c "0\|1") != 0 ] ; then  
				:
			else
				
				`{
					{ 
						echo -n "${FullShellName[$s]} start to run in: "
						date "+%Y-%m-%d %H:%M:%S  %z"
						echo "${ShellsSet[$s]##*.}" | grep -iwq "py"
						if [ $? == 0 ] ; then
							python3 ${ShellsSet[$s]}
						else
							if [ "${OSType}"x == "ubuntu"x ]; then
								bash ${ShellsSet[$s]} -x ${XmlConfig}
							else
								sh ${ShellsSet[$s]} -x ${XmlConfig}
							fi
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
							grep -wq "${FullShellName[$s]}" "../PPID/FAILITEM.TXT" 2>/dev/null || echo "${FullShellName[$s]}" >> ../PPID/FAILITEM.TXT
						fi
						echo "----------------------------------------------------------------------"
						sync;sync;sync;
					} > ./logs/${ShellName[$s]}.log 2>&1 
				}` &
			fi
		fi

		#按測試時間循環測試
		if [ "${TestMethod}"x == 'byct'x ] ; then
			if [ $(echo "${ExecuteBackground}" | grep -ic "${FullShellName[$s]}" ) == 0 ] && [ $t -gt 0 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp 2>/dev/null | tail -n1 | grep -ic '1') != 1 ] ; then
			
				#NCIS,燒錄的程式只需要運行一次即可
				if [ $(echo ${FullShellName[$s]} | grep -ic "NCSI\|_w") -gt 0 ] && [ $(cat -v ./logs/${ShellName[$s]}.temp | grep -ic "0\|1") ] ; then
					continue
				fi
				
				#回路測試要提前100秒結束
				if [ $(echo ${FullShellName[$s]} | grep -ic "lan") -gt 0 ] && [ $t -le 100 ] ; then
					continue
				fi
				
				`{
					{ 					
						echo -n "${FullShellName[$s]} start to run in: "
						date "+%Y-%m-%d %H:%M:%S  %z"
						echo 'test' >> ./logs/${ShellName[$s]}.temp
						echo "${ShellsSet[$s]##*.}" | grep -iwq "py"
						if [ $? == 0 ] ; then
							python3 ${ShellsSet[$s]}
						else
							if [ "${OSType}"x == "ubuntu"x ]; then
								bash ${ShellsSet[$s]} -x ${XmlConfig}
							else
								sh ${ShellsSet[$s]} -x ${XmlConfig}
							fi
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
							grep -wq "${FullShellName[$s]}" "../PPID/FAILITEM.TXT" 2>/dev/null || echo "${FullShellName[$s]}" >> ../PPID/FAILITEM.TXT
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

ShowPartLog()
{
	local LogIndex=$1
	# ShowPartLog 1-32
	#測試過程中顯示特定的log檔案，檔案存在於./logs/下
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

ShowMainMTProcess ()
{
	clear
	#需要和ShowTestResultOnScreem搭配
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
		
	ShowTitle "Multithreading test tool for linux"
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
		
		
		FullShellName[$s]=$(basename ${ShellsSet[$s]})
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
				KillProcess="xml"
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
		
		ShowMainMTProcess 
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
			ShowMainMTProcess
			sleep 1
			ShowMainMTProcess | tee ${WorkPath}/logs/${BaseName}.log
			echo
			break
		fi
	done

	#按測試時間循環測試時間結束后的加時測試——確保後臺運行的程式測試完整
	SoleShellName=($(echo ${ShellName[@]} | tr ' ' '\n' | sort -u ))
	SoleShellName=$(echo ${SoleShellName[@]} | sed 's/ /\\|/g')
	while [ $(ps ax | grep -iw "${SoleShellName}\|celo64e\|eeupdate64e" | grep -vc "grep" ) != 0 ]
	do
		ShowMainMTProcess | tee ${WorkPath}/logs/${BaseName}.log
	done

	echo -n "Please wait a moment ..."
	wait
	echo -ne "\e[1;33m`printf "\r                             \n" `\e[0m"
	echo

	if [ $t -le 0 ] && [ "${TestMethod}"x != 'byitem'x ] ; then
		ShowMainMTProcess | tee ${WorkPath}/logs/${BaseName}.log
	fi

	#考慮到重測的功能，檢查.temp文件，其不含“1”則說明全部pass，然後將ErrorFlag置0
	DefaultErrorFlag=${#ShellName[@]}
	for((q=0;q<${#ShellName[@]};q++))
	do
		if [ $(cat -v ./logs/${ShellName[$q]}.temp 2>/dev/null | grep -c '1') == 0 ] && [	$(cat -v ./logs/${ShellName[$q]}.temp 2>/dev/null | grep -c '0') -ge 1 ] && [	$(cat -v ./logs/${ShellName[$q]}.log 2>/dev/null | grep -iw "${FullShellName[$q]}" | grep -iwc "test pass") -ge 1 ] ; then
			let DefaultErrorFlag=${DefaultErrorFlag}-1
		fi
	done
	if [ ${DefaultErrorFlag} -le 0 ] ; then
		ErrorFlag=0
	fi

	# 僅限於按測試項目的測試，不限於按測試時間的測試方法
	if [ $t -le 0 ] && [ "${TestMethod}"x == 'byitem'x ] ; then
		Process 1 "Time out, Multithreading test fail."
		let ErrorFlag++
	fi
}

MergeLog()
{
	if [ ${#pcb} == 0 ] ; then
		#在非主程式運行的時候pcb變量為空，因此不需要追加測試log
		return 0
	fi

	#合併多線程測試log
	echo "=======================================================================================================================" >> ${logpath}/${pcb}.log
	cat ./logs/${BaseName}.log 2>/dev/null >> ${logpath}/${pcb}.log
	echo >> ${logpath}/${pcb}.log
	sync;sync;sync

	echo "Multithreading test tool for linux, all test logs" >> ${logpath}/${pcb}.log
	for((i=0;i<${#ShellName[@]};i++))
	do
		cat -v ./logs/${ShellName[$i]}.log 2>/dev/null | grep -iw "${FullShellName[$i]}" | grep -iwq "test pass"
		if [ $? != 0 ] ; then
			let ErrorFlag++
			Process 1 "No found: ${FullShellName[$i]} tested pass. Logs check fail" 		
		fi
		
		#不管是否有測試pass記錄都要合併測試記錄
		{
		let I=${i}+1
		echo "=========================================="
		echo " ${I}/${#ShellName[@]} ${ShellsSet[$i]}"
		echo "==========================================" ;
		} >> ${logpath}/${pcb}.log
		
		cat ./logs/${ShellName[$i]}.log 2>/dev/null >> ${logpath}/${pcb}.log
	done
	[ ${ErrorFlag} != 0 ] && exit 1
}

main()
{
	if [ $(echo "${TestMethod}" | grep -iwc "ByItem\|ByCT") == 0 ] ; then
		#確認備置參數符合要求
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

	#確認備置當
	if [ ! -s "${MTConfigFile}" ] ; then
		Process 1 "No such file or 0 KB size of file: ${MTConfigFile}"
		exit 2
	else
		ShellsSet=($(cat -v ${MTConfigFile} | grep -v "#"))
	fi

	#--->Get and process the parameters
	#XML檔案是給對應的子程式的，可以沒有，但不能大於1個文件
	XmlConfig="${XmlConfigFile}"
	if [ ${#XmlConfig} == 0 ] ; then
		XmlConfig=($(ls ../Config/*.xml 2>/dev/null ))
		if [ ${#XmlConfig[@]} -gt 1 ] ; then
			Process 1 "Too much or no found XML config file. Check XML fail"
			ls ../Config/*.xml 2>/dev/null
			exit 2
		fi
	fi

	#確保所有的程式文件均存在
	for((f=0;f<${#ShellsSet[@]};f++))
	do
		if [ ! -s "${ShellsSet[$f]}" ] ; then
			Process 1 "No such file: ${ShellsSet[$f]}"
			let ErrorFlag++
		fi	
	done
	[ ${ErrorFlag} != 0 ] && exit 1

	rm -rf ${WorkPath}/logs/* 2>/dev/null
	mkdir -p ${WorkPath}/logs 2>/dev/null

	#把總的測試結果記錄到log內
	ShowTestResultOnScreem 
	MergeLog
	if [ ${ErrorFlag} != 0 ] ||  [ ${BreakFlag} != 0 ] ; then
		#人為中斷退出測試fail
		echoFail "Multithreading test"
		exit 1
	else
		echoPass "Multithreading test"
	fi	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare RemoveRecord='enable'
declare -i ErrorFlag=0
declare -i BreakFlag=0
declare -i TTLCycleCnt=0
declare CycleTime='360'
declare ExecuteBackground=1
declare OSDisplayMode TestMethod
declare XmlConfigFile XmlConfig MTConfigFile OSType ApVersion
declare ShellsSet=()
declare ShellName=()
declare FullShellName=()
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
			printf "%-s\n" "ParallelTest,Multithreading"
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
