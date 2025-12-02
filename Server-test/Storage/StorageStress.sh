#!/bin/bash
#FileName : StorageStress.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.3"
	local CreatedDate="2020-08-04"
	local UpdatedDate="2020-12-11"
	local Description="SSD/HDD and IO Stress test"
	
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
	printf "%16s%-s\n" "" "2020-11-18,支持NVMe SSD定位"
	printf "%16s%-s\n" "" "2020-12-11,優化Gen的判定方法"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet fio hdparm)
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
	   0 : I/O stress test pass
	   1 : I/O stress test  fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Storage>	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS1U|SATA port test fail</ErrorCode>
			
			<!--超時提前退出,單位: 秒-->
			<TimeOut>180</TimeOut>
			
			<FioParameter>
				<!--global-->
				<!--IO引擎: 異步libaio， 同步psync/sync-->
				<ioengine>psync</ioengine>
				<!--文件上I/O模块的数量，注意大于1的iodepth对于同步io来说是没用的的-->
				<iodepth>1</iodepth>
				<!--1:測試過程繞過機器自帶的buffer,使測試結果更真實-->
				<direct>1</direct>
				<!--只对异步I/O引擎有用-->
				<thread>16</thread>
				<!--本次測試線程,置空則為2的CPU的核心數量次方-->
				<numjobs>4</numjobs>
				<!--預運行時間-->
				<ramp_time>1</ramp_time>
				<!--rw: 讀寫模式請填寫: randwread|randwrite, randrw, read|write, rw-->
				<rw>read|write</rw>
				<!--單次IO的塊文件大小: 4k/16k/32k-->
				<bs>4k</bs>
				
				<!--測試時間,和size不能同時設置,同时设置以runtime為準-->
				<runtime>2</runtime>			
				<!--本次測試文件的大小,和runtime不能同時設置-->
				<size>1G</size>
			</FioParameter>
			
			<Test>
				<!--Speed:填写1.5/3.0/6.0，单位为Gbps，不需要填写单位-->
				<!--ReadBW/WriteBW讀寫帶寬: 單位是MB/s,測試過程讀到KB/s級別的判fail;不測試則填寫null-->
				<!--Address|Speed|ReadBW|WriteBW|Location-->
				<Port>2:0:0:0|6.0|100|80|SATA1</Port>
				<Port>2:0:1:0|6.0|100|80|SATA2</Port>
				<Port>2:0:2:0|6.0|100|80|SATA3</Port>
			</Test>
		</TestCase>
	</Storage>	
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
	TimeOut=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/TimeOut" -n "${XmlConfigFile}" 2>/dev/null)
	TimeOut=${TimeOut:-240}
	
	ioengine=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/ioengine" -n "${XmlConfigFile}" 2>/dev/null)
	iodepth=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/iodepth" -n "${XmlConfigFile}" 2>/dev/null)
	direct=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/direct" -n "${XmlConfigFile}" 2>/dev/null)
	thread=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/thread" -n "${XmlConfigFile}" 2>/dev/null)
	numjobs=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/numjobs" -n "${XmlConfigFile}" 2>/dev/null)
	ramp_time=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/ramp_time" -n "${XmlConfigFile}" 2>/dev/null)
	rw=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/rw" -n "${XmlConfigFile}" 2>/dev/null | tr '|' " "))
	bs=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/bs" -n "${XmlConfigFile}" 2>/dev/null)
	
	size=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/size" -n "${XmlConfigFile}" 2>/dev/null)
	runtime=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/FioParameter/runtime" -n "${XmlConfigFile}" 2>/dev/null)
	
	Address=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Test/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $1}'))
	Speed=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Test/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $2}'))
	ReadBW=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Test/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $3}'))
	WriteBW=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Test/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $4}'))
	Location=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Test/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $5}'))
	if [ ${#Location[@]} != ${#Address[@]} ] || [ ${#Location[@]} != ${#Speed[@]} ] || [ ${#Location[@]} != ${#ReadBW[@]} ] || [ ${#Location[@]} != ${#WriteBW[@]} ] ; then
		Process 1 "Test/Port參數不能留空,使用null補充空位 ..."
		let ErrorFlag++
	fi

	if [ ${#numjobs} == 0 ] ; then
		numjobs=$(printf "%s\n" "2^`grep -ic "processor" /proc/cpuinfo`" | bc)
	fi
	
	if [ $(echo ${ioengine} | grep -iwc "libaio\|psync\|sync" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'ioengine': ${ioengine}"
		let ErrorFlag++
	fi
	
	if [ $(echo ${iodepth} | grep -iwEc "[0-9]{1,9}" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'iodepth': ${iodepth}"
		let ErrorFlag++
	fi	
	
	if [ $(echo ${direct} | grep -iwc "0\|1" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'direct': ${direct}"
		let ErrorFlag++
	fi
	
	if [ $(echo ${thread} | grep -iwEc "[0-9]{1,9}" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'thread': ${thread}"
		let ErrorFlag++
	fi	
	
	if [ $(echo ${numjobs} | grep -iwEc "[0-9]{1,9}" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'numjobs': ${numjobs}"
		let ErrorFlag++
	fi

	if [ $(echo ${ramp_time} | grep -iwEc "[0-9]{1,9}" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'ramp_time': ${ramp_time}"
		let ErrorFlag++
	fi
	
	if [ $(echo ${rw} | grep -iwc "randwread\|randwrite\|randrw\|read\|write\|rw" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'rw': ${rw}"
		let ErrorFlag++
	fi
	
	if [ $(echo ${bs} | grep -iwEc "[0-9]{1,9}[kmg]" ) != 1 ] ; then
		Process 1 "Error fio parameter of 'bs': ${bs}"
		let ErrorFlag++
	fi
	
	if [ ${#runtime} != 0 ] ; then
		if [ $(echo ${runtime} | grep -iwEc "[0-9]{1,9}" ) != 1 ] ; then
			Process 1 "Error fio parameter of 'runtime': ${runtime}"
			let ErrorFlag++
		fi
	fi
	
	if [ ${#size} != 0 ] ; then
		if [ $(echo ${size} | grep -iwEc "[0-9]{1,9}[kmg]" ) != 1 ] ; then
			Process 1 "Error fio parameter of 'size': ${size}"
			let ErrorFlag++
		fi	
	fi
	
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0			
}

DefineKeyAddress()
{
	KeyAddress=()
	for ((E=0;E<${#Address[@]};E++))
	do
		echo "${Address[$E]}" | grep -iEq "^ata" 			&& KeyAddress[$E]=ATA
		echo "${Address[$E]}" | grep -iEq "^host" 			&& KeyAddress[$E]=HOST
		echo "${Address[$E]}" | grep -iEq "^target"			&& KeyAddress[$E]=TARGET
		echo "${Address[$E]}" | grep -iEq "^[0-9]{1,3}"		&& KeyAddress[$E]="[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}"
		echo "${Address[$E]}" | grep -iEq "^mmc"			&& KeyAddress[$E]="MMC[0-9]\{1,2\}"
		echo "${Address[$E]}" | grep -iEq "^nvme"			&& KeyAddress[$E]="nvme[0-9]\{1,2\}"
		echo "${Address[$E]}" | grep -iEq "^[0-9A-F]{4}"	&& KeyAddress[$E]="[0-9A-F]\{4\}:[0-9A-F]\{2\}:[0-9A-F]\{2\}.[0-9A-F]"

		echo "${Address[$E]}" | grep -iq "${KeyAddress[$E]}" 2>/dev/null
		if [ $? != 0 ] ; then
			Process 1 "Wrong config word: ${Address[$E]}"
			let ErrorFlag++
		fi
	done
	if [ "${ErrorFlag}" != 0 ] ; then
		exit 4
	else
		return 0
	fi
}

GetDeviceGeneration ()
{
	local TargetDeviceAddr=$1                        # Addr
	# Usage: GetDeviceGeneration 1:1:0:0 SATA1 /dev/sda 6.0 

	echo  "${TargetDeviceAddr}" | grep -iq "nvme\|mmc"
	if [ $? == 0 ] ; then
		echo "n/a"
		return 0
	fi

	local TargetKeyAddress=NULL
	echo "${TargetDeviceAddr}" | grep -iEq "^ata" 			&& TargetKeyAddress=ATA
	echo "${TargetDeviceAddr}" | grep -iEq "^host" 			&& TargetKeyAddress=HOST
	echo "${TargetDeviceAddr}" | grep -iEq "^target"		&& TargetKeyAddress=TARGET
	echo "${TargetDeviceAddr}" | grep -iEq "^[0-9]{1,3}"	&& TargetKeyAddress="[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}"
	echo "${TargetDeviceAddr}" | grep -iEq "^mmc"			&& TargetKeyAddress="MMC[0-9]\{1,2\}"
	echo "${TargetDeviceAddr}" | grep -iEq "^nvme"			&& TargetKeyAddress="nvme[0-9]\{1,2\}"
	echo "${TargetDeviceAddr}" | grep -iEq "^[0-9A-F]{4}"	&& TargetKeyAddress="[0-9A-F]\{4\}:[0-9A-F]\{2\}:[0-9A-F]\{2\}.[0-9A-F]"

	# ../devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0/block/sda
	# ../devices/pci0000:00/0000:00:1b.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0
	# ../devices/pci0000:ae/0000:ae:02.0/0000:b0:00.0/nvme/nvme0/nvme0n1
	# ../devices/pci0000:ae/0000:ae:03.0/0000:b1:00.0/nvme/nvme1/nvme1n1

	# ata1, host0, target0:0:0; 0:0:0:0
	Block2DeviceAddr=$(ls -l /sys/block/ | grep -iw "${TargetDeviceAddr}" | tr '/' '\n' | grep -v ">" | grep  -iA20 "${TargetKeyAddress}" | head -n1 )
	Block2DeviceAddrID=$(echo ${Block2DeviceAddr} | awk -F':' '{print $1}' | tr -d [[:alpha:]] )

	[ "${TargetKeyAddress}" != "ATA" ] && let Block2DeviceAddrID++
	#DeviceVolAddr=$(echo ata${Block2DeviceAddrID})   #e.g.: ata2
	DeviceVolAddr=$(ls -l /sys/block/ | grep -iw "${TargetDeviceAddr}" | tr '/' '\n' | grep -iwE "ata[0-9]{1,3}")
	DeviceVolAddr=${DeviceVolAddr:-"NULL_STRING"}
	CurGenSpeed=$(dmesg | grep -i sata | grep -iw "${DeviceVolAddr}:" | grep "link up" |awk -F'link up' '{print $2}' | awk '{print $1}' | tr -d [A-Za-z] | tr -d ' ' | tail -n1 )
	CurGenSpeed=${CurGenSpeed:-0.0}
	GenUnit=$(dmesg | grep -i sata | grep -iw "${DeviceVolAddr}:" | grep "link up" |awk -F'link up ' '{print $2}' | awk '{print $2}' | tr -d [.0-9] | tr -d ' ' | tail -n1 )
	GenUnit=${GenUnit:-"Gbps"}
	echo "${CurGenSpeed}Gbps"
	return 0
}

GetRelation ()
{
	echo "${#Location[@]}" | grep -iq "usb"
	if [ $? == 0 ] ; then
		Process 1 "Current ${ShellFile} is not suitable for USB function test"
		exit 3	
	fi

	# ata1|/dev/sda|4562(Last 4bit SN)
	rm -rf ${CurRelationship} 2>/dev/null

	# ata1|Gen3.0|200|miniSAS-3-0,address=ata1
	# host0/target0:0:0/0:0:0:0/block/sda 
	[ ! -d .temp ] && mkdir -p ${WorkPath}/.temp 2>/dev/null

	DefineKeyAddress

	# ../devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0/block/sda
	# ../devices/pci0000:00/0000:00:1b.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0
	# ../devices/pci0000:ae/0000:ae:02.0/0000:b0:00.0/nvme/nvme0/nvme0n1
	# ../devices/pci0000:ae/0000:ae:03.0/0000:b1:00.0/nvme/nvme1/nvme1n1

	for ((F=0;F<${#Address[@]};F++))
	do
		# KeyAddress,eg.: ata2
		Block2DeviceAddr[$F]=$(ls -l /sys/block/ | grep -iw "${Address[$F]}" | tr '/' '\n' | grep -v ">" | grep  -iA20 "${KeyAddress[$F]}" | head -n1 )

		# sda
		Block2DeviceName[$F]=$(ls -l /sys/block/ | grep -iw "${Address[$F]}" | tr '/' '\n' | grep  -iA20 "${KeyAddress[$F]}" | tail -n1 )
		DeviceSN[$F]=$(hdparm -I "/dev/${Block2DeviceName[$F]}" 2>/dev/null | grep -i "Serial Number" | head -n1 | awk '{print $3}') 
		if [ ${#DeviceSN[$F]} == 0 ] ; then
			DeviceSN[$F]='null'
		fi
		 
		# 1:0:0:0|/dev/sda|4701|SATA1 --> ${CurRelationship}
		if [ ${#Block2DeviceAddr[$F]} == 0 ] ; then
			echo "NULL|NULL|NULL|NULL|${Location[$F]}">> ${CurRelationship}
		else
			Generation=$(GetDeviceGeneration "${Block2DeviceAddr[$F]}")
			echo "${Block2DeviceAddr[$F]}|/dev/${Block2DeviceName[$F]}|${DeviceSN[$F]:0-4:4}|${Generation:-n/a}|${Location[$F]}">> ${CurRelationship}
		fi
		
		sync;sync;sync
	done
	sed -i "s/||/|null|/g" ${CurRelationship}
	# TestDevicePath=(/dev/sda /dev/sdb /dev/sdc ...)
	local SolePcbMarking=($(echo ${Location[@]} | tr ' ' '\n' | sort -u ))
	local SolePcbMarking=$(echo ${SolePcbMarking[@]} | sed 's/ /\\|/g')
	TestDevicePath=($(cat ${CurRelationship} | grep -w ${SolePcbMarking} | grep -ivw "${BootDiskVolume}" | awk -F'|' '{print $2}' ))
	TestLocation=($(cat ${CurRelationship} | grep -w ${SolePcbMarking} | grep -ivw "${BootDiskVolume}" | awk -F'|' '{print $5}' )) 
}

GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457

	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" |awk '{print $1}'| sed -n 1p | awk '{print $1}' | tr -d ': ')
	#BootDiskVolume=$( echo $BootDiskVolume | cut -c 1-$((${#BootDiskVolume}-1))) 
	BootDiskVolume=$(lsblk | grep -wB30 "`basename ${BootDiskVolume}`" | grep -iw "disk" | tail -n1 | awk '{print $1}')
	BootDiskVolume=$(echo "/dev/${BootDiskVolume}" )
	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $NF}')
}

CreateFioConfigureFile()
{
	rm -rf ${BaseName}.conf ${LOGDIR}/${BaseName}StatusGroup.txt ${BaseName}.log 2>/dev/null
	if [ ${#runtime} != 0 ] ; then
		cat <<-Conf > ${BaseName}.conf
		[global]
		time_based
		group_reporting
		norandommap
		ioengine=${ioengine}
		iodepth=${iodepth}
		direct=${direct}
		thread=${thread}
		numjobs=${numjobs}
		bs=${bs}
		timeout=$((runtime+20))
		randrepeat=0
		ramp_time=${ramp_time}
		runtime=${runtime}
		
		Conf
	elif [ ${#size} != 0 ] ; then
		cat <<-Conf > ${BaseName}.conf
		[global]
		time_based
		group_reporting
		norandommap
		ioengine=${ioengine}
		iodepth=${iodepth}
		direct=${direct}
		thread=${thread}
		numjobs=${numjobs}
		bs=${bs}
		randrepeat=0
		ramp_time=${ramp_time}
		size=${size}
		
		Conf
	else
		Process 1 "Both runtime and size are null ..."
		exit 3
	fi
	
	let index=0
	for((i=0;i<${#rw[@]};i++))
	do
		for((j=0;j<${#TestDevicePath[@]};j++))
		do
			echo ${TestDevicePath[j]} | grep -iwq "null" && continue
			cat<<-TestJobs >>${BaseName}.conf
			[${TestLocation[j]}-${bs}-${rw[i]}]
			rw=${rw[i]}
			filename=${TestDevicePath[j]}
			stonewall
			
			TestJobs
			echo "${TestLocation[j]}|${bs}|${rw[i]}|Run status group ${index}" >>${LOGDIR}/${BaseName}StatusGroup.txt
			let index++
		done	
	done  
	sync;sync;sync
}

FioStressTest()
{	
	printf "%s\n" "**********************************************************************"
	printf "%s\n" "*****              SSD/HDD I/O stress test for linux             *****"
	printf "%s\n" "**********************************************************************"
	FIOTool=$(which fio | head -n1)
	chmod 777 ${FIOTool}

	printf "%-23s%-2s%-s\n" "Devices count" ":" "${#Location[@]} PCS"
	
	printf "%-23s%-2s%-s\n" "I/O engine" ":" "${ioengine}"
	printf "%-23s%-2s%-s\n" "I/O depth" ":" "${iodepth}"
	printf "%-23s%-2s%-s\n" "Direct" ":" "${direct}"
	printf "%-23s%-2s%-s\n" "Thread" ":" "${thread}"
	printf "%-23s%-2s%-s\n" "Number jobs" ":" "${numjobs}"
	if [ ${#runtime} != 0 ] ; then
		printf "%-23s%-2s%-s\n" "Run time" ":" "${runtime}s"
		printf "%-23s%-2s%-s\n" "FIO Time out" ":" "$((timeout+20))s"
	fi
	printf "%-23s%-2s%-s\n" "Ramp time" ":" "${ramp_time}s"
	[[ ${#size} != 0 && ${#runtime} == 0 ]] && printf "%-23s%-2s%-s\n" "File size" ":" "${size}"
	printf "%-23s%-2s%-s\n" "Block size" ":" "${bs}"
	printf "%-23s%-2s%-s\n" "Test mode" ":" "`echo ${rw[@]} | sed "s/ / and /g"`"
	
	printf "%-23s%-2s%-s\n" "Stress test timeout" ":" "${TimeOut}s"
	printf "%-23s%-2s%-s\n" "Working directory" ":" "${PWD}"
	printf "%-23s%-2s%-s\n" "FIO tool" ":" "${FIOTool}"
	printf "%-23s%-2s%-s\n" "LOGs directory" ":" "${PWD}/`basename ${LOGDIR}`"
	printf "%-23s%-2s%-s\n" "Boot disk" ":" "${BootDiskVolume}"
	
	echo
	printf "%-23s%-2s"      "Jobs started at date" ":"
	date "+%Y/%m/%d %H:%M:%S"
	
	${FIOTool} ${BaseName}.conf > ${LOGDIR}/${BaseName}.log 2>&1 &
	
	printf "\n%s\n" "Please wait a moment ..."
	for((s=1;s>0;s++))
	do
		local ChildenProcesses=($(pgrep -P ${PIDKILL} fio))
		if [ ${#ChildenProcesses[@]} == 0 ]; then
			break
		elif [ ${s} -ge ${TimeOut} ] ; then	
			echo
			echo -n "End of testing(TIMEOUT)... "
			echo "KILL CHILD" && kill -9 $(pgrep -P ${PIDKILL} fio) >/dev/null 2>&1 && echo "Childen processes - KILLED."
			echo "Finished the SSD/HDD Stress test"
			printf "%-23s%-2s" "Jobs finished at date" ":"
			date "+%Y/%m/%d %H:%M:%S"
			sync;sync;sync
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
	echo
	echo -n "End of testing(Excution ended)... "
	echo "Finished the FIO"
	printf "%-23s%-2s" "Jobs finished at date" ":"
	date "+%Y/%m/%d %H:%M:%S"		
}

ParseTestLog()
{
	rm -rf ${LOGDIR}/${BaseName}TestResult.log 2>/dev/null
	local Loaction=($(cat ${CurRelationship} | awk -F'|' '{print $5}'))
	for((k=0;k<${#Loaction[@]};k++))
	do
		local Info=$(cat ${CurRelationship} | grep -iw "${Loaction[k]}")
		if [ $(echo "${Info}" | grep -iwc "${BootDiskVolume}") == 1 ] ; then
			echo "${Info}|SKIP|SKIP" >> ${LOGDIR}/${BaseName}TestResult.log
		else
			if [ $(cat ${LOGDIR}/${BaseName}StatusGroup.txt | grep -wc "${Loaction[k]}") == 0 ] ; then
				echo "${Info}|0MB/s|0MB/s" >> ${LOGDIR}/${BaseName}TestResult.log
			else
				local StatusGroupIndex=$(cat ${LOGDIR}/${BaseName}StatusGroup.txt | grep -w "${Loaction[k]}" | grep -w "randwread\|randrw\|read\|rw" | awk '{print $4}')			
				local ReadBW=$(cat ${LOGDIR}/${BaseName}.log | grep -w -A2 "${StatusGroupIndex}" | grep -w "READ" | awk '{print $3}' | tr -d '(),')
				
				StatusGroupIndex=$(cat ${LOGDIR}/${BaseName}StatusGroup.txt | grep -w "${Loaction[k]}" | grep -w "randwrite\|randrw\|write\|rw" | awk '{print $4}')
				local WriteBW=$(cat ${LOGDIR}/${BaseName}.log| grep -w -A2 "${StatusGroupIndex}" | grep -w "WRITE" | awk '{print $3}' | tr -d '(),')
				echo "${Info}|${ReadBW:-0MB/s}|${WriteBW:-0MB/s}" >> ${LOGDIR}/${BaseName}TestResult.log
			fi	
		fi
	done
	sync;sync;sync
}

CheckShowResult()
{
	
	#TestResult:
	#2:0:0:0|/dev/sda|5432|0.0Gbps|SATA1|SKIP|SKIP
	#2:0:1:0|/dev/sdb|5432|0.0Gbps|SATA2|337MB/s|266MB/s
	#2:0:2:0|/dev/sdc|5432|0.0Gbps|SATA3|323MB/s|270MB/s
	#No  Location        Device     SN   LinkSpeed  ReadSpeed   WriteSpeed  Result
	#--+---------------+---------+------+---------+-----------+------------+-------
	#01  SATA1           sda       5432   6.0Gbps    323MB/s     323MB/s     Pass
	#02  SATA2           nvme0n1   5432   6.0Gbps    323MB/s     323MB/s     Pass
	#03  SATA3           mmcblk0   5432   6.0Gbps    323MB/s     323MB/s     Pass
	#--+---------------+---------+------+---------+-----------+------------+-------
	
	printf "%-4s%-16s%-11s%-5s%-11s%-12s%-12s%-7s\n" "No" "Location" "Device" "SN" "LinkSpeed" "ReadSpeed" "WriteSpeed" "Result"
	printf "%s\n" "--+---------------+---------+------+---------+-----------+------------+-------"
	for((q=0;q<${#Location[@]};q++))
	do
		SubErrorFlag=0
		local TestResultInfo=($(cat ${LOGDIR}/${BaseName}TestResult.log | grep -iw "${Location[q]}" | tr '|' ' '))
		printf "%02d%2s" "$((q+1))" ""
		DeviceName=`basename ${TestResultInfo[1]}`
		if [ ${#DeviceName} == 3 ]; then
			DeviceName=$(echo "  ${DeviceName}")
		fi
		printf "%-16s%-10s%-7s" "${Location[q]:0:14}" "${DeviceName}" "${TestResultInfo[2]}"
		
		#Speed
		if [ $(echo "${Speed[q]}" | grep -iwc "null") == 1 ]  ; then
			printf "%-11s" "------"
		else
			
			if [ $(echo "${TestResultInfo[3]:-n/a}" | grep  -iwc "${Speed[q]}Gbps") != 1 ] ; then
				printf "\e[31m%-11s\e[0m" "${TestResultInfo[3]:-n/a}"
				let SubErrorFlag++
			else
				printf "%-11s" "${TestResultInfo[3]:-n/a}"
			fi
		fi
		
		#ReadBW
		local CurReadBW=$(echo "${TestResultInfo[5]}" | tr -d "[[:alpha:]]/")
		if [ $(echo "${ReadBW[q]}" | grep -iwc "null") == 1 ] || [ "${TestResultInfo[5]}"x == 'SKIP'x ]; then
			printf "%-12s" "${TestResultInfo[5]}"
		else 
			if [ $(printf "%s\n" "${CurReadBW}-${ReadBW[q]}>0" | bc | grep -iwc "1") != 1 ] || [ $(echo "${TestResultInfo[5]}" | tr -d "[0-9]." | tr '[a-z]' '[A-Z]') != "MB/S" ] ; then
				printf "\e[31m%-12s\e[0m" "${TestResultInfo[5]:-0.0MB/s}"
				let SubErrorFlag++
			else
				printf "%-12s" "${TestResultInfo[5]:-0.0MB/s}"
			fi		
		fi
		
		#WriteBW
		local CurWriteBW=$(echo "${TestResultInfo[6]}" | tr -d "[[:alpha:]]/")
		if [ $(echo "${WriteBW[q]}" | grep -iwc "null") == 1 ] || [ "${TestResultInfo[6]}"x == 'SKIP'x ] ; then
			printf "%-12s" "${TestResultInfo[6]}"
		else 
			if [ $(printf "%s\n" "${CurWriteBW}-${WriteBW[q]}>0" | bc | grep -iwc "1") != 1 ] || [ $(echo "${TestResultInfo[6]}" | tr -d "[0-9]." | tr '[a-z]' '[A-Z]') != "MB/S" ] ; then
				printf "\e[31m%-12s\e[0m" "${TestResultInfo[6]:-0.0MB/s}"
				let SubErrorFlag++
			else
				printf "%-12s" "${TestResultInfo[6]:-0.0MB/s}"
			fi		
		fi
		
		if [ ${SubErrorFlag} == 0 ] ; then
			printf "\e[32m%-6s\e[0m\n" "Pass"
		else
			printf "\e[31m%-6s\e[0m\n" "Fail"	
			let ErrorFlag++
		fi
	
	done
	printf "%s\n" "--+---------------+---------+------+---------+-----------+------------+-------"
	
	TypeLog
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "${BaseName} I/O stress test"
	else
		echoFail "${BaseName} I/O stress test"
		GenerateErrorCode
	fi
}

TypeLog()
{	
	echo
	if [ ${#pcb} != 0 ] && [ $(grep -iwc "I/O stress test for linux " ../PPID/${pcb}.log 2>/dev/null ) == 0 ] && [ ${ErrorFlag} == 0 ] ; then
		printf "%s\n" "--------------------------------------------------------------------------------------" >> ../PPID/${pcb}.log
		printf "%s\n" "-------------                 I/O stress test for linux                  -------------" >> ../PPID/${pcb}.log
		printf "%s\n" "--------------------------------------------------------------------------------------" >> ../PPID/${pcb}.log
		
		cat ${LOGDIR}/${BaseName}.log 2>/dev/null  >> ../PPID/${pcb}.log
		printf "%s\n" "======================================================================================" >> ../PPID/${pcb}.log
		cat device.log  2>/dev/null  >> ../PPID/${pcb}.log
		printf "%s\n" "--------------------------------------------------------------------------------------" >> ../PPID/${pcb}.log
		printf "%s\n" "-------------                  I/O stress Test Log End                   -------------" >> ../PPID/${pcb}.log
		printf "%s\n" "--------------------------------------------------------------------------------------" >> ../PPID/${pcb}.log
		Process 0 "已经将I/O stress測試log追加到 ../PPID/${pcb}.log"
		sync;sync;sync
	fi
}

main()
{
	rm -rf ${LOGDIR}/ 2>/dev/null
	mkdir -p ${LOGDIR} 2>/dev/null
	
	GetBootDisk
	GetRelation
	CreateFioConfigureFile
	FioStressTest
	ParseTestLog
	CheckShowResult
	[ ${ErrorFlag} != 0 ] && exit 1	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare PIDKILL=$$
declare LOGDIR=./fio-Log
declare XmlConfigFile
declare CurRelationship=".temp/${BaseName}Relationship.log"
declare KeyAddress BootDiskVolume
declare Address Speed ReadBW WriteBW Location TestDevicePath TestLocation TimeOut
declare ioengine iodepth direct thread numjobs runtime ramp_time size rw bs
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
			printf "%-s\n" "SerialTest,StoragePortIOStressTest"
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
