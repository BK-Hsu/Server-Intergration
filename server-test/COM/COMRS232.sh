#!/bin/bash
#FileName : COMRS232.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.3.0"
	local CreatedDate="2018-06-26"
	local UpdatedDate="2023-07-25"
	local Description="COM port RS-232 functional test"
	
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
	printf "%16s%-s\n" "" "2020-08-12,Fixture TL20 card,優化代碼, 免中間文件"
	printf "%16s%-s\n" "" "2023-03-23,新的COM 测试工具，支持Legacy/TL20 模式"
	printf "%16s%-s\n" "" "2023-07-25,lCOM.out update to v1.00.06, support IO mode and API mode"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet lCOM.out)
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
`basename $0` [-x lConfig.xml] [ -DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : All COM ports RS232 function test pass
		1 : Some COM ports RS232 function test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
		

	怎麼在OS下增加更多的COM設備:
	# Add "8250.nr_uarts=6" in config file: /etc/grub/grub.conf  ,Linux6.x
	# or add "8250.nr_uarts=6" in config file: /etc/grub/grub2-efi.cfg

		set root='hd1,gpt2'
		if [ x$feature_platform_search_hint = xy ]; then
		  search --no-floppy --fs-uuid --set=root --hint-bios=hd1,gpt2 --hint-efi=hd1,gpt2 --hint-baremetal=ahci1,gpt2  8b03ba85-52eb-4d2b-a0a1-1daa13f4a9de
		else
		  search --no-floppy --fs-uuid --set=root 8b03ba85-52eb-4d2b-a0a1-1daa13f4a9de
		fi
		linuxefi /vmlinuz-3.10.0-514.el7.x86_64 root=/dev/mapper/cl-root ro crashkernel=auto 8250.nr_uarts=6 rd.lvm.lv=cl/root rd.lvm.lv=cl/swap rhgb quiet LANG=en_US.UTF-8
		initrdefi /initramfs-3.10.0-514.el7.x86_64.img
		
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<COM>
	  	<TestCase>
		<ProgramName>${BaseName}</ProgramName>
		<ErrorCode>TXC11|COM function fail</ErrorCode>
		<TestMode>IO</TestMode>
		<TestCard>Legacy</TestCard>
		<lCOMver>V1.00.06</lCOMver>
		<TestItems>
		<!-- 1: 測試該信號, other: 不測試該信號 -->
		<DCD>1</DCD>
		<RI>1</RI>
		<DSR>1</DSR>
		<CTS>1</CTS>
		</TestItems>
		<Port>COM1|/dev/ttyS0|0x3F8</Port>
		<Port>COM1|/dev/ttyS1|0x2F8</Port>
		</TestCase>
	</COM>
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

Dumpini()
{
	cat <<-Sample | tee lCOM.ini
	lCOM Version = V1.00.06

	;The number of com ports to test, up to 16
	COMNumber=2

	;Test card parameters, please enter 'TL20','TL644', 'Legacy', 'LegacyRS422', 'TXRX'
	;TXRX parameters will not test internal and external loops, only test TX/RX transmission.
	Test Card=Legacy

	;Test Mode parameters, please enter 'IO', 'API'
	;The 'IO' parameter is to use the IO port for the underlying test
	;The 'API' parameter is to use the Linux API test. Can only test external circuits
	Test Mode=IO

	;Select pins not to test. 1=Test, 0=No Test
	DCD TEST=1
	RI  TEST=1
	DSR TEST=1
	CTS TEST=1

	;Choose whether to test TX/RX, the authority of this parameter is lower than that of TestCard
	TXRXTest=1

	;Please enter the COM port name and BASE, these information can be enter command
	;in terminel: dmesg | grep tty
	[COM1]
	NAME=/dev/ttyS0
	BASE=3F8
	[COM2]
	NAME=/dev/ttyS1
	BASE=2F8
	Sample
	sync;sync;sync
	if [! -f "./lCOM.ini" ] ;then
		echo
		echo -e "\033[1;31m no found any ini: ./lCOM.ini\e[0m"
		sleep 2
		exit 1
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
	ComPorts=($(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $1}'))
	ComDevices=($(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $2}'))
	TestCard=$(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/TestCard" -n "${XmlConfigFile}" 2>/dev/null)
	TestMode=$(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/TestMode" -n "${XmlConfigFile}" 2>/dev/null)
	#Toolver=$(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/lCOMver" -n "${XmlConfigFile}" 2>/dev/null)
	#if [ "${Toolver}"x == ""x ] ; then
	#	Process 1 "xml config is wrong, please check Toolver"
	#	exit 3
	#fi
	#if [ -f lCOM.ini ];then
	#	rm -f lCOM.ini
	#fi
	#if [ -f lCOM.out ];then
	#	./lCOM.out 2>&1 >/dev/null
	#	stand_version=$(cat lCOM.ini |grep "Version" |awk -F'=' '{print $2}' |tr -d ' ')
	#else
	#	Process 1 "COM Test Tool lCOM.out not exist, please check"
	#	exit 3
	#fi
	#if [ "${Toolver}"x != "${stand_version}"x ] ; then
	#	Process 1 "xml config is wrong, please check Toolver"
	#	exit 3
	#fi
	if [ "${TestCard}"x == ""x ] ; then
		Process 1 "xml config is wrong, please check TestCard"
		exit 3
	fi
	
	if [ "${TestMode}"x == ""x ] ; then
		Process 1 "xml config is wrong, please check TestMode"
		exit 3
	fi
	echo ${Toolver}
	#echo "lCOM Version = ${Toolver}" > lCOM.ini
	#echo "COMNumber=${#ComDevices[@]}" >> lCOM.ini
	
	
	#echo "Test Card=${TestCard}" >> lCOM.ini
	#echo "Test Mode=${TestMode}" >> lCOM.ini

	cat <<-EOF>lCOM.ini
	lCOM Version = V1.00.06

	;The number of com ports to test, up to 16
	COMNumber=${#ComDevices[@]}

	;Test card parameters, please enter 'TL20','TL644', 'Legacy', 'LegacyRS422', 'TXRX'
	;TXRX parameters will not test internal and external loops, only test TX/RX transmission.
	Test Card=${TestCard}

	;Test Mode parameters, please enter 'IO', 'API'
	;The 'IO' parameter is to use the IO port for the underlying test
	;The 'API' parameter is to use the Linux API test. Can only test external circuits
	Test Mode=${TestMode}

	;Select pins not to test. 1=Test, 0=No Test
	EOF



	for((c=0;c<${#ComPorts[@]};c++))
	do
		ComPortsDevices[$c]=$(echo "${ComPorts[c]}|${ComDevices[c]}")	
	done
	
	local ComPortsDevicesCnt=$(echo "${ComPortsDevices[@]}" | tr " " "\n" | sort -u | wc -l )
	if [ ${ComPortsDevicesCnt} != ${#ComPorts[@]} ] ; then
		Process 1 "Find a repeated Settings in the configuration file."
		exit 3
	fi
	# Get the information from the config file(*.xml)
	for((i=0;i<${#ItemList[@]};i++))
	do
		local item=$(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/TestItems/${ItemList[i]}" -n "${XmlConfigFile}" 2>/dev/null)
		if [ "${item}"x != "1x" ] ; then
			item=0
			SkipItems=$(printf "%s\n" "${SkipItems} ${ItemList[i]}")
		fi
		TestItems=$(printf "%s\n" "${TestItems}${item}")
		#sed -i 's/^${ItemList[i]}=*/${ItemList[i]}=${item}/g' lCOM.ini
		echo "${ItemList[i]} TEST=${item}" >> lCOM.ini
	done
	
	echo "${TestItems}" | grep -oq "1"
	if [ $? != 0 ] || [ ${#TestItems} != 4 ] ; then
		Process 1 "Error test item(s) seted in xml config files."
		exit 3
	fi
	
	#ComPorts=($(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $1}'))
	
	#sed -i 's/Test Card=*/Test Card=${TestMode}/g' lCOM.ini
	echo "" >> lCOM.ini
	echo ";Choose whether to test TX/RX, the authority of this parameter is lower than that of TestCard" >> lCOM.ini
	echo "TXRXTest=1" >> lCOM.ini
	echo "" >> lCOM.ini
	echo ";Please enter the COM port name and BASE, these information can be enter command" >> lCOM.ini
	echo ";in terminel: dmesg | grep tty" >> lCOM.ini
	ComAdds=($(xmlstarlet sel -t -v "//COM/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $3}'))
	for((i=0;i<${#ComDevices[@]};i++))
	do
		echo "[COM$((i+1))]" >> lCOM.ini
		echo "NAME=${ComDevices[i]}" >> lCOM.ini
		if [ "${ComAdds[i]}"x == ""x ] ; then
		Process 1 "xml config is wrong, please check BASE"
		exit 3
		fi
	#sed 
		echo "BASE=${ComAdds[i]}" >> lCOM.ini	
	done	
	return 0
}

main ()
{
	for ((i=0; i<${#ComDevices[@]};i++))
	do		
		# Detect the com port before function test
		ComDevicettySn=$(echo ${ComDevices[i]} | awk -F'/' '{print $3}')
		dmesg | grep -iq "${ComDevicettySn}"
		if [ $? -ne 0 ]; then
			Process 1 "No such COM port: ${ComDevices[i]}, ${ComPorts[i]}"
			let ErrorFlag++
			ShowDetectCom='enable'
			read -t3
			echo
			continue
		fi
	done
		TestTool=$(which lCOM.out | head -n 1)
		#echo ${TestTool}
		chmod 777 ${TestTool} 2>/dev/null
		#for ((i=0; i<20;i++))
		#do
		./lCOM.out 2>/dev/null 
		Process $?  "ComPorts function test ..." || let ErrorFlag++
			#done
		
		[ "${SkipItems}x" != "x" ] && printf "%-10s%-60s\n" "" "${SkipItems} have been skipped..."
	


	if [ ${ShowDetectCom} == 'enable' ] ; then
		echo '----------------------------------------------------------------------'
		echo "COM port detected message: "
		echo
		dmesg | grep -i 'ttyS' | awk -F':' '{print $NF}'
		echo '----------------------------------------------------------------------'
	fi

	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "${ComPorts[@]} RS232 function test"
	else 
		echoFail "${ComPorts[@]} RS232 function test"
		GenerateErrorCode
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare ItemList=(DCD RI DSR CTS)
declare ShowDetectCom='disable'
declare TestItems=''
declare XmlConfigFile ComPorts ComDevices SkipItems ApVersion
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
#ChkExternalCommands

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
			printf "%-s\n" "SerialTest,RS-232Test"
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
