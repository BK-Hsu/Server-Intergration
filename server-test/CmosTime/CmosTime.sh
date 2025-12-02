#!/bin/bash
#FileName : CmosTime.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.2"
	local CreatedDate="2018-05-25"
	local UpdatedDate="2020-11-03"
	local Description="Synchronizing NTP server time,compare date and time"
	
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
	printf "%16s%-s\n" "" "1.0.2: 1>Set the terminal show English"
	printf "%16s%-s\n" "" "1.1.2: 1>新增手選網卡功能"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//CmosTime/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet hwclock)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			ntpdate)printf "%10s%s\n" "" "Please install: samba-common-tools-4.7.1-6.el7.x86_64.rpm";;
		esac
		
		let ErrorFlag++
	else
		chmod 777 ${_ExtCmmd}
	fi
	done
	[ ${ErrorFlag} != 0 ] && exit 127
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

#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [ -x lConfig.xml ] [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file		
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Compare date and time pass
		1 : Set date and time or compare fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<CmosTime>
		<TestCase>	
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS46|CMOS time fail</ErrorCode>
			<!--CmosTime.sh: CMOS日期時間設置、比對程式--> 
			<!-- TimeZone is time zone --> 
			<!-- UTC/GMT+0800 : HKT,CCT,CST(HongKong,China Standard Time) --> 
			<!-- UTC/GMT+1000 : GST(Greenwich Sidereal Time) --> 
			<!-- UTC/GMT+0900 : JST,KST(Japan,Korea Standard Time) --> 
			<!-- UTC/GMT+0100 : DNT,NOR,SWT,BST,CET,FET,MET --> 
			<!-- UTC/GMT+0000 : GMT,UT,UTC --> 
			<!-- UTC/GMT-0400 : AST --> 
			<!-- UTC/GMT-0500 : EST(Eastern Standard Time) --> 
			<!-- UTC/GMT-0800 : PST(Pacific Standard Time) --> 
			<TimeZone>+0800</TimeZone>
			
			<!-- NtpIpAddr: NTP server ip address -->
			<NtpIpAddr>20.20.0.60</NtpIpAddr>
			
			<!-- The gap of NTP server and location time ,unit: second -->
			<Gap>120</Gap>
			
			<!-- for Linux OS only -->
			<OsDstStatus>disable</OsDstStatus>

			<!-- enable: Set time function enable -->
			<SetTime>enable</SetTime>
		</TestCase>	
	</CmosTime>		
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

