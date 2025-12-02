#!/bin/bash
#FileName : usbDevices.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-09-21"
	local UpdatedDate="2020-09-24"
	local Description="偵測USB設備是否插在指定位置或符合HW SPEC"
	
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
	printf "%16s%-s\n" "" "2020-08-24,功能測試中可用於檢測指定位置是否插了USB設備,如鍵盤/鼠標/掃碼槍等"
	printf "%16s%-s\n" "" "2020-09-24,設備有無SN自定義"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet usb-devices dmesg)
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
	   0 : Detect USB device(s) and verify pass
	   1 : Detect USB device(s) or verify fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<USB>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXUS2|USB test fail</ErrorCode>
			<!--1.0: 1.5Mbps(low-speed)/1.1: 12Mbps(full-speed) / 2.x: 480Mbps(high-speed)/3.x: 5000Mbps(SuperSpeed)-->
			<Port>
				<Location>M2_B2-key</Location>
				<PortID>1-1</PortID>
				<UsbSpd>high-speed</UsbSpd>
				<!--none：設備沒有SN; yes：設備帶有SN-->
				<DeviceSN>none</DeviceSN>
			</Port>

			<Port>
				<Location>M2_B2-key</Location>
				<PortID>1-2</PortID>
				<UsbSpd>high-speed</UsbSpd>
				<!--none：設備沒有SN; yes：設備帶有SN-->
				<DeviceSN>none</DeviceSN>
			</Port>
		</TestCase>
	</USB>
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
	local AllUsbSpd=($(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/Port/UsbSpd" -n "${XmlConfigFile}" 2>/dev/null | tr -d '[[:punct:]]' | tr '[A-Z]' '[a-z]'))
	PortID=($(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/Port/PortID" -n "${XmlConfigFile}" 2>/dev/null))
	
	if [ ${#PortID[@]} == 0 ] ; then
		Process 1 "Error XML config. No USB device need to test ..."
		exit 1
	fi
	
	for((p=0;p<${#PortID[@]};p++))
	do
		echo "${PortID[p]}" | grep -iwEq "[0-9]{1,3}-[0-9]{1,3}" 
		if [ $? != 0 ] ;then
			Process 1 "Invalid port ID: ${PortID[p]}"
			let ErrorFlag++		
		fi
	done
	
	echo "${PortID[@]}" | tr ' ' '\n' | sort -u | grep -iwEc "[A-Z0-9]" | grep -iwq "${#PortID[@]}"
	if [ $? != 0 ] ;then
		Process 1 "Duplicate setting found in PortID ..."
		printf "\e[1;31m%10s%s\e[0m\n" "" "`echo ${PortID[@]} | tr ' ' '\n' |  sort -s | uniq -c | sed "s/      //g" |grep -iwv "^1"`"
		let ErrorFlag++	
	fi
	
	for((v=0;v<${#AllUsbSpd[@]};v++))
	do
		echo ${AllUsbSpd[v]} | grep -iwEq "(lowspeed|fullspeed|highspeed|superspeed)"
		if [ $? != 0 ] ;then
			Process 1 "Invalid speed: ${AllUsbSpd[v]}"
			let ErrorFlag++
		fi	
	done
	
	
	if [ ${ErrorFlag} != 0 ] ;then
		exit 1
	fi
	return 0			
}

DmesgInfo()
{
	local UsbPortID=$1
	
	local LastDetect=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw "New USB device found" | tail -n1 )
	dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -F -A20 "${LastDetect}" | grep -iwq "USB disconnect" && return 1
	DmesgUsbSpd=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw -B20 -A20 "New USB device found" | grep -i "speed" | tr ' ' '\n' | grep -i "speed" | tr -d '[[:punct:]]' | tr '[A-Z]' '[a-z]' | tail -n1)
	idVendor=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw -A20 "New USB device found" | grep -iw "idVendor" | tr ' ' '\n' | grep -iw "idVendor" | awk -F'=' '{print $NF}' | tail -n1 | tr -d "[[:punct:]]")
	idProduct=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw -A20 "New USB device found" | grep -iw "idProduct" | tr ' ' '\n' | grep -iw "idProduct" | awk -F'=' '{print $NF}' | tail -n1 | tr -d "[[:punct:]]")
	DmesgProduct=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw -A20 "New USB device found" | grep -iw "Product:" | awk -F'Product: ' '{print $NF}' | tail -n1)
	DmesgManufacturer=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw -A20 "New USB device found" | grep -iw "Manufacturer:" | awk -F'Manufacturer: ' '{print $NF}' | tail -n1)
	DmesgSerialNumber=$(dmesg | grep -E "usb [1-9]{1,3}-" | grep -iw "${UsbPortID}:" | grep -iw -A20 "New USB device found" | grep -iw "SerialNumber:" | awk -F'SerialNumber: ' '{print $NF}' | tail -n1)
	return 0
}

CovertSpeed()
{
	local Speed=$1
	echo ${Speed} | grep -iEq "[A-Z]"
	if [ $? == 0 ]; then
		printf "%s\n" "${Speed}"
		return 0
	fi
	
	case ${Speed} in
	1.5)printf "%s\n" "lowspeed";;
	12)printf "%s\n" "fullspeed";;
	480)printf "%s\n" "highspeed";;
	5000)printf "%s\n" "superspeed";;
	*)printf "%s\n" "superspeed+";;
	esac	
	return 0
}

