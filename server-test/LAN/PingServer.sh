#!/bin/bash
#FileName : PingServer.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.3"
	local CreatedDate="2018-06-01"
	local UpdatedDate="2020-11-02"
	local Description="Ping the specified server and check the packet loss rate less than 25%"
	
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
	printf "%16s%-s\n" "" "2020-11-02,可以自定義IP地址; dhclient --timeout/-timeout都适用;修復一些bug "
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
	ExtCmmds=(xmlstarlet ${ProgramTool} ${TestTool})
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
	eg.: `basename $0` x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
		
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Ping server all pass
		1 : Ping server fail
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
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NXI23|CANT CONNECT TO INTERNET WITH INTERNAL LAN JACK</ErrorCode>
			<!--PingServer.sh-->
			<!--Test Port-->
			<Card>
				<!--通過MAC地址定位網卡-->
				<NicIndex>1 2</NicIndex>
				<MacAddrFile>/TestAP/PPID/MAC1.TXT</MacAddrFile>
				<MacAddrFile>/TestAP/PPID/MAC2.TXT</MacAddrFile>
			</Card>
			
			<HowToGetIP>
				<!--Auto: 自動獲取IP地址,以下IPaddress/Mask被忽略; Spec: 指定IP地址,以下IPaddress/Mask有效-->
				<Type>Spec</Type>
				<IPaddress>192.168.1.10</IPaddress>
				<SubnetMask>255.255.255.0</SubnetMask>
				<!--Enable: 測試完成後全部釋放IP地址; disable: 測試完成後保留最後一個port的IP地址-->
				<ReleaseIP>Enable</ReleaseIP>
			</HowToGetIP>
			
			<!-- minPacketLossRate is Minimum packet loss rate -->
			<ServerIpAddr>20.40.1.40</ServerIpAddr>
			<!--ping多少秒鐘-->
			<Deadline>5</Deadline>
			<Packet>10240</Packet>
			
			<PacketLossRate>10%</PacketLossRate>
			<!-- MaxSpeed is the Max support link mode speed -->
			<MaxSpeed>1000</MaxSpeed>
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
	
	# Get the BIOS information from the config file(*.xml)
	NicIndex=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/NicIndex" -n "${XmlConfigFile}" 2>/dev/null))
	MacArrayFiles=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Card/MacAddrFile" -n "${XmlConfigFile}" 2>/dev/null))

	ServerIpAddr=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ServerIpAddr" -n "${XmlConfigFile}" 2>/dev/null)
	Deadline=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Deadline" -n "${XmlConfigFile}" 2>/dev/null)
	Packet=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Packet" -n "${XmlConfigFile}" 2>/dev/null)
	PacketLossRate=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/PacketLossRate" -n "${XmlConfigFile}" 2>/dev/null | tr -d "[[:punct:]]")
	MaxLinkSpd=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/MaxSpeed" -n "${XmlConfigFile}" 2>/dev/null)

	#How to get IP
	HowToGetIP=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/HowToGetIP/Type" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
	ClientIPaddress=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/HowToGetIP/IPaddress" -n "${XmlConfigFile}" 2>/dev/null)
	SubnetMask=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/HowToGetIP/SubnetMask" -n "${XmlConfigFile}" 2>/dev/null)
	ReleaseIP=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/HowToGetIP/ReleaseIP" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
	
	if [ ${#NicIndex} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		let ErrorFlag++
	fi
	
	echo "${HowToGetIP}" | grep -iwq "Auto\|Spec" 
	if [ $? != 0 ] ; then
		Process 1 "Invalid setting: \"HowToGetIP/Type\": ${HowToGetIP}"
		printf "%10s%s\n" "" "Valid setting: \"HowToGetIP/Type\" is Auto or Spec"
		let ErrorFlag++
	fi
	
	if [ ${HowToGetIP} == 'spec' ] ; then
		CheckIPaddr "${ClientIPaddress}" || let ErrorFlag++
		CheckIPaddr "${SubnetMask}" || let ErrorFlag++
	fi
	
	[ ${ErrorFlag} != 0 ] && exit 3
	
	return 0
}

CheckIPaddr ()
{
	local IPaddr=$1
	echo ${IPaddr} | grep -iq "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$"
	if [ "$?" != "0" ] ; then 
		Process 1 "Invalid IP address: ${IPaddr}"
		return 1
	fi 

	for ((i=1;i<=4;i++))
	do
		IPaddrSegment=$(echo ${IPaddr} | awk -F'.'  -v S=$i '{print $S}')
		IPaddrSegment=${IPaddrSegment:-"999"}
		if [ $IPaddrSegment -gt 255 ] || [ $IPaddrSegment -lt 0 ] ; then 
			Process 1 "Invalid IP address: ${IPaddr}"
			return 1
		fi 
	done 
	return 0
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
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do   
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			break
		else
			continue
		fi
	done
	echo '' 
}

GetEthId()
{
	if [ "${XmlConfigFile}"x == "x" ] && [ "${#NicIndex[@]}" != "0x" ] ; then
		MacArrayFiles=($(ls ${PpidDir}/ | grep -iE "^MAC" | sort -s ))

		if [ ${#MacArrayFiles[@]} == 0 ] ; then
			echo -e  "\e[1;33m Not found any mac files,ping all LANs\e[0m" 
			echo -e  "\e[1;33m-----------------------------------------------------------------------\e[0m" 
			EthId=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "([\dA-F]{2}:){5}[\dA-F]{2}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':'))
			if [ ${#EthId[@]} != 0 ] ; then	
				return 0
			else
				let ErrorFlag++
				return 1
			fi
		
		else
			for ((cnt=0;cnt<${#MacArrayFiles[@]};cnt++))
			do
				# Add the path
				MacArrayFiles[$cnt]=$(echo "${PpidDir}/${MacArrayFiles[$cnt]}")
			done
		fi
	fi 

	for EachNicIndex in ${NicIndex[@]}
	do
		FindResult=$(find ${PpidDir}/ -iname "mac${EachNicIndex}.txt" 2>/dev/null)
		echo FindResult = $FindResult
		pause
		if [ ${#FindResult} == 0 ] ; then 
			Process 1 "Some mac(nic index=${EachNicIndex}) file is missing ..."
			let ErrorFlag++
		fi 
	done
	if [ $ErrorFlag != 0 ] ; then
		ls ${PpidDir}/ | grep -iE "^MAC" | sort -s | tr '\n' '\t'
		echo
		exit 2
	fi

	for ((t=0;t<${#NicIndex[@]};t++))
	do
		GetPartMacArrayFiles[$t]=${MacArrayFiles[$t]}
	done

	if [ ${#GetPartMacArrayFiles[@]} -ge 1 ] ; then
		for ((cnt=0;cnt<${#GetPartMacArrayFiles[@]};cnt++))
		do

			if [ ! -s "${GetPartMacArrayFiles[$cnt]}" ] ; then
				Process 1 "No such file or 0 KB size of file: ${GetPartMacArrayFiles[$cnt]}" 
				let ErrorFlag++
				continue
			fi
			# Get the MAC address
			MacArray[$cnt]=$(cat -v ${GetPartMacArrayFiles[$cnt]} | head -n1 )
		done
		
		[ ${ErrorFlag} != 0 ] && exit 2

		for ((cnt=0;cnt<${#MacArray[@]};cnt++))
		do
			# Split the MAC Address,e.g.:D8CB8AA7BCE6 to D8:CB:8A:A7:BC:E6
			for ((j=1,k=1;j<=6,k<=11;j++,k+=2 ))
			do
				mac[$j]=$(echo "${MacArray[$cnt]}" | cut -c $k-$(($k+1)))
			done
			
			MacAddr="${mac[1]}:${mac[2]}:${mac[3]}:${mac[4]}:${mac[5]}:${mac[6]}" 
			EthId[$cnt]=$(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "${MacAddr}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':')
			EthId[$cnt]=${EthId[$cnt]:-NonExistent}
			[ "$cnt"x == "0"x ] &&  echo '-------------------------------------------------'	
			echo -e "\tLAN$((${cnt}+1)), ${MacArray[$cnt]}: ${EthId[$cnt]}"		
		done
		
		echo '-------------------------------------------------'
	else
		EthId=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "([\dA-F]{2}:){5}[\dA-F]{2}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':'))
		echo '---------------------------------------------------------------------'	
		echo "Found LAN device: ${EthId[@]}"
		echo '---------------------------------------------------------------------'	

	fi

	case ${#EthId[@]} in
		0)
			Process 1 "No LAN device found"
			exit 4
		;;

		*)
			NonExistent_cnt=$(echo ${EthId[@]} | tr ' ' '\n' | grep -ic "NonExistent")
			if [ ${NonExistent_cnt} == ${#EthId[@]} ]; then
				Process 1 "No LAN device found"
				exit 4
			fi
		;;
		esac
		return 0
}

CompareMaxSpdAndLinkMode ()
{
	local TargetEthId1=$1
	local TargetMac1=$2
	MaxLinkSpd=$(echo ${MaxLinkSpd} | tr -d '[[:punct:]][[:alpha:]]' )

	<<-EthTool
	Settings for enp0s20f0:
		Supported ports: [ TP ]
		Supported link modes:   10baseT/Half 10baseT/Full 
								100baseT/Half 100baseT/Full 
								1000baseT/Full 
		Supported pause frame use: Symmetric
		Supports auto-negotiation: Yes
		Advertised link modes:  10baseT/Half 10baseT/Full 
								100baseT/Half 100baseT/Full 
								1000baseT/Full 
		Advertised pause frame use: Symmetric
		Advertised auto-negotiation: Yes
		Speed: 100Mb/s
		Duplex: Full
		Port: Twisted Pair
		PHYAD: 0
		Transceiver: internal
		Auto-negotiation: on
		MDI-X: off (auto)
		Supports Wake-on: pumbg
		Wake-on: g
		Current message level: 0x00000007 (7)
					   drv probe link
		Link detected: yes
	EthTool

	ethtool $TargetEthId1 2>/dev/null | grep -iwA3 "Supported link modes"  | grep  -iwq "${MaxLinkSpd}base.*" 
	if [ $? != 0 ] ; then
		Process 1  "$TargetMac1 $TargetEthId1 max Supported link modes: ${MaxLinkSpd}base"
		printf "%-10s%-70s\n" "" "The stanadard max Supported link modes(${MaxLinkSpd}baseT) is too large."
		return 1	
	fi

	for((try=1;try<=2;try++))
	do
		CurSpd=$(ethtool $TargetEthId1 2>/dev/null | grep -iw "Speed"  | awk -F':' '{print $NF}' | tr -d '[[:punct:]][[:alpha:]] ')
		CurSpd=${CurSpd:-'0'}
		if [ "${CurSpd}" != "${MaxLinkSpd}" ] ; then
		
			if [ ${try} == 1 ] ; then 
				# ethtool -s ${TargetEthId} autoneg on speed ${MaxLinkSpd} duplex full
				ethtool -s "${TargetEthId1}" duplex full autoneg off speed ${MaxLinkSpd} 
				Process $? "Set ${TargetEthId1}'s speed as: ${MaxLinkSpd}Mbps ... "
				if [ $? != 0 ]; then
					printf "%s10%-s\n" "" "Try again ..."
				fi
				sleep 5
				continue
			fi
			
			Process 1  "Check $TargetMac1 $TargetEthId1 link speed fail."
			printf "%-10s%-60s\n" "" "             Current link speed is: ${CurSpd} Mbps"
			printf "%-10s%-60s\n" "" "The stanadard link speed should be: ${MaxLinkSpd} Mbps"
			return 1	
		fi
	done
}


Connet2Server ()
{
	local TargetEthId=$1
	local TargetMac=$2

	# Connect Server,Show message
	ShowMsg --b "Plug LAN cable in LAN port: ${TargetEthId} ${TargetMac}"
	ShowMsg --e "Press [Enter] key to continue ..."
	Wait4nSeconds ${TimeOut}
	echo  "${TargetMac} ${TargetEthId} testing ..."
	ifconfig ${TargetEthId} up >/dev/null 2>&1
	sleep 2
	dhclient -r ${TargetEthId} >/dev/null 2>&1
	#此部分程式498～511 行，与下面程式有重复，无需提前设置
	#if [ ${HowToGetIP} == 'auto' ] ; then
	#	dhclient ${TargetEthId} >/dev/null 2>&1
	#else
	#	for((e=0;e<10;e++))
	#	do 
	#		ifconfig "${TargetEthId}" "${ClientIPaddress}" netmask "${SubnetMask}"
	#		ifconfig "${TargetEthId}" | grep -iwq "${ClientIPaddress}" && break
	#		if [ ${e} -ge 5 ]; then
	#			Process 1 "Set IP address time out ..."
	#			return 1
	#		fi
	#		sleep 1
	#	done
	#fi
	sleep 1

	for((m=0;m<3;m++))
	do 
		KillPid
		local SubErrorFlag=0
		local FailFlag=0
		rm -rf ${TargetEthId}.log >/dev/null 2>&1
		if [ ${HowToGetIP} == 'auto' ] ; then
			dhclient ${TargetEthId} >/dev/null 2>&1
			#ubuntu 下面dhclient 工具不支持timeout 指令,如下522~532行指令取消，直接做dhclient
			#if [ $(dhclient --help 2>&1 | grep -wFc "[--timeout" ) == 1 ] ; then
			#	dhclient --timeout 5 ${SelectCard} >/dev/null 2>&1
			#elif [ $(dhclient --help 2>&1 | grep -wFc "[-timeout" ) == 1 ] ; then
			#	dhclient -timeout 5 ${SelectCard} >/dev/null 2>&1
			#else
			#	Process 1 "No argument 'timeout' for dhclient ..."
			#	return 1
			#fi
		else
			cat <<-setIP > setIPaddr
			#!/bin/bash
			while :
			do 
				ifconfig "${TargetEthId}" "${ClientIPaddress}" netmask "${SubnetMask}"
			done
			setIP
			sync;sync;sync
			chmod 777 setIPaddr
			`./setIPaddr` &
		fi
		CompareMaxSpdAndLinkMode ${TargetEthId} ${TargetMac}
		[ $? != 0 ] && continue
		
		ifconfig ${TargetEthId} 2>/dev/null
		ethtool ${TargetEthId} 2>/dev/null

		{(ping ${ServerIpAddr} -I ${TargetEthId} -w ${Deadline:-5} -s ${Packet} ) || let FailFlag++ ;} | tee ${TargetEthId}.log
		CurPacketLossRate=$(cat -v ${TargetEthId}.log 2>/dev/null | grep -i "loss" | tr ' ' '\n' | grep '%' | tr -d '[[:punct:]]')
		rm -rf ${TargetEthId}.log >/dev/null 2>&1
		
		if [ "${FailFlag}" == "0" ] && [ ${PacketLossRate} -ge ${CurPacketLossRate} ] ; then
			Process 0 "$TargetMac ${TargetEthId} ping server"
			SubErrorFlag=0
			break
		else
			CurPacketLossRate=${CurPacketLossRate:-100}
			Process 1 "$TargetMac ${TargetEthId} ping server packet loss rate:${CurPacketLossRate}%"
			let SubErrorFlag++
		fi
		if [ ${HowToGetIP} == 'spec' ] ; then
			kill -9 $(pgrep -P ${PPIDKILL} setIPaddr) >/dev/null 2>&1
			kill -9 $(pgrep -P ${PPIDKILL} while) >/dev/null 2>&1
			kill -9 $(pgrep -P ${PPIDKILL} ifconfig) >/dev/null 2>&1
		fi
		

		
	done
	
	if [ "${SubErrorFlag}" != "0" ] ; then
		let ErrorFlag++
	else
		ErrorFlag=0
		return 0
	fi
	[ ${m} -gt 3 ] && let ErrorFlag++ && return 1
}

KillPid()
{
	# Stop PID
	rm -rf setIPaddr >& /dev/null
	ps ax | awk '/setIPaddr/{print $1}' | while read PID
	do
		kill -9 "${PID}" >& /dev/null
	done
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i TimeOut=5
declare -i ErrorFlag=0
declare -i PPIDKILL=$$
declare XmlConfigFile ServerIpAddr EthId MacArray MacAddr NicIndex Packet PacketLossRate MaxLinkSpd 
declare HowToGetIP ClientIPaddress SubnetMask ReleaseIP
declare PpidDir='../PPID'
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

		P)
			printf "%-s\n" "SerialTest,PingTest"
			exit 1
		;;		

		V)
			VersionInfo
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

GetEthId || exit 1

for ((e=0;e<${#EthId[@]};e++))
do
	Connet2Server ${EthId[$e]} ${MacArray[$e]}
	if [ "${ErrorFlag}" != "0" ] ; then
		echoFail "Ping the server from ${EthId[$e]}"
		GenerateErrorCode
		KillPid
		exit 1
	else 
		if [ ${ReleaseIP:-enable} == "enable" ]; then
			dhclient -r ${EthId[$e]} >/dev/null 2>&1
		else
			if [ ${#EthId[@]} -gt 1 ]; then
				dhclient -r ${EthId[$e]} >/dev/null 2>&1
			fi
		fi
	fi
done


echoPass "Ping the server test"
KillPid
exit 0