#--->Get the parameters from the XML config file
GetParametersFrXML ()
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
	TimeZone=$(xmlstarlet sel -t -v "//CmosTime/TestCase[ProgramName=\"${BaseName}\"]/TimeZone" -n "${XmlConfigFile}" 2>/dev/null)
	NtpIpAddr=$(xmlstarlet sel -t -v "//CmosTime/TestCase[ProgramName=\"${BaseName}\"]/NtpIpAddr" -n "${XmlConfigFile}" 2>/dev/null)
	Gap=$(xmlstarlet sel -t -v "//CmosTime/TestCase[ProgramName=\"${BaseName}\"]/Gap" -n "${XmlConfigFile}" 2>/dev/null)
	OsDstStatus=$(xmlstarlet sel -t -v "//CmosTime/TestCase[ProgramName=\"${BaseName}\"]/OsDstStatus" -n "${XmlConfigFile}" 2>/dev/null)
	SetTime=$(xmlstarlet sel -t -v "//CmosTime/TestCase[ProgramName=\"${BaseName}\"]/SetTime" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#TimeZone} == 0 ] || [ ${#NtpIpAddr} == 0 ]  || [ ${#Gap} == 0 ]  || [ ${#OsDstStatus} == 0 ]   || [ ${#SetTime} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

Wait4nSeconds()
 {
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do  
		printf "\r\e[1;33mAfter %02d seconds will auto continue, press [Y/y] continue at once ...\e[0m" "${p}" 
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			break
		else
			continue
		fi
	done
	echo '' 
}

GetKernelVersion ()
{
	KernelVersion=$(uname -r | cut -c 1)
}

DisableUTC ()
{   
	local UtcStatus=disable
	[ "${KernelVersion}" !=	"2" ] && timedatectl set-ntp false

	grep -iq "UTC" /etc/adjtime 2>/dev/null 
	if [ "$?" == 0 ] ; then
		Process 1 "Check UTC status is: enable"
		Wait4nSeconds 2
		UtcStatus=enable
	else
		Process 0 "Check UTC status is: disable"
	fi 

	#update in 2017-06-20
	if [ "${UtcStatus}"x == "enable"x  ] ; then

		for((cnt=1;cnt<1000;cnt++))
		do
			grep -iq "UTC" /etc/adjtime 2>/dev/null 
			if [ "$?" == 0 ] ; then
				echo -e "\e[33mBegin to disable UTC ...\e[0m"
				hwclock --systohc --localtime
				#Check again
				continue
		   else
				Process 0 "Check UTC status is: disable"
				break
		   fi
		   [ ${cnt} -ge 5 ] && Process 1 "Disable UTC fail ..." && exit 5
		done   
		
		 CurCmosTime=$(hwclock -r)
		 CurCmosTime=$(date -d "${CurCmosTime}" +%s)
		   CurOsTime=$(date +%s)
	 
		# 8 hours equal 28800 seconds
		GapCmosOs=$(echo "obase=10; ibase=10; ${CurOsTime}-${CurCmosTime}-28800" | bc)
		gap_ABS=`echo "${GapCmosOs#-}"`
		if [ "${gap_ABS}" -le "${Gap}" ] || [ "${gap_ABS}" -le "28800" ]; then
			while :
			do   
				hwclock --hctosys
				if [ $? == 0 ] ; then
					Process 0 "Syncing CMOS time to OS time"
					break 1
				fi
			done	
		else
			Process 1 "CMOS time or OS time are not match"
			printf "%-10s%-60s\n" "" "CMOS time: `hwclock -r`"
			printf "%-10s%-60s\n" "" "  OS time: `date`"
			exit 5
	  fi
	fi
}

CheckTimeZone ()
{
	local GetYear=`date +%Y`
	local CurrentTimeZone=$(date +%z)
	local dst_temp=""

	rm -rf ${TmpLog} 2>/dev/null
	zdump -v /etc/localtime > ${TmpLog} 2>&1
	sync;sync;sync 

	for ((i=1;i<=4;i++))
	do
		# Get the info as dst_flag =
		#[1]Sat Apr 22 21:59:59 2017 EASST isdst=1 
		#[2]Sat Apr 22 21:00:00 2017 EAST isdst=0 
		#[3]Sat Sep  2 21:59:59 2017 EAST isdst=0 
		#[4]Sat Sep  2 23:00:00 2017 EASST isdst=1 
		# or
		#[1]Sat Apr 13 23:59:59 1991 CST isdst=0 
		#[2]Sun Apr 14 01:00:00 1991 CDT isdst=1 
		#[3]Sat Sep 14 23:59:59 1991 CDT isdst=1 
		#[4]Sat Sep 14 23:00:00 1991 CST isdst=0 

		dst_flag[$i]=$(cat ${TmpLog} 2>/dev/null | grep "`date +%Y`" |awk -F'UTC = ' '{print $2}'|awk -F'gmt' '{print $1}' | head -n $i |tail -n 1)
		[ -z "${dst_flag[$i]}" ] && dst_temp="null" && break
		dst_val[$i]=$(echo ${dst_flag[$i]} | awk -F'isdst=' '{print $1}'|head -n $i |tail -n 1)
		dst_tip[$i]=$(echo ${dst_flag[$i]} | awk -F'isdst=' '{print $2}'|head -n $i |tail -n 1)
		dst_val[$i]=$(date -d "${dst_val[$i]}" +%s)
	done

	# For DST enable OS
	if [ "${dst_temp}"x != "null"x ] ; then
		dst_str=$(echo ${dst_tip[@]} | tr -d ' ')
		CurTime=$(date +%s)
		if  [ ${CurTime} -ge ${dst_val[2]} ] && [ ${CurTime} -le ${dst_val[3]} ] ; then
			case $dst_str in
			1001|0110)
				#if TimeZone="+0800",+0100,equal +0900;-0700,+0100,equal -0800
				TimeZoneValue=$(echo 1"$TimeZone" | tr -d '+-' )
				TimeZoneSymbol=$(echo "$TimeZone" | cut -c 1 )

				# For S1401,DST OS
				TimeZoneValue=$(echo "obase=10; ibase=10; $TimeZoneValue-100" | bc | cut -c 2-5)
				TimeZone=$(echo ${TimeZoneSymbol}${TimeZoneValue})
			;;

			*)
				#do nothing
				:
			;;
			esac 
		fi
	fi

	# Verify the time zone
	if [ "$CurrentTimeZone"x == "$TimeZone"x ] ; then
		Process 0 "Check time zone(Cur: UTC/GMT$CurrentTimeZone,Std: UTC/GMT$TimeZone)"
	else
		Process 1 "Check time zone(Cur: UTC/GMT$CurrentTimeZone,Std: UTC/GMT$TimeZone)"
		ShowMsg --b "Warning !! Time zone is fault"
		ShowMsg --e "Please follow WI to remake test program"
		exit 1
	fi
}