main()
{
	local BlankLineID=($(usb-devices | grep -n "^$" | tr -d ":" | tr "\n" " " )) # Get the blank line number
	BlankLineID=($(echo "${BlankLineID[@]} 999"))
	for ((x=0,y=1;y<${#BlankLineID[@]};x++,y++))
	do
		rm -rf .temp/${BaseName}-${y}.log 2>/dev/null
		mkdir .temp >/dev/null 2>&1
		usb-devices | sed -n "${BlankLineID[$x]},${BlankLineID[$y]}"p >.temp/${BaseName}-${y}.log
		sync;sync;sync
	done
	
	for((p=0;p<${#PortID[@]};p++))
	do
		local FindLog=""
		local SubErrorFlag=0
		Location=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/Port[PortID=\"${PortID[p]}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null)
		DeviceSN=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/Port[PortID=\"${PortID[p]}\"]/DeviceSN" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
		UsbSpd=$(xmlstarlet sel -t -v "//USB/TestCase[ProgramName=\"${BaseName}\"]/Port[PortID=\"${PortID[p]}\"]/UsbSpd" -n "${XmlConfigFile}" 2>/dev/null | tr -d '[[:punct:]]' | tr '[A-Z]' '[a-z]')
		local ShowUsbSpd=$(echo ${UsbSpd} | sed "s/speed/\-speed/g")
		
		DmesgInfo "${PortID[p]}"
		if [ $? != 0 ] ; then
			Process 1 "The USB device probably removed from \"${Location}\""
			let ErrorFlag++
			continue
		fi
		
		for log in `ls ./.temp/${BaseName}-*.log`
		do
			grep -iwq "keyboard\|mouse" ${log} 
			if [ $? == 0 ] || [ "${DeviceSN:none}"x == 'none'x ]  ; then
				grep -iwq "Vendor=${idVendor} ProdID=${idProduct}" ${log} 
			else
				grep -iw -A5 "Vendor=${idVendor} ProdID=${idProduct}" ${log} | grep -iwq "SerialNumber=${DmesgSerialNumber}"
			fi
			if [ $? == 0 ] ; then
				FindLog=${log}
				break
			fi
		done
		
		
		if [ ${#FindLog} != 0 ] ; then
			local UsbDevicesSpeed=$(grep -iw "Spd" ${FindLog} | tr ' ' '\n' | grep -iw "Spd" | awk -F'=' '{print $NF}')
			local UsbSpeed=$(CovertSpeed ${UsbDevicesSpeed})
			local ShowUsbSpeed=$(echo ${UsbSpeed} | sed "s/speed/\-speed/g")
			local UsbDevicesManufacturer=$(grep -iw "Manufacturer" ${FindLog} | awk -F'=' '{print $NF}')
			local UsbDevicesProduct=$(grep -iw "Product" ${FindLog} | awk -F'=' '{print $NF}')
			local UsbDevicesSerialNumber=$(grep -iw "SerialNumber" ${FindLog} |  awk -F'=' '{print $NF}')
			echo "**********************************************************************"
			printf "%-14s%-2s%-s\n" "Location" ": " "${Location}"
			printf "%-14s%-2s%-s\n" "Port ID" ": " "${PortID[p]}"
			printf "%-14s%-2s%-s\n" "Vendor ID" ": " "${idVendor}"
			printf "%-14s%-2s%-s\n" "Product ID" ": " "${idProduct}"
			if [ ${#UsbSpd} != 0 ] ;then
				if [ $(echo ${UsbSpeed} | grep -iwc "${UsbSpd}") == 1 ] && [ $(echo ${UsbSpeed} | grep -iwc "${DmesgUsbSpd}") == 1 ] ; then
					printf "%-14s%-2s%-s\n" "Link Speed" ": " "${UsbDevicesSpeed}Mbps (${ShowUsbSpeed})"
				else
					printf "%-14s%-2s%-s\e[1;31m%-s\e[0m%-s\n" "Link Speed" ": " "${UsbDevicesSpeed}Mbps (Actual: " "${DmesgUsbSpd}" ", Expect: ${ShowUsbSpd})"
					let SubErrorFlag++
				fi
			else
				printf "%-14s%-2s%-s\n" "Link Speed" ": " "${UsbDevicesSpeed}Mbps (${ShowUsbSpeed})"
			fi
			printf "%-14s%-2s%-s\n" "Manufacturer" ": " "${UsbDevicesManufacturer}"
			printf "%-14s%-2s%-s\n" "Product" ": " "${UsbDevicesProduct}"
			[ ${#UsbDevicesSerialNumber} != 0 ] && printf "%-14s%-2s%-s\n" "Serial Number" ": " "${UsbDevicesSerialNumber}"
			echo "**********************************************************************"
			Process ${SubErrorFlag} "Verify the USB device on \"${Location}\" ..." || let ErrorFlag++
		else
			Process 1 "The USB device probably removed from \"${Location}\""
			let ErrorFlag++
		fi
		rm -rf ${FindLog} .log 2>/dev/null
	done
	
	rm -rf ./.temp 2>/dev/null
	if [ ${ErrorFlag} == 0 ]; then
		echoPass "USB device(s) detection check"
	else
		echoFail "USB device(s) detection check"
		let ErrorFlag++
	fi
	[ ${ErrorFlag} != 0 ] && exit 1
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile PortID
declare DmesgUsbSpd idVendor idProduct DmesgProduct DmesgManufacturer DmesgSerialNumber
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
			printf "%-s\n" "SerialTest,CheckUSBDevices"
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
