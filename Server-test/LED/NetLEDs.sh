#!/bin/bash
#FileName : NetLEDs.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2020-11-13"
	local UpdatedDate="2020-11-27"
	local Description="網卡LEDs同時測試"
	
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
	printf "%16s%-s\n" "" "2020-11-27, 新增萬兆網卡的支持,需要使用celo64e, eeupdate64e等tools"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet ethtool $@)
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
	-d : Show the status code, for debug only
	-V : Display version number and exit(1)	
				
	return code:
		0 : LED status verify pass
		1 : LED status verify fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
		
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<LED>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXLAF|LAN led abnormal</ErrorCode>
			
			<!--${BaseName}.sh計數測試法-->
			<!--可選工具: ethtool/celo64e/bootutil64e,1G 網卡使用celo64e無效-->
			<!--ethtool: 適用於1G及以下的網卡 網卡使用celo64e無效-->
			<!--celo64e/bootutil64e: 適用於10G或以上的網卡-->
			<SpeedControlTool>celo64e</SpeedControlTool>
			<!-- LAN MAC is for getting location for LAN port，按MAC獲取Port-->
			<LanMac>/TestAP/Scan/MAC1.TXT</LanMac>
			<LanMac>/TestAP/Scan/MAC2.TXT</LanMac>
			<LanMac>/TestAP/Scan/MAC3.TXT</LanMac>
			<LanMac>/TestAP/Scan/MAC4.TXT</LanMac>
			
			<!--缺省或DHCP則程式自動獲取,ethtool控制的時候有有效-->
			<IPaddress>192.168.1.10</IPaddress>
			<SubnetMask>255.255.255.0</SubnetMask>
			
			<!--on/off: 設置網卡是否自動協商,ethtool控制的時候有有效-->
			<Autoneg>on</Autoneg>
			<!--half/full: 設置網卡半雙工/全雙工-->
			<Duplex>full</Duplex>
			
			<!--Off/Dark:0; Orange/amber:1; Green:2 -->
			<ActiveLED>2</ActiveLED>
			<SpeedLED>
				<!--Speed將傳給celo64e設置速度,其他的方式不會使用此參數,Spd10000Mbps可用於100G/40G的設置-->
				<Spd10Mbps Speed="10">0</Spd10Mbps>
				<Spd100Mbps Speed="100">0</Spd100Mbps>
				<Spd1000Mbps Speed="50G">1</Spd1000Mbps>
				<Spd10000Mbps Speed="100G">2</Spd10000Mbps>
			</SpeedLED>
			
			<AlwaysLightUp>
				<!--常亮的LED位置,顏色代碼1/2有效-->
				<Loction ColorCode="2">LED9</Loction>
			</AlwaysLightUp>
		</TestCase>
	</LED>
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
	SpeedControlTool=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedControlTool" -n "${XmlConfigFile}" 2>/dev/null)
	LanMacFiles=($(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/LanMac" -n "${XmlConfigFile}" 2>/dev/null))
	FirstIPaddress=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/IPaddress" -n "${XmlConfigFile}" 2>/dev/null)
	SubnetMask=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SubnetMask" -n "${XmlConfigFile}" 2>/dev/null)
	Autoneg=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Autoneg" -n "${XmlConfigFile}" 2>/dev/null)
	Duplex=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Duplex" -n "${XmlConfigFile}" 2>/dev/null)
	ActiveLEDColor=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/ActiveLED" -n "${XmlConfigFile}" 2>/dev/null)
	Spd10MbpsColor=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedLED/Spd10Mbps" -n "${XmlConfigFile}" 2>/dev/null)
	Spd100MbpsColor=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedLED/Spd100Mbps" -n "${XmlConfigFile}" 2>/dev/null)
	Spd1000MbpsColor=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedLED/Spd1000Mbps" -n "${XmlConfigFile}" 2>/dev/null)
	Spd10000MbpsColor=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedLED/Spd10000Mbps" -n "${XmlConfigFile}" 2>/dev/null)
	AlwaysLightUp=($(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/AlwaysLightUp/Loction" -n "${XmlConfigFile}" 2>/dev/null | tr -d ' '))
	AlwaysLightUpColor1=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/AlwaysLightUp/Loction[@ColorCode=\"1\"]" -n "${XmlConfigFile}" 2>/dev/null | grep -iEc "[0-9A-Z]" )
	AlwaysLightUpColor2=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/AlwaysLightUp/Loction[@ColorCode=\"2\"]" -n "${XmlConfigFile}" 2>/dev/null | grep -iEc "[0-9A-Z]" )

	echo "${SpeedControlTool}" | grep -wq "celo64e\|ethtool\|bootutil64e"
	if [ $? != 0 ] ; then
		Process 1 "Invalid Speed Control Tool: ${SpeedControlTool} "
		let ErrorFlag++
	else
		echo "${SpeedControlTool}" | grep -wq "celo64e\|bootutil64e"
		if [ $? == 0 ] ; then
			if [ ${#Spd10000MbpsColor} == 0 ] ; then
				Process 1 "No found the 10G Speed color code: Spd10000MbpsColor "
				let ErrorFlag++
			fi
		fi		
	fi
	
	if [ $((${#LanMacFiles[@]}%2)) != 0 ] ; then
		Process 1 "Only for testing even Numbers of network CARDS ..."
		let ErrorFlag++
	fi

	for((f=0;f<${#LanMacFiles[@]};f++))
	do
		if [ ! -f ${LanMacFiles[f]} ] ; then
			Process 1 "No such MAC file: ${LanMacFiles[f]}"
			LanMac[$f]='000000000000'
			let ErrorFlag++
		else
			LanMac[$f]=$(cat ${LanMacFiles[f]} | head -n1 | grep -iwE "[0-9A-F]{12}" )
		fi
		
		if [ ${#LanMac[f]} == 0 ] ; then
			Process 1 "Invalid LAN MAC address: `cat ${LanMacFiles[f]}`"
			let ErrorFlag++
		fi
	done

	if [ ${#FirstIPaddress} != 0 ] ; then
		CheckIPaddr ${FirstIPaddress} || let ErrorFlag++
		CheckIPaddr ${SubnetMask} || let ErrorFlag++
	fi
	
	echo "${SpeedControlTool}" | grep -iwq "ethtool"
	if [ $? == 0 ] ; then
		echo "${Autoneg}" | grep -wq "on\|off"
		if [ $? != 0 ] ; then
			Process 1 "Invalid Autoneg: ${Autoneg} "
			let ErrorFlag++
		fi
	
		echo "${Duplex}" | grep -wq "half\|full"
		if [ $? != 0 ] ; then
			Process 1 "Invalid Duplex: ${Duplex} "
			let ErrorFlag++
		fi
	fi

	for led in ActiveLEDColor Spd10MbpsColor Spd100MbpsColor Spd1000MbpsColor Spd10000MbpsColor
	do
		case ${led} in
		ActiveLEDColor)ColorCode=${ActiveLEDColor};;
		Spd10MbpsColor)ColorCode=${Spd10MbpsColor};;
		Spd100MbpsColor)ColorCode=${Spd100MbpsColor};;
		Spd1000MbpsColor)ColorCode=${Spd1000MbpsColor};;
		Spd10000MbpsColor)ColorCode=${Spd10000MbpsColor};;
		esac
		
		[ ${#ColorCode} == 0 ] && continue
		echo ${ColorCode} | grep -iwEq "[0-2]"
		if [ $? != 0 ] ; then
			Process 1 "Invalid LED color code: ${ColorCode}"
			let ErrorFlag++			
		fi
	done

	if [ ${ActiveLEDColor} == 1 ] ; then
		Question=(1 2)
	else
		Question=(2 1)
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

GetNetcardInterface()
{
	for((L=0;L<${#LanMac[@]};L++))
	do
		NetCards[$L]=$(ifconfig -a 2>/dev/null | grep -v "inet" | tr -d ":" | grep -iB3 "${LanMac[L]}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':')
		if [ ${#NetCards[$L]} == 0 ] ; then
			NetCards[L]='NoExist'
			Process 1 "Not found the network card(MAC address: ${LanMac[L]}) ... "
			let ErrorFlag++
		fi
	done
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0
}

GetNicIndex()
{
	printf "%s\n" "Dump the MAC address, please wait ..."
	SoleLanMac=($(echo ${LanMac[@]} | tr ' ' '\n' | sort -u ))
	SoleLanMac=$(echo ${SoleLanMac[@]} | sed 's/ /\\|/g')
	NicIndexS=($(eeupdate64e /all /mac_dump 2>/dev/null | grep -iw "${SoleLanMac}" | awk '{print $1}' | tr -d ': '))

	if [ ${#NicIndexS[@]} != ${#LanMac[@]} ] ; then
		Process 1 "The NIC number was not found for some MAC(s) ... "
		eeupdate64e /all /mac_dump | grep -iw "${SoleLanMac}" 2>/dev/null
		let ErrorFlag++
		exit 1
	fi
	return 0
}

KillSetIPaddress()
{
	rm -rf setIPaddress setSpeed-* >& /dev/null
	ps ax | awk '/setIPaddress/{print $1}' | while read PID
	do
		kill -9 "${PID}" >& /dev/null
	done
	dhclient -r >& /dev/null
}

SetIP()
{	
	KillSetIPaddress
	printf "%-s\n" "#!/bin/bash" > setIPaddress
	printf "%-s\n" "while :"     >> setIPaddress
	printf "%-s\n" "do"          >> setIPaddress
	
	local IPaddressSplitX4=($(echo "${FirstIPaddress}" | tr '.' " "))
	
	for((n=0;n<${#NetCards[@]};n++))
	do
		printf "%s\n" "ifconfig \"${NetCards[n]}\" \"${IPaddressSplitX4[0]}.${IPaddressSplitX4[1]}.${IPaddressSplitX4[2]}.$((${IPaddressSplitX4[3]}+n))\" netmask \"${SubnetMask}\"" >> setIPaddress
	done
	printf "%-s\n" "done" >> setIPaddress
	sync;sync;sync
	
	chmod 777 setIPaddress
	`./setIPaddress` &
	
	printf "%s" "Set IP address, please wait "
	for((i=1;i<=3;i++));do
		printf "%s" "."
		sleep 1
	done
	echo
	
	for((n=0;n<${#NetCards[@]};n++))
	do
		ifconfig "${NetCards[n]}" | grep -wq "${IPaddressSplitX4[0]}.${IPaddressSplitX4[1]}.${IPaddressSplitX4[2]}.$((${IPaddressSplitX4[3]}+n))"
		Process $? "Set ${NetCards[n]}'s IP: ${IPaddressSplitX4[0]}.${IPaddressSplitX4[1]}.${IPaddressSplitX4[2]}.$((${IPaddressSplitX4[3]}+n))" || let ErrorFlag++
		sleep 1
	done
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0
}

SetSpeedEthtool()
{
	local EthId=$1
	local SpeedCode=$2
	local Speed=10
	case ${SpeedCode} in 
		1)Speed=10;;
		2)Speed=100;;
		3)Speed=1000;;
	esac	
	
	rm -rf setSpeed-${EthId} 2>/dev/null
	cat <<-setSpeeds > setSpeed-${EthId}
	#!/bin/bash
	ethtool "${EthId}" | grep -i "Link detected" | grep -iwq 'yes'
	if [ \$? == 0 ] && [ \$(ethtool "${EthId}" | grep -iwc "Speed: ${Speed}Mb/s") == 1 ] ; then
		exit 0
	fi
	for((r=1;r<=3;r++))
	do
		dhclient -r "${EthId}" >/dev/null 2>&1
		sleep 1
		ifconfig "${EthId}" down 2>/dev/null || continue
		sleep 1
		ifconfig "${EthId}" up 2>/dev/null || continue
		sleep 1
		
		ethtool -s "${EthId}" duplex ${Duplex} autoneg ${Autoneg} speed ${Speed} >/dev/null 2>&1
		sleep 2
		for ((T=0;T<=3;T++))
		do
			ethtool "${EthId}" | grep -i "Link detected" | grep -iwq 'yes'
			if [ \$? == 0 ] ; then
				break 2
			fi
			sleep 1
		done
	done
	
	if [ \${r} == 4 ] ; then
		printf "\e[1;31m%s\e[0m\n" " Fail to set \"${EthId}\"'s as ${Speed}Mbps ... " >> linkStatus.log
	fi
	setSpeeds
	
	chmod 777 setSpeed-${EthId}
	`./setSpeed-${EthId} 2>/dev/null` &
}

SetSpeedCelo64e()
{
	local NicIndex=$1
	local SpeedCode=$2
	local Speed=1000
	case ${SpeedCode} in 
		3)
			#Speed=1000
			Speed=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedLED/Spd1000Mbps/@Speed" -n "${XmlConfigFile}" 2>/dev/null)
		;;
		4)
			#Speed=10G
			Speed=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/SpeedLED/Spd10000Mbps/@Speed" -n "${XmlConfigFile}" 2>/dev/null)
		;;
	esac	
	
	rm -rf setSpeed-${NicIndex} 2>/dev/null
	cat <<-setSpeeds > setSpeed-${NicIndex}
	#!/bin/bash
	celo64e /nic=${NicIndex} /ttl /autonegspeed ${Speed} /TIMEOUT 15
	setSpeeds
	
	rm -rf setSpeed-${NicIndex}.log CELO.LOG 2>/dev/null
	chmod 777 setSpeed-${NicIndex}
	`./setSpeed-${NicIndex} 1>setSpeed-${NicIndex}.log 2>/dev/null` &
}


BlinkLEDBootutil64e()
{
	local NicIndex=$1
	rm -rf Blink-${NicIndex} 2>/dev/null
	cat <<-setBlink > Blink-${NicIndex}
	#!/bin/bash
	bootutil64e /nic=${NicIndex} /BLINK
	setBlink
	
	rm -rf Blink-${NicIndex}.log 2>/dev/null
	chmod 777 Blink-${NicIndex}
	`./Blink-${NicIndex} 1>Blink-${NicIndex}.log 2>/dev/null` &
}

GetDisplayMode()
{
	if [ "$(uname -r | cut -c 1 )" -lt "3" ] ; then 
		grep -iq "id:5:" /etc/inittab >/dev/null 2>&1
	else
		systemctl get-default | grep -iq "graphical" >/dev/null 2>&1
	fi
	GraphicalMode=$?
}

PromptMessage()
{
	printf "\e[1;30;43m%-s\e[0m\n" " ******************************************************************** "
	if [ "${GraphicalMode}" == 0 ] ; then
		printf "\e[1;30;43m%-s\e[0m\n" " **         若發現LED顏色的數量和輸入的確實不符,請轉入維修站       ** "
		printf "\e[1;30;43m%-s\e[0m\n" " **         觀察以下指定網卡上的LED燈並按要求按顏色計數測試        ** "
	else
		printf "\e[1;30;43m%-s\e[0m\n" " **         Observe the LEDs of the following network cards        ** "
	fi
	for((n=0;n<${#NetCards[@]};n++))
	do
		printf "\e[1;30;43m%-16s%12s%-12s%30s\e[0m\n" " **          " "${NetCards[n]}: " "${LanMac[n]}" "** " 
	done
	for LED in `printf "%s\n" "${AlwaysLightUp[@]}"`
	do
		printf "\e[1;30;43m%-20s%-20s%30s\e[0m\n" " **          " "${LED}" "** " 
	done
	printf "\e[1;30;43m%-s\e[0m\n" " ******************************************************************** "

}

ControlledByEthtool()
{
	SetIP
	for((g=0;g<$((${#NetCards[@]}/2));g++))
	do
		local R=$((RANDOM%${#RandomSpeedCode_1G[@]}))
		OrderOfLighting[$g]=${RandomSpeedCode_1G[R]}
	done
	
	for((t=0;t<${#RandomSpeedCode_1G[0]};t++))
	do
		[ ${t} != 0 ] && clear
		PromptMessage		
		local StandardAnswer=''
		rm -rf linkStatus.log
		for((g=0,G=0;g<${#NetCards[@]};g=g+2,G++))
		do
			SetSpeedEthtool "${NetCards[g]}" "${OrderOfLighting[G]:$t:1}"
			case "${OrderOfLighting[G]:$t:1}" in 
			'1')StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd10MbpsColor} ${ActiveLEDColor} ${Spd10MbpsColor}");;
			'2')StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd100MbpsColor} ${ActiveLEDColor} ${Spd100MbpsColor}");;
			'3')StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd1000MbpsColor} ${ActiveLEDColor} ${Spd1000MbpsColor}");;
			esac
		done
		let OrangeAmberAmount=$(printf "%s\n" "${StandardAnswer}" | grep -o "[0-9]" | grep -iwc "1")+${AlwaysLightUpColor1}
		let GreenAmount=$(printf "%s\n" "${StandardAnswer}" | grep -o "[0-9]" | grep -iwc "2")+${AlwaysLightUpColor2}
		sleep 1
		printf "%s\n" "Set the network card's speed, please wait ..."
		for((s=1;s>0;s++))
		do
			if [ $(ps ax | grep -iwc "setSpeed") -le 1 ] ; then
				break
			else
				printf "%s" ">"
				if [ $((s%70)) == 0 ] ; then
					printf "\r%s\r" "                                                                       "
				fi
				sleep 1
			fi
		done
		echo
		cat linkStatus.log 2>/dev/null | grep -iwq "Fail"
		if [ $? == 0 ] ; then
			cat linkStatus.log 2>/dev/null | sort -u
			KillSetIPaddress
			exit 1
		fi
		
		BeepRemind 0
		numlockx on 2>/dev/null
		[ ${Debug} == 'enable' ] && echo "The number of greep and orange/amber/yellow LEDs are ${GreenAmount} PCs and ${OrangeAmberAmount} PCs"
		
		if [ "${GraphicalMode}" == 0 ] ; then
			for((q=0;q<${#Question[@]};q++))
			do
				if [ ${Question[q]} == 2 ] ; then
					tput sc;tput rc;tput ed;
					echo -en "現在指定位置上亮的\e[1;32m青/綠/翡翠色燈\e[0m的總數量是: "
					read -n ${#GreenAmount} -t 15 GreenAns
					echo -e "\b${GreenAns}"
				else
					tput sc;tput rc;tput ed;
					echo -en "現在指定位置上亮的\e[1;33m橙/黃/琥珀色燈\e[0m的總數量是: "
					read -n ${#OrangeAmberAmount} -t 15 OrangeAmberAns
					echo -e "\b${OrangeAmberAns}"
				fi
			done
		else
			for((q=0;q<${#Question[@]};q++))
			do
				if [ ${Question[q]} == 2 ] ; then
					tput sc;tput rc;tput ed;
					echo -en "Now the number of \e[1;32mgreen\e[0m LEDs is: "
					read -n ${#GreenAmount} -t 15 GreenAns
					echo -e "\b${GreenAns}"
				else
					tput sc;tput rc;tput ed;
					echo -en "Now the number of \e[1;33morange/amber/yellow\e[0m LEDs is: "
					read -n ${#OrangeAmberAmount} -t 15 OrangeAmberAns
					echo -e "\b${OrangeAmberAns}"
				fi
			done
		fi		
		echo	

		if [ "${OrangeAmberAmount}"x == "${OrangeAmberAns}"x ] &&  [ "${GreenAmount}"x == "${GreenAns}"x ] ; then
			Process 0 "The number of orange/amber/yellow and green LEDs are ${OrangeAmberAmount} PCs and ${GreenAmount} PCs "
			rm -rf setSpeed-* 2>/dev/null
		else
			Process 1 "Error number of orange/amber/yellow and green LEDs"
			let ErrorFlag++
			break
		fi
	done

	# 還原速率到1000Mbps
	echo -e "\nTest finish ..."
	for((g=0;g<${#NetCards[@]};g=g+2))
	do
		SetSpeedEthtool "${NetCards[g]}" "3" >/dev/null 2>&1
	done
	
	printf "%s\n" "Set the network card's speed as default, please wait ..."
	for((s=1;s>0;s++))
	do
		if [ $(ps ax | grep -iwc "setSpeed") -le 1 ] ; then
			break
		else
			printf "%s" ">"
			if [ $((s%70)) == 0 ] ; then
				printf "\r%s\r" "                                                                       "
			fi
			sleep 1
		fi
	done
	echo
	KillSetIPaddress 
}

ControlledByCelo64e()
{
	ChkExternalCommands "celo64e" "eeupdate64e"
	GetNicIndex
	for((g=0;g<$((${#NicIndexS[@]}/2));g++))
	do
		local R=$((RANDOM%${#RandomSpeedCode_10G[@]}))
		OrderOfLighting[$g]=${RandomSpeedCode_10G[R]}
	done
	
	#10G 網卡LED在設置狀態後若干秒內就恢復了初始值，無法保持狀態,因此只能詢問該狀態的LED燈顏色數量
	if [ $((RANDOM%2)) == 1 ] ; then
		Question=(1 2)
	else
		Question=(2 1)
	fi
	
	for((q=0;q<${#Question[@]};q++))
	do
		local TestTwice="Yes"
		for((t=0;t<${#RandomSpeedCode_10G[0]};t++))
		do
			[ ${q} != 0 ] && clear
			PromptMessage		
			local StandardAnswer=''

			if [ "${GraphicalMode}" == 0 ] ; then
				if [ ${Question[q]} == 2 ] ; then
					echo -en "請開始計數指定位置上亮的\e[1;32m青/綠/翡翠色燈\e[0m的總數量 ..."
				else
					echo -e "請開始計數指定位置上亮的\e[1;33m橙/黃/琥珀色燈\e[0m的總數量 ... "
				fi
			else
				if [ ${Question[q]} == 2 ] ; then
					echo -e "Begin counting the \e[1;32mgreen\e[0m light at the specified location ..."
				else
					echo -e "Begin counting the \e[1;33morange/amber/yellow\e[0m light at the specified location ..."
				fi
			fi
			echo
			
			if [ ${Question[q]} == ${ActiveLEDColor} ] ; then
				# 不設置網卡狀態，全部是按常態計數
				for((g=0;g<${#NicIndexS[@]};g=g+2))
				do
					StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd10000MbpsColor} ${ActiveLEDColor} ${Spd10000MbpsColor}")
					TestTwice="no"
				done
			else
				for((g=0,G=0;g<${#NicIndexS[@]};g=g+2,G++))
				do
					case "${OrderOfLighting[G]:$t:1}" in 
					'3')
						SetSpeedCelo64e "${NicIndexS[g]}" "${OrderOfLighting[G]:$t:1}"
						StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd1000MbpsColor} ${ActiveLEDColor} ${Spd1000MbpsColor}");;
					'4')StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd10000MbpsColor} ${ActiveLEDColor} ${Spd10000MbpsColor}");;
					esac
				done
			fi
			let OrangeAmberAmount=$(printf "%s\n" "${StandardAnswer}" | grep -o "[0-9]" | grep -iwc "1")+${AlwaysLightUpColor1}
			let GreenAmount=$(printf "%s\n" "${StandardAnswer}" | grep -o "[0-9]" | grep -iwc "2")+${AlwaysLightUpColor2}
			sleep 1
			printf "%s\n" "Set the network card's speed, please wait ..."
			for((s=1;s>0;s++))
			do
				if [ $(ps ax | grep -iwc "setSpeed") -le 1 ] ; then
					break
				else
					printf "%s" ">"
					if [ $((s%70)) == 0 ] ; then
						printf "\r%s\r" "                                                                       "
					fi
					sleep 1
				fi
			done
			echo
			
			BeepRemind 0
			numlockx on 2>/dev/null
			[ ${Debug} == 'enable' ] && echo "The number of greep and orange/amber/yellow LEDs are ${GreenAmount} PCs and ${OrangeAmberAmount} PCs"
			
			echo -e "結束計數(The end of the count)... "
			if [ "${GraphicalMode}" == 0 ] ; then
				if [ ${Question[q]} == 2 ] ; then
					tput sc;tput rc;tput ed;
					echo -en "這段時間內,你看到了多少個位置上亮了\e[1;32m青/綠/翡翠色燈\e[0m,答案是:"
					read -n ${#GreenAmount} -t 15 GreenAns
					echo -e "\b${GreenAns}"
				else
					tput sc;tput rc;tput ed;
					echo -en "這段時間內,你看到了多少個位置上亮了\e[1;33m橙/黃/琥珀色燈\e[0m,答案是: "
					read -n ${#OrangeAmberAmount} -t 15 OrangeAmberAns
					echo -e "\b${OrangeAmberAns}"
				fi
			else
				if [ ${Question[q]} == 2 ] ; then
					tput sc;tput rc;tput ed;
					echo -en "During this time, the number of \e[1;32mgreen\e[0m LEDs is: "
					read -n ${#GreenAmount} -t 15 GreenAns
					echo -e "\b${GreenAns}"
				else
					tput sc;tput rc;tput ed;
					echo -en "During this time, the number of \e[1;33morange/amber/yellow\e[0m LEDs is: "
					read -n ${#OrangeAmberAmount} -t 15 OrangeAmberAns
					echo -e "\b${OrangeAmberAns}"
				fi
			fi
			echo
			
			if [ "${OrangeAmberAmount}"x == "${OrangeAmberAns}"x ] ||  [ "${GreenAmount}"x == "${GreenAns}"x ] ; then
				Process 0 "The number of orange/amber/yellow and green LEDs are ${OrangeAmberAmount} PCs and ${GreenAmount} PCs "
				rm -rf setSpeed-* CELO.LOG 2>/dev/null
			else
				Process 1 "Error number of orange/amber/yellow and green LEDs"
				let ErrorFlag++
				break
			fi
			[ ${TestTwice} == "no" ] && continue 2	
		done
	done
}

Random()
{
    local min=$1
	local max=$(($2-$1))
    local num=$(date +%s+%N | bc)
    echo $((num%max+min))     
}

RandomNoRepetition()
{
	local num="$1"
	#獲取1~num個隨機不重複的數
	while :
	do
		for((i=0;i<${num};i++))
		do 
			local arrary[i]=$(Random 1 ${#LanMacFiles[@]})
		done
		
		echo "${arrary[@]}" | tr ' ' '\n' | sort -u | wc -l | grep -iwq "${num}" 
		if [ $? == 0 ]; then
			echo "${arrary[@]}" | tr ' ' '\n' | sort -ns
			break
		fi
	done
}

RandomSort()
{
	local LedsAcount="$1"
	local TempFile=${BaseName}_sort.txt
	
	rm -rf ${TempFile} 2>/dev/null
	touch ${TempFile} 2>/dev/null
	
	while :
	do
		sort -u  ${TempFile} | wc -l | grep -wq "${LedsAcount}" && break
		echo $(($RANDOM%${LedsAcount}+1)) >>${TempFile}
	done
	
	local AllNumber=($(cat ${TempFile}))
	LEDsIndex=()
	LEDsIndex[0]=$(head -n1 ${TempFile}) 	
	for((j=1;j<${LedsAcount};j++))
	do
		SoleLEDsIndex=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | sort -u ))
		SoleLEDsIndex=$(echo ${SoleLEDsIndex[@]} | sed 's/ /\\|/g')
		
		for ((n=0;n<${#AllNumber[@]};n++))
		do
			echo ${AllNumber[n]} | grep -iwq "${SoleLEDsIndex}" 
			if [ $? != 0 ] ; then
				LEDsIndex[j]=${AllNumber[n]}
				continue 2
			fi
		done
	done
	#對LED進行隨機排序存在數組LEDsIndex,然後截取按一定規則截取分組
	#echo ${LEDsIndex[@]}		
}

CountingOn()
{
	local LedSwitchStr="0000000000000000000000000000000000000000000000000000000000000000"
	# Random RandomNoRepetition RandomSort CountingOn是分組的核心
	# 此處0代表OFF
	SwitchOffAll=$(echo ${LedSwitchStr} | cut -c 1-${#LanMacFiles[@]} )
	Min2Max=($(echo 2 $((${#LanMacFiles[@]}+1)) | tr ' ' '\n' | sort -ns))
	ActualOnOff[0]=$(Random ${Min2Max[@]})

	#獲得LEDs隨機序號
	RandomSort ${#LanMacFiles[@]}
	#ActualOnOff隨機長度(範圍是 MinTurnOnoff ~ MaxTurnOnoff)
	Sum=0
	
	#分組個數
	GroupNumber=0
	for((t=0;t<20;t++))
	do
		ActualOnOff[$t]=$(Random ${Min2Max[@]})
		Sum=$((Sum+${ActualOnOff[$t]}))
		if [ ${Sum} -ge ${#LanMacFiles[@]} ] ; then
			#各組數量總和相加不小於LED總數即退出
			GroupNumber="${t}"
			break
		fi
	done
	
	Sum=0
	for((g=0;g<=${GroupNumber};g++))
	do
		#對LEDsIndex分組,以便分別點亮
		#LedGroup[$g]=(21 12 10 3 4)
		LedGroup=()
		if [ ${g} == 0 ] ; then
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | head -n ${ActualOnOff[g]}))
		elif [ ${g} == ${GroupNumber} ]; then
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | tail -n ${ActualOnOff[g]}))
		else
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | sed -n "$((Sum+1)),$((${ActualOnOff[g]}+Sum))p"))
		fi

		Sum=$((Sum+${ActualOnOff[g]}))
		
		SwitchOn[$g]=${SwitchOffAll}
		for((j=0;j<${#LedGroup[@]};j++))
		do
			#把LedGroup指定序號的LED點亮,1 is on
			SwitchOn[$g]=$(echo ${SwitchOn[g]} | grep -o "[0-1]" | sed "${LedGroup[j]}c 1" )
		done
		SwitchOn[$g]=$(echo ${SwitchOn[$g]} | tr -d ' ')

		ActualOn[$g]=$(echo ${SwitchOn[$g]} | grep -oE "[0-1]" | grep -wc "1" )
		#點亮的LED數量
		printf "%s\n" "${ActualOn[$g]};${SwitchOn[$g]}"
	done
	echo
}

CountingOff()
{
	local LedSwitchStr="1111111111111111111111111111111111111111111111111111111111111111"
	# Random RandomNoRepetition RandomSort CountingOn是分組的核心
	# 此處0代表OFF
	SwitchOnAll=$(echo ${LedSwitchStr} | cut -c 1-${#LanMacFiles[@]} )
	Min2Max=($(echo 2 $((${#LanMacFiles[@]}+1)) | tr ' ' '\n' | sort -ns))
	ActualOnOff[0]=$(Random ${Min2Max[@]})

	#獲得LEDs隨機序號
	RandomSort ${#LanMacFiles[@]}
	#ActualOnOff隨機長度(範圍是 MinTurnOnoff ~ MaxTurnOnoff)
	Sum=0
	
	#分組個數
	GroupNumber=0
	for((t=0;t<20;t++))
	do
		ActualOnOff[$t]=$(Random ${Min2Max[@]})
		Sum=$((Sum+${ActualOnOff[$t]}))
		if [ ${Sum} -ge ${#LanMacFiles[@]} ] ; then
			#各組數量總和相加不小於LED總數即退出
			GroupNumber="${t}"
			break
		fi
	done
	
	Sum=0
	for((g=0;g<=${GroupNumber};g++))
	do
		#對LEDsIndex分組,以便分別點亮
		#LedGroup[$g]=(21 12 10 3 4)
		LedGroup=()
		if [ ${g} == 0 ] ; then
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | head -n ${ActualOnOff[g]}))
		elif [ ${g} == ${GroupNumber} ]; then
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | tail -n ${ActualOnOff[g]}))
		else
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | sed -n "$((Sum+1)),$((${ActualOnOff[g]}+Sum))p"))
		fi

		Sum=$((Sum+${ActualOnOff[g]}))
		
		SwitchOff[$g]=${SwitchOnAll}
		for((j=0;j<${#LedGroup[@]};j++))
		do
			#把LedGroup指定序號的LED點亮,0 is off
			SwitchOff[$g]=$(echo ${SwitchOff[g]} | grep -o "[0-1]" | sed "${LedGroup[j]}c 0" )
		done
		SwitchOff[$g]=$(echo ${SwitchOff[$g]} | tr -d ' ')

		ActualOff[$g]=$(echo ${SwitchOff[$g]} | grep -oE "[0-1]" | grep -wc "1" )
		#點亮的LED數量
		printf "%s\n" "${ActualOff[$g]};${SwitchOff[$g]}"
	done
	echo
}

ControlledByBootutil64e()
{
	ChkExternalCommands "bootutil64e" "eeupdate64e"
	GetNicIndex
	for ((i=1;i<=2;i++))
	do
		Error=0
		#CheckList: 點亮數量;點亮位置,如3;1110 3;1011這樣的數組
		if [ $((i%2)) == 1 ] ; then
			CheckList=($(CountingOn))
		else
			CheckList=($(CountingOff))
		fi

		for((c=0;c<${#CheckList[@]};c++))
		do
			#[ ${c} != 0 ] && clear
			clear
			StandardAnswer=''
			local SetBlinkLEDs=0
			PromptMessage
			TurnOnCount=$(echo "${CheckList[c]}" | awk -F';' '{print $1}')
			bit=$(echo "${CheckList[c]}" | awk -F';' '{print $NF}' )
			#把點亮的LED Show 到Log內
			if [ $((i%2)) == 1 ] ; then
				bit2Bin=$(echo "00000000000000000000000000000000000000000${bit}")
			else
				bit2Bin=$(echo "11111111111111111111111111111111111111111${bit}")
			fi
			#echo bit2Bin: ${bit2Bin}

			for((n=0,N=1;n<${#NicIndexS[@]};n++,N++))
			do
				if [ ${bit2Bin: -N:1} == 1 ] ; then
					let SetBlinkLEDs++
					BlinkLEDBootutil64e "${NicIndexS[n]}"
					# S258E Blink 千兆orange色
					StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd1000MbpsColor}")
				else
					# 正常的顏色不運行設置程式
					StandardAnswer=$(printf "%s\n" "${StandardAnswer} ${ActiveLEDColor} ${Spd10000MbpsColor}")
				fi
			done
			
			let OrangeAmberAmount=$(printf "%s\n" "${StandardAnswer}" | grep -o "[0-9]" | grep -iwc "1")+${AlwaysLightUpColor1}
			let GreenAmount=$(printf "%s\n" "${StandardAnswer}" | grep -o "[0-9]" | grep -iwc "2")+${AlwaysLightUpColor2}
			printf "%s\n" "Set the network card's speed, please wait ..."
			sleep 2
			for((s=1;s>0;s++))
			do
				ls Blink-*.log 2>/dev/null | grep -iwc "Blink" | grep -iwq "${SetBlinkLEDs}"
				if [ $? == 0 ] || [ $(ps ax | grep -iwc "Blink") -le 1 ] ; then
					for((t=1;t<=$((SetBlinkLEDs*4));t++))
					do 
						echo -n ">"
						sleep 1
					done
					echo
					break
				else
					printf "%s" ">"
					if [ $((s%70)) == 0 ] ; then
						printf "\r%s\r" "                                                                       "
					fi
					sleep 1
				fi
			done
			echo
			
			for((try=1;try<3;try++))
			do
				Error=0
				BeepRemind 0
				numlockx on 2>/dev/null
				[ ${Debug} == 'enable' ] && echo "The number of greep and orange/amber/yellow LEDs are ${GreenAmount} PCs and ${OrangeAmberAmount} PCs"
				
				if [ "${GraphicalMode}" == 0 ] ; then
					for((q=0;q<${#Question[@]};q++))
					do
						if [ ${Question[q]} == 2 ] ; then
							tput sc;tput rc;tput ed;
							echo -en "LED顏色發生了變化,\e[1;31m顏色變化的時候\e[0m指定位置上亮的\e[1;32m青/綠/翡翠色燈\e[0m的總數量是: "
							read -n ${#GreenAmount} -t 15 GreenAns
							echo -e "\b${GreenAns}"
						else
							tput sc;tput rc;tput ed;
							echo -en "LED顏色發生了變化,\e[1;31m顏色變化的時候\e[0m指定位置上亮的\e[1;33m橙/黃/琥珀色燈\e[0m的總數量是: "
							read -n ${#OrangeAmberAmount} -t 15 OrangeAmberAns
							echo -e "\b${OrangeAmberAns}"
						fi
					done
				else
					for((q=0;q<${#Question[@]};q++))
					do
						if [ ${Question[q]} == 2 ] ; then
							tput sc;tput rc;tput ed;
							echo -en "When the color changes, the number of \e[1;32mgreen\e[0m LEDs is: "
							read -n ${#GreenAmount} -t 15 GreenAns
							echo -e "\b${GreenAns}"
						else
							tput sc;tput rc;tput ed;
							echo -en "When the color changes, the number of \e[1;33morange/amber/yellow\e[0m LEDs is: "
							read -n ${#OrangeAmberAmount} -t 15 OrangeAmberAns
							echo -e "\b${OrangeAmberAns}"
						fi
					done
				fi
				echo
				
				if [ "${OrangeAmberAmount}"x == "${OrangeAmberAns}"x ] && [ "${GreenAmount}"x == "${GreenAns}"x ] ; then
					Process 0 "The number of orange/amber/yellow and green LEDs are ${OrangeAmberAmount} PCs and ${GreenAmount} PCs "
					printf "%s\n" "The loaction of LEDs light on or off is: ${bit2Bin: -${#NicIndexS[@]}})"
					rm -rf Blink-* 2>/dev/null
					Error=0
					printf "%s\n" "Please wait a moment ..." && wait
					continue 2
				else
					Process 1 "Error number of orange/amber/yellow and green LEDs"
					let Error++
					continue
				fi
			done

			wait
			if [ ${Error} != 0 ] || [ ${try} -ge 3 ] ; then
				let ErrorFlag++
				break 2
			fi
		done
	done
	if [ ${Error} != 0 ] ; then
		let ErrorFlag++
	fi	
}

main()
{
	GetNetcardInterface
	GetDisplayMode
	
	case ${SpeedControlTool} in
		'ethtool')ControlledByEthtool;;
		'celo64e')ControlledByCelo64e;;
		'bootutil64e')ControlledByBootutil64e;;
	esac
	
	echo
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "Network card LEDs test "
	else
		echoFail "Network card LEDs test "
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
# 1/2/3/4 可以理解為10的指數
declare RandomSpeedCode_1G=(123 132 213 231 321 312)
declare RandomSpeedCode_10G=(34 43)
declare Debug='disable'
declare GraphicalMode='0'
declare XmlConfigFile SpeedControlTool ApVersion AlwaysLightUp AlwaysLightUpColor1 AlwaysLightUpColor2
declare LanMac FirstIPaddress SubnetMask Autoneg Duplex ActiveLEDColor Spd10MbpsColor Spd100MbpsColor Spd1000MbpsColor Spd10000MbpsColor Question
declare -a NetCards=()
declare -a NicIndexS=()
declare -a OrderOfLighting=()
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
		d)
			Debug='enable'
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
			printf "%-s\n" "SerialTest,NETLEDsTest"
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
