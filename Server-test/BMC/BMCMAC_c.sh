#!/bin/bash
#FileName : BMCMAC_c.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-06-25"
	local UpdatedDate="2019-07-03"
	local Description="Compare the BMC MAC address"
	
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
		0 : Compare BMC MAC address pass
		1 : Compare BMC MAC address fail			
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
			<ErrorCode></ErrorCode>	
			<FlashMacAddr>
				<!-- BMCMAC_w.sh/BMCMAC_c.sh -->		
				<!--  Channel # | Path of BMC Mac address-->
				<BmcMacAddr>
					<Channel>1</Channel>
					<MacFile>/TestAP/Scan/bmcmac1.txt</MacFile>
					<Location>MLAN1</Location>
				</BmcMacAddr>

				<BmcMacAddr>
					<Channel>8</Channel>
					<MacFile>/TestAP/Scan/bmcmac2.txt</MacFile>
					<Location>NCSI</Location>
				</BmcMacAddr>
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
	ChannelIndex=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/BmcMacAddr/Channel" -n "${XmlConfigFile}" 2>/dev/null))
	BMClocation=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/BmcMacAddr/Location" -n "${XmlConfigFile}" 2>/dev/null))
	BmcMacAddr=($(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/BmcMacAddr/MacFile" -n "${XmlConfigFile}" 2>/dev/null))
	SavePath=$(xmlstarlet sel -t -v "//BMC/TestCase[ProgramName=\"${BaseName}\"]/FlashMacAddr/SavePath" -n "${XmlConfigFile}" 2>/dev/null)
	SavePath=${SavePath:-"/TestAP/PPID"}

	if [ ${#ChannelIndex} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

CompareBmcMacAddress()
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

		# Type A: Get BMC PORT IP
		CurBmcMacAddr=$(ipmitool lan print ${ChannelIndex[$j]} | grep 'MAC Address' | head -n1 | cut -c 27-43 | tr -d ': ' | tr [a-z] [A-Z] )
		
		# Type B: Get BMC PORT IP
		#CurBmcMacAddr=$(ipmitool raw 0x0c 0x02 0x0${ChannelIndex[$j]} 0x05 0x00 0x00 | cut -c 5-21 | tr -d ': ' | tr [a-z] [A-Z] )
		
		# Compare the the BMC MAC address
		if [ -f ${BmcMacAddr[$j]} ] ; then
			cat -v ${BmcMacAddr[$j]} | grep -iw ${CurBmcMacAddr} | grep -Eq '^[0-9A-Fa-f]{12}+$'
		else
			Process 1 "No such file: ${BmcMacAddr[$j]} "
			let ErrorFlag++
			continue
		fi
			
		if [ $? == 0 ] ; then
			Process 0 "Check BMC Channel ${ChannelIndex[$j]} ${BMClocation[$j]} MAC address( ${CurBmcMacAddr} )"
			#cat ${BmcMacAddr[$j]} | tr '[a-f]' '[A-F]' > ${SavePath}/BMCMAC${J}.TXT 2>/dev/null
			cp -rf ${BmcMacAddr[$j]} ${SavePath}/ 2>/dev/null
			sync;sync;sync
			
		else
			Process 1 "Check BMC Channel ${ChannelIndex[$j]} ${BMClocation[$j]} MAC address fail Current BMC Channel ${ChannelIndex[$j]} ${BMClocation[$j]} MAC address is:  $CurBmcMacAddr"
			printf "%-10s%-60s\n" ""  "The BMC Channel ${ChannelIndex[$j]} ${BMClocation[$j]} MAC address should be: `cat -v ${BmcMacAddr[$j]}| tr [a-f] [A-F]`"
			let ErrorFlag++	
		fi
		
	done

	for ((j=0;j<${#ChannelIndex[@]};j++))
	do

		SaveBmcMac=$(echo ${BmcMacAddr[$j]} | awk -F "/" '{print $NF}')	
		cat -v ${SavePath}/${SaveBmcMac} 2>/dev/null | head -n 1 | grep -Eq '^[0-9A-Fa-f]{12}+$'
		if [ $? != 0 ] ; then
			Process 1 "Invalid BMC MAC address file: ${SavePath}/${SaveBmcMac}"
			let ErrorFlag++
		fi
	done
	
	if [ ${ErrorFlag} == 0 ]; then
		echoPass "Compare BMC MAC address"
	else
		echoFail "Compare BMC MAC address"
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
declare XmlConfigFile BmcMacConfigFile ChannelIndex BmcMacAddr ApVersion
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
			printf "%-s\n" "SerialTest,CheckBmcMAC"
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
	
CompareBmcMacAddress
exit 0
