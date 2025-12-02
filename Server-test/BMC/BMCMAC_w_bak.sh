#!/bin/bash
#FileName : BMCMAC_w.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.3"
	local CreatedDate="2018-06-25"
	local UpdatedDate="2020-12-25"
	local Description="Flash the BMC MAC address"
	
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
	printf "%16s%-s\n" "" " 2020-11-19 ,modify the flash command "
	printf "%16s%-s\n" "" " 2020-12-25 ,add the 2nd access permission(not apply)"
	printf "%16s%-s\n" "" " 2023-2-14 ,add BMC channel 7 "
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
	local ErrorCode=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet ipmitool)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			ipmitool)printf "%10s%s\n" "" "ipmitool-1.8.18-7.el7.x86_64.rpm";;
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
`basename $0` [-x[p] lConfig.xml] [-DV]
	eg.: `basename $0` -[p]x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-p : Enter the password to compel flash eeprom again
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)	

	return code:
		0 : Flash BMC MAC address pass
		1 : Flash BMC MAC address fail			
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<BMC>
		<TestCase>				
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NULL</ErrorCode>	
			<FlashMacAddr>
				<!-- BMCMAC_w.sh/BMCMAC_c.sh -->
				<!-- enable: 必要的時候可以二次燒錄; disable: 禁止二次燒錄 -->
				<DoubleFlash>enable</DoubleFlash>
				<Password>abcf314e470e139bf3c06c859761d560</Password>
				<!--  Channel # | Path of BMC Mac address-->
				<BmcMacAddr>
					<Channel>1</Channel>
					<MacFile>/TestAP/Scan/bmcmac1.txt</MacFile>
				</BmcMacAddr>

				<BmcMacAddr>
					<Channel>8</Channel>
					<MacFile>/TestAP/Scan/bmcmac2.txt</MacFile>
				</BmcMacAddr>
				
				<!--兩個BMC燒錄的間隔時間（單位：秒） -->
				<!--While the BMC channel amount is great than 2, Time Interval is needed. Unit: seconds,default: 100s -->
				<TimeInterval>120</TimeInterval>
			</FlashMacAddr>
		</TestCase>
	</BMC>
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
	DoubleFlash=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/DoubleFlash" -n "${XmlConfigFile}" 2>/dev/null)
	Password=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/Password" -n "${XmlConfigFile}" 2>/dev/null)
	TimeInterval=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/TimeInterval" -n "${XmlConfigFile}" 2>/dev/null)
	ChannelIndex=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/BmcMacAddr/Channel" -n "${XmlConfigFile}" 2>/dev/null))
	BMClocation=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/BmcMacAddr/Location" -n "${XmlConfigFile}" 2>/dev/null))
	BmcMacAddr=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/BmcMacAddr/MacFile" -n "${XmlConfigFile}" 2>/dev/null))

	if [ ${#DoubleFlash} == 0 ] ; then
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
		printf "\r\e[1;33mAfter %003d seconds will auto continue to test ...\e[0m" "${p}"
		sleep 1
	done
	echo 
}

FlashBmcMacAddress()
{
	local TargetIndex=$1
	local TargetBmcMac=$(cat -v $2 | tr [a-z] [A-Z] | head -n1 | grep -E '^[0-9A-F]{12}+$' )
	if [ ${#TargetBmcMac} == 0 ] ; then
		Process 1 "Invalid BMC mac address: `cat $2| head -n 1`"
		let ErrorFlag++
		return 1
	fi

	# Wite BMC MAC2, wait TimeInterval seconds
	if [ ${TargetIndex} != 1 ] ; then
		StartTime=$(cat -v BMC1_StartTime.log 2>/dev/null | awk -F'.' '{print $1}' | tr -d ' ')
		StartTime=${StartTime:-'110008165'}
		NowTime=$( date +%s | awk -F'.' '{print $1}' | tr -d ' ')
		EndTime=$(echo "obase=10; ibase=10; ${StartTime}+${TimeInterval}" | bc) 
		Gap=$(echo "obase=10; ibase=10; ${EndTime}-${NowTime}" | bc) 
		Gap=`echo "${Gap#-}"`

		if [[ ${NowTime}<${EndTime} ]] ; then
			ShowMsg --b "Please do not interrupt this processing ..."  
			ShowMsg --e "Wait for writing BMC Channel ${TargetIndex} address ... " 
			Wait4nSeconds $Gap
		fi
	fi

	# Type A: Get BMC PORT IP
	KeyString="MAC Address"
	CurBmcMacAddr=$(ipmitool lan print ${TargetIndex} | grep "${KeyString}" | head -n1 | cut -c 27-43 | tr -d ': ' | tr [a-z] [A-Z] )

	# Type B: Get BMC PORT IP
	#CurBmcMacAddr=$(ipmitool raw 0x0c 0x02 0x0${TargetIndex} 0x05 0x00 0x00 | cut -c 5-21 | tr -d ': ' | tr [a-z] [A-Z] )

	SoleLetterAmount=$(echo ${CurBmcMacAddr} | grep -o '[0-9A-F]' | sort -u | wc -l)

	if [ $SoleLetterAmount -ge 6 ] && [ $DoubleFlash == "disable" ] && [ $CompelMode == "disable" ] ; then
		echo -e "\e[1;33m ${CurBmcMacAddr} is not default mac, skip reflash BMC${J} as: ${TargetBmcMac}\e[0m"
		echo -e "\e[1;33m---------------------------------------------------------------------\e[0m"
		echo ${CurBmcMacAddr} | grep -iwq $TargetBmcMac
		if [ $? == 0 ] ; then
			# Does not need to wait.
			echo '110008165' > BMC1_StartTime.log
			return 0
		else
			return 1
		fi
	fi

	# Split the MAC Address,e.g.:D8CB8AA7BCE6 to d8:cb:8a:a7:bc:e6
	for ((X=1,Y=1;X<=6,Y<=11;X++,Y+=2 ))
	do
		bmcmac[$X]=$(echo "${TargetBmcMac}" | tr [A-F] [a-f] | cut -c $Y-$(($Y+1)))
	done
	OriginalBmcMacAddr="${bmcmac[1]}:${bmcmac[2]}:${bmcmac[3]}:${bmcmac[4]}:${bmcmac[5]}:${bmcmac[6]}" 

	# Write BMC MAC Address
	case $TargetIndex in
		1)
			echo ipmitool raw 0x0c 0x01 0x01 0xc2  
			echo ipmitool raw 0x0c 0x01 0x01 0x05 0x${bmcmac[1]} 0x${bmcmac[2]} 0x${bmcmac[3]} 0x${bmcmac[4]} 0x${bmcmac[5]} 0x${bmcmac[6]} 
			
			ipmitool raw 0x0c 0x01 0x01 0xc2  >/dev/null 2>&1
			ipmitool raw 0x0c 0x01 0x01 0x05 0x${bmcmac[1]} 0x${bmcmac[2]} 0x${bmcmac[3]} 0x${bmcmac[4]} 0x${bmcmac[5]} 0x${bmcmac[6]} >/dev/null 2>&1
		;;

		7)
			echo ipmitool raw 0x0c 0x01 0x07 0xc2  
			echo ipmitool raw 0x0c 0x01 0x07 0x05 0x${bmcmac[1]} 0x${bmcmac[2]} 0x${bmcmac[3]} 0x${bmcmac[4]} 0x${bmcmac[5]} 0x${bmcmac[6]}
			ipmitool raw 0x0c 0x01 0x07 0xc2 >/dev/null 2>&1
			ipmitool raw 0x0c 0x01 0x07 0x05 0x${bmcmac[1]} 0x${bmcmac[2]} 0x${bmcmac[3]} 0x${bmcmac[4]} 0x${bmcmac[5]} 0x${bmcmac[6]} >/dev/null 2>&1
		;;

		8)
			echo ipmitool raw 0x0c 0x01 0x08 0xc2  
			echo ipmitool raw 0x0c 0x01 0x08 0x05 0x${bmcmac[1]} 0x${bmcmac[2]} 0x${bmcmac[3]} 0x${bmcmac[4]} 0x${bmcmac[5]} 0x${bmcmac[6]}
			ipmitool raw 0x0c 0x01 0x08 0xc2 >/dev/null 2>&1
			ipmitool raw 0x0c 0x01 0x08 0x05 0x${bmcmac[1]} 0x${bmcmac[2]} 0x${bmcmac[3]} 0x${bmcmac[4]} 0x${bmcmac[5]} 0x${bmcmac[6]} >/dev/null 2>&1
		;;

		*)
			Process 1 "Invalid BMC index: $TargetIndex"
			let ErrorFlag++
			return 1
		;;
		esac
	if [ $? == 0 ] ; then
		if [ ${ChannelIndex[$j]} == 1 ] ; then
			rm -rf BMC1_StartTime.log 2>/dev/null
			date +%s > BMC1_StartTime.log
			sync;sync;sync
		elif [ ${ChannelIndex[$j]} == 7 ];then
			echo "BMC CH7 MAC Flashed"
			rm -rf BMC1_StartTime.log 2>/dev/null
			date +%s > BMC1_StartTime.log
			sync;sync;sync
		else
			rm -rf BMC1_StartTime.log 2>/dev/null
		fi
	else
		return 1
	fi

	return 0
}
main()
{
	if [ ${#ChannelIndex[@]} != ${#BmcMacAddr[@]} ] ; then
		echo "The BMC index number is not eque to BMC mac address file number"
		Usage 
	fi

	# Load IPMI Driver,or: modprobe ipmi_si
	modprobe ipmi_devintf
	if [ "$?" != "0" ]; then
		Process 1 "Load IPMI Driver ..."
		exit 1
	fi
		
	for ((j=0;j<${#ChannelIndex[@]};j++))
	do
		#if [ ${ChannelIndex[$j]} == 1 ] ; then
		#	J=1
		#else
		#	J=2
		#fi

		# Input correct Password,flash Mac address again!
		if [ "$CompelMode"x == "enable"x ] && [ $DoubleFlash == "disable" ] ; then
			while :
			do
				echo -e "\033[0;30;43m--Input the correct password, flash BMC MAC again!--\033[0m"
				read -p "Please input password: " -s psw
				pswmd5=$(echo -n $psw  | md5sum | cut -c 1-32)
				echo ''
				if [ $(echo "${pswmd5}"x | grep -iwc "${Password}"x ) == 1 ]; then
					CompelMode='enable'
					DoubleFlash='enable'
					break
				else				
					echo -e "\033[0;30;41m--Incorrect password.Please try again!--\033[0m"
				fi
			done
		fi
		
		# check the the BMC MAC address file is exist
		if [ ! -f  ${BmcMacAddr[$j]} ] ; then	
			Process 1 "No such file: ${BmcMacAddr[$j]} "
			let ErrorFlag++
			continue
		fi

		FlashBmcMacAddress "${ChannelIndex[$j]}" "${BmcMacAddr[$j]}"
		#Process $? "Flash BMC${J} MAC address: `cat ${BmcMacAddr[$j]}`" || let ErrorFlag++
		Process $? "Flash BMC ${ChannelIndex[$j]} ${BMClocation[$j]} MAC address: `cat ${BmcMacAddr[$j]}`" || let ErrorFlag++
	done
	echo

	if [ ${ErrorFlag} == 0 ]; then
		echoPass "Flash BMC MAC address"
	else
		echoFail "Flash BMC MAC address"
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
declare CompelMode='disable'
declare DoubleFlash='disable'
declare Password
declare XmlConfigFile BmcMacConfigFile ChannelIndex BmcMacAddr TimeInterval ApVersion
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :P:VDpx: argv
do
	 case ${argv} in
	 	p)
			CompelMode="enable"
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
			printf "%-s\n" "SerialTest,WriteBmcMAC"
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