CheckOsDstStatus ()
{
	local GetYear=`date +%Y`
	# Get toyear DST status,isdst=1,DST enable,isdst=0 DST disable
	ToyearDstStatus=$( cat ${TmpLog} 2>/dev/null | grep "$GetYear" | grep -ic "isdst=1")
	OsDstStatus=$(echo ${OsDstStatus} | tr [A-Z] [a-z])
	case $OsDstStatus in
		enable)
			if [ "$ToyearDstStatus" -ge 1 ] ; then
				Process 0 "Check the DST status of time zone(status: enable)"
			else
				Process 1 "Check the DST status of Time Zone(status: disable)"
				exit 1
			fi 
		;;

		disable)
			if [ "$ToyearDstStatus" -ge 1 ] ; then
				Process 1 "Check the DST status of time zone(status: enable)"
				exit 1
			else
				Process 0 "Check the DST status of Time Zone(status: disable)"
			fi 
		;;
		
		*)
			Process 1 "Invalid option: ${OsDstStatus}"
			printf "%-10s%-60s\n" "" "OS DST status should be: enable, or disable"	
			exit 3	
		;;
		
		esac
}

# 不限定一定要用主板上的网口，只要用网口并且网口已经连接，并获取IP就可以进行联网
# line 425～453,467 行屏蔽
GetEthId()
{
	#MacArrayFiles=($(ls ${PpidDir}/ | grep -iE "^MAC"))
	#if [ ${#MacArrayFiles[@]} -ge 1 ] ; then
	#	for ((cnt=0;cnt<${#MacArrayFiles[@]};cnt++))
	#	do
	#		MacArray[$cnt]=$(cat -v ${PpidDir}/${MacArrayFiles[$cnt]} | head -n1 )
	#	done
	#
	#	for ((cnt=0;cnt<${#MacArray[@]};cnt++))
	#	do
	#		# Split the MAC Address,e.g.:D8CB8AA7BCE6 to D8:CB:8A:A7:BC:E6
	#		for ((j=1,k=1;j<=6,k<=11;j++,k+=2 ))
	#		do
	#			mac[$j]=$(echo "${MacArray[$cnt]}" | cut -c $k-$(($k+1)))
	#		done
	#		
	#		MacAddr=$(echo "${mac[1]}:${mac[2]}:${mac[3]}:${mac[4]}:${mac[5]}:${mac[6]}" | tr -d '\n ')
	#		if [ "$OsVersion" == "Linux6" ] ; then
	#			EthId[$cnt]=$(ifconfig -a 2>/dev/null | grep "${MacAddr}" | grep -E "^e" | awk '{print $1}')
	#		else
	#
	#			EthId[$cnt]=$(ifconfig -a 2>/dev/null | grep -v "inet" | grep -B 1 -i "${MacAddr}" | awk -F':' '/flag/{print $1}' | grep -vE "^v" )
	#		fi
	#	
	#		EthId[$cnt]=${EthId[$cnt]:-'NonExistent'}
	#		[ "$cnt"x == "0"x ] &&  printf "%-10s%-60s\n" "" '---------------------------------- '	
	#		printf "%-10s%-60s\n" "" "  ${MacArray[$cnt]}: ${EthId[$cnt]}"		
	#		printf "%-10s%-60s\n" "" '----------------------------------'	
	#	done
	#else
		if [ "$KernelVersion"x == "2"x ] ; then
			EthId=($(ifconfig -a 2>/dev/null | grep -iw "HWaddr"|  awk '{print $1}'))
		else
			EthId=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -B 1 -E "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}"|awk -F':' '/flag/{print $1}'| grep -vE "^v" ))
		fi
		printf "%-10s%-60s\n" "" "Found LAN device(s):"
		printf "%-10s%-60s\n" "" '------------------------------------------------------------'	
		for ((e=0;e<${#EthId[@]};e=e+2))
		do
			printf "%-14s%-28s%-28s\n" "" "${EthId[$e]}" "${EthId[e+1]}"
		done
		printf "%-10s%-60s\n" "" '------------------------------------------------------------'	

	#fi

	case ${#EthId[@]} in
		0)
			Process 1 "Search the LAN device fail and no LAN found ..."
			exit 4
		;;

		*)
			NonExistent_cnt=$(echo ${EthId[@]} | tr ' ' '\n' | grep -ic "NonExistent")
			if [ ${NonExistent_cnt} == ${#EthId[@]} ] ; then
				Process 1 "No LAN device found" 
				exit 4
			fi
		;;
		esac
		return 0
}

CheckLinkStatus ()
{
	GetEthId
	for ((cnt=0;cnt<${#EthId[@]};cnt++))	
	do
		ethtool ${EthId[$cnt]} 2>/dev/null | grep -iw "Link detected" | grep -qiw "yes"
		if [ $? == 0 ] ; then
			Process 0 "${EthId[$cnt]} Link detected 'yes' "
			return 0
		fi
	done
	return 1
}

SetTerminalShowEnglish ()
{
	echo $LANG | grep -iwq 'en_US.UTF-8'
	if [ $? != 0 ] ; then
		LANG="en_US.UTF-8"
	fi
	# Set the terminal show English
	# English: LANG="en_US.UTF-8"
	# Chinese: LANG="zh_CN.UTF-8"
}

Connet2Server_ByAnyLAN ()
{
	CheckLinkStatus
	if [ $? == 0 ] ; then
		for ((x=1;x<10;x++))
		do
			ping ${NtpIpAddr} -c 2 -w 3
			if [ "$?" != "0" ] ; then 
				BeepRemind 1
				dhclient -r
				ShowMsg --b "Please plug net cable in a LAN port"
				ShowMsg --e "Wait $TimeOut seconds, press [Enter] to continue"	 
				Wait4nSeconds ${TimeOut} 
				
				if [ $(dhclient --help 2>&1 | grep -wFc "[--timeout" ) == 1 ] ; then
					dhclient --timeout 5 >/dev/null 2>&1
				elif [ $(dhclient --help 2>&1 | grep -wFc "[-timeout" ) == 1 ] ; then
					dhclient -timeout 5 >/dev/null 2>&1
				else
					dhclient >/dev/null 2>&1
					#Process 1 "No argument 'timeout' for dhclient ..."
					#return 1
				fi
			else
				return 0		
			fi
			
			[ ${x} -gt 3 ] && return 1
		done
	fi
	return 1
}

Connet2ServerByOption ()
{
	local NetCard=${1}
	local LanMac=$(ifconfig ${NetCard} 2>/dev/null | tr -d ":" | tr ' ' '\n' | tr '[a-z]' '[A-Z]' | grep -iwE "[0-9A-F]{12}")
	# Connect Server,Show message
	BeepRemind 1
	ShowMsg --b "Plug LAN cable in LAN port: ${LanMac}"
	ShowMsg --e "Press [Enter] key to continue ..."
	Wait4nSeconds ${TimeOut}
	printf "%-s\n" "Try to link the NTP server(IP:${NtpIpAddr})  ..."
	ifconfig ${NetCard} up >/dev/null 2>&1
	sleep 2
	dhclient -r ${NetCard} >/dev/null 2>&1
	dhclient ${NetCard} >/dev/null 2>&1
	sleep 1

	for((m=1;m<10;m++))
	do 
		if [ $(dhclient --help 2>&1 | grep -wFc "[--timeout" ) == 1 ] ; then
			dhclient --timeout 5 ${NetCard} >/dev/null 2>&1
		elif [ $(dhclient --help 2>&1 | grep -wFc "[-timeout" ) == 1 ] ; then
			dhclient -timeout 5 ${NetCard} >/dev/null 2>&1
		else
			dhclient ${NetCard} >/dev/null 2>&1
			#Process 1 "No argument 'timeout' for dhclient ..."
			#return 1
		fi
		
		ping ${NtpIpAddr} -I ${NetCard} -c 2 -w 10
		if [ "$?" == "0" ];then
			Process 0 "ping server from ${NetCard}(${LanMac}) pass"
			break
		else
			Process 1 "ping server from ${NetCard}(${LanMac}) fail"
		fi
		[ ${m} -gt 2 ] && return 1
	done
	return 0
}

SelectNetworkCard()
{
	NetCards=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "([\dA-F]{2}:){5}[\dA-F]{2}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':'))
	if [ ${#NetCards[@]} == 0 ] ;then
		Process 1 "No found any netcard onboard ..."
		exit 1
	fi
	
	rm -rf chooseNetCard 2>/dev/null
	printf "%-s\n" "#!/bin/bash" > chooseNetCard
	printf "%-s\n" "OPTION=\$(whiptail --title \"Network card selection\" --menu \"Please select a network card.\" 15 60 4 \\" >>chooseNetCard
	for((n=0;n<${#NetCards[@]};n++))
	do
		local MacAddress=$(ifconfig ${NetCards[n]} | tr -d ":" | tr ' ' '\n' | tr '[a-z]' '[A-Z]' | grep -iwE "[0-9A-F]{12}")
		printf "%-s%-s%-s\n" "\"$((n+1))\" " " \"${NetCards[n]}  MAC: ${MacAddress}\" " " \\" >>chooseNetCard
	done
	printf "%-s\n" "3>&1 1>&2 2>&3)" >>chooseNetCard
	
	cat<<-Msg >>chooseNetCard
	exitstatus=\$?
	if [ \${exitstatus} = 0 ]; then
		echo "\$OPTION"
	else
		echo "You chose Cancel."
	fi
	Msg
	sync;sync;sync
	chmod 777 chooseNetCard
	SelectCardIndex=$(./chooseNetCard)
	echo ${SelectCardIndex} | grep -iwq "Cancel" && exit 1
	rm -rf chooseNetCard 2>/dev/null
	SelectCard=$(echo ${NetCards[SelectCardIndex-1]} 2>/dev/null)
}

# Connect to the server
Connect2NtpServer ()
{
	Connet2Server_ByAnyLAN
	if [ $? != 0 ] ; then
		if [ "${KernelVersion}"x == "2"x ] ; then
			LastEthId=$(ifconfig -a 2>/dev/null | grep -iw "HWaddr" | grep -i "${MacAddr}" | awk '{print $1}')
		else
			LastEthId=$(ifconfig -a 2>/dev/null | grep -v "inet" | grep -B 1 -iE "${MacAddr}" | awk -F':' '/flag/{print $1}')
		fi
		Connet2ServerByOption "${LastEthId}"
		if [ $? -ne 0 ] ; then
			for((v=1;v<=3;v++))
			do
				command -v whiptail >/dev/null 2>&1 || continue
				SelectNetworkCard
				Connet2ServerByOption "${SelectCard}"
				[ $? == 0 ] && return 0 
			done
			if [ ${v} -ge 4 ] ; then
				exit 1
			fi
		fi
	fi
	return 0
}

NetTime()
{
	local NTPServerTime=""
	while :
	do
		#command "net" is one suit of samba-common-tools-4.7.1-6.el7.x86_64.rpm
		NTPServerTime=$(echo "`net time -S ${NtpIpAddr} 2>&1`")
		echo "${NTPServerTime}" | grep -iq 'Session request failed'
		if [ "$?" != 0 ] && [ ${#NTPServerTime} != 0 ] ; then
			break
		fi	
	done
	echo -ne "Set the OS local date and time as: "
	date -s "${NTPServerTime}" 2>/dev/null 
	local ReturnCode=$?
	[ ${ReturnCode} != 0 ] && echo "null"
	return ${ReturnCode}      
}

SetDateTime ()
{
	for((s=0;s<1000;s++))
	do
		# Set the date via NTP Server
		NetTime
		if [ "$?" -ne 0 ]; then
			Process 1 "Connect to NTP server($NtpIpAddr) by command: net time"
			printf "%-10s%-60s\n" "" "Try to install the \"samba-common-tools*.rpm\" , now try the command: ntpdate ${NtpIpAddr}"
		else
			Process 0 "Connect to NTP Server($NtpIpAddr) by command:  net time"
			break 
		fi
		
		# if NetTime fail
		ntpdate "${NtpIpAddr}"  2>/dev/null
		if [ "$?" -ne 0 ]; then
			Process 1 "Connect to NTP server($NtpIpAddr) by command: ntpdate"
			ShowMsg --1 "Please check net cable has plug in LAN Port"
		else
			Process 0 "Connect to NTP Server($NtpIpAddr) by command: ntpdate"
			break 
		fi
		
		[ $s -ge 5 ] && exit 1
	done

	hwclock --systohc 2>/dev/null
	if [ "$?" -eq 0 ]; then
		Process 0 "Synchronizing NTP server time"
	else
		Process 1 "Synchronizing NTP server time"
		exit 1
	fi
}

CompareDateTime()
{
	while :
	do
		# Get Server time
		NtpdateExist=$(net time -S ${NtpIpAddr} 2>&1  | grep -ic "bash\|not found" )
		case ${NtpdateExist} in
		   1)
				#while the net time command invalid
				while :
				 do       
					#This type include the year
					ServerDateTime=$(ntpdate -d ${NtpIpAddr} | grep -i "originate" | awk -F',' '{print $2}')
					[ ! -z "${ServerDateTime}" ] && break
				done
			;;
		 
		   *)   
				while :
				 do
					ServerDateTime=`net time -S ${NtpIpAddr} 2>/dev/null`	
					[ ! -z "${ServerDateTime}" ] && break
				 done
			;;
			esac
		Process 0 "Getting server($NtpIpAddr) time ..."
			
		# Get CMOS time
		while : 
		do
			CmosDT=$(hwclock -r 2>/dev/null)
			[ ! -z "$CmosDT" ] && break
		done
		Process 0 "Getting Local Hardware(CMOS) time ..."
		 
		  ServerDateTimeValue=$(date -d "$ServerDateTime" +%s)
			CmosDateTimeValue=$(date -d "$CmosDT" +%s)
			  OsDateTimeValue=$(date +%s)
			  
		  ServerDateTime=$(date -d @${ServerDateTimeValue} +"%Y-%m-%d %H:%M:%S %A")
			CmosDateTime=$(date -d @${CmosDateTimeValue} +"%Y-%m-%d %H:%M:%S %A")
			  OsDateTime=$(date -d @${OsDateTimeValue} +"%Y-%m-%d %H:%M:%S %A")
			   
			
		 # Calculate the time gap
		  Tdif_SC=$(echo "obase=10; ibase=10; $ServerDateTimeValue-$CmosDateTimeValue" | bc)
		  Tdif_SO=$(echo "obase=10; ibase=10; $ServerDateTimeValue-$OsDateTimeValue" | bc)

		  Tdif_SC=`echo "${Tdif_SC#-}"`
		  Tdif_SO=`echo "${Tdif_SO#-}"`

		# if the gad of CMOS and Server time is 1 hour ,OS DST is on(0110/1001)
		# then set the Server time to CMOS,for the adjust the CMOS or OS DST 
		DST_FLAG=0
		DST_CMOS=0

		if [ "$Tdif_SC" -ge "3480" ] && [ "$Tdif_SC" -le "3720" ]  ; then
			let DST_FLAG++
			let DST_CMOS=1
		fi

		if [ "$Tdif_SO" -ge "3480" ] && [ "$Tdif_SO" -le "3720" ]  ; then
			let DST_FLAG++
		fi

		if [ ${DST_FLAG} == 2 ] || [ ${DST_CMOS} == 1 ] ; then
		case $dst_str in
			1001|0110)
				while :
				do
					ToYear=`date +%Y`
					printf "%-10s%-60s\n" "" "DST start at: `cat ${TmpLog} 2>/dev/null | grep "${ToYear}" | awk -F'=' '{print $2}' | sed 's/isdst//g' | sed 's/  / /g' | sed -n 2p | date +"%Y-%m-%d %H:%M:%S %Z %A"`"
					printf "%-10s%-60s\n" "" "DST   end at: `cat ${TmpLog} 2>/dev/null | grep "${ToYear}" | awk -F'=' '{print $2}' | sed 's/isdst//g' | sed 's/  / /g' | sed -n 3p | date +"%Y-%m-%d %H:%M:%S %Z %A"`"
					printf "%-10s%-60s\n" "" "Real time is: `date +"%Y-%m-%d %H:%M:%S %Z %A"`"
					SetDateTime 
					Process $? "Automatic adjust to DST ... " && continue 2
				done
			;;

			*)
				#do nothing
				:
			 ;;
			esac 
		fi

		break
		
	done
	# if OS is Linux 7.x ,then show the time zone,DST,UCT,RTC,local time
	[ "$KernelVersion"x != "2"x ] && timedatectl | head -n8 
	which getCmosDT >/dev/null 2>&1 && getCmosDT

	printf "%-s\n" "*********************************************************************"
	printf "%-s\n" "      Compare server time and local time, Deviation:$Gap     "
	printf "%-s\n" "-----------------------------------------------------------  "
	printf "%-s\n" "    Server date and time: ${ServerDateTime}                  "
	printf "%-s\n" "      CMOS date and time: ${CmosDateTime}                    "
	printf "%-s\n" "        OS date and time: ${OsDateTime}                      "
	printf "%-s\n" "*********************************************************************"

	if [ "$Tdif_SC" -le "$Gap" ] && [ "$Tdif_SO" -le "$Gap" ]; then
		echoPass "Compare Date and time(Deviation:${Tdif_SC},${Tdif_SO})"
	else
		echoFail "Compare Date and time(Deviation:${Tdif_SC};${Tdif_SO})"	
		GenerateErrorCode
		exit 1
	fi
}

main()
{
	OsDstStatus=${OsDstStatus:-disable}
	SetTerminalShowEnglish
	#Auto connect network
	NetworkManager
	GetKernelVersion
	DisableUTC
	CheckTimeZone
	CheckOsDstStatus
	Connect2NtpServer
	[ ${SetTime}x == "enable"x ] && SetDateTime
	CompareDateTime
	[ ${ErrorFlag} != 0 ] && exit 1
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i TimeOut=5
declare -i ErrorFlag=0
declare SetTime=disable
declare NtpIpAddr TimeZone OsDstStatus Gap EthId MacArray KernelVersion MacAddr XmlConfigFile SelectCard ApVersion
declare PpidDir="../PPID"
declare TmpLog='/.zdump.log'
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
			printf "%-s\n" "SerialTest,SetCmosTime"
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
