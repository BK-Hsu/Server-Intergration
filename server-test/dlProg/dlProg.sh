#!/bin/bash
#FileName : dlProg.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2018-12-27"
	local UpdatedDate="2018-12-27"
	local Description="Download the test program by the barcode"
	
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

ChkExternalCommands ()
{
	ExtCmmds=(mes)
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

ShowHeader()
{
	echo "**********************************************************************"
	printf "%13s%-2s%-55s\n" "Function"     ": " "Download the test program by the barcode"
	printf "%13s%-2s%-55s\n" "Version"      ": " "1.0.0"
	printf "%13s%-2s%-55s\n" "Author"       ": " "Cody,qiutiqin@msi.com"
	printf "%13s%-2s%-55s\n" "Created"      ": " "2018-12-27"
	printf "%13s%-2s%-55s\n" "Updated"      ": " ""
	printf "%13s%-2s%-55s\n" "Department"   ": " "Application engineering course"
	printf "%13s%-2s%-55s\n" "Note"         ": " ""
	printf "%13s%-2s%-55s\n" "Environment"  ": " "Linux/CentOS"
	printf "%13s%-2s%-55s\n" "OS Info"      ": " "`uname -r`"
	printf "%13s%-2s%-55s\n" "BIOS info"    ": " "`dmidecode -t0 | grep "Release\|Version" | sort -u | sort -r | awk '{print $NF}' | tr '\n' ','`"
	printf "%13s%-2s%-55s\n" "Real Time"    ": " "`date +"%Y-%m-%d %H:%M:%S %Z %A"`"
	echo "**********************************************************************"

} 
 
ShowTitle()
{
	local BlankCnt=0
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                           ' | cut -c 1-${BlankCnt})
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
 
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` -i IpAddress [ -p N ] [-V]
	eg.: `basename $0` -i 172.17.160.105
	eg.: `basename $0` -i 20.40.1.42
	eg.: `basename $0` -V

	-i : IP Address, default: 20.40.1.42
	-p : LAN port
	-V : Display version number and exit(1)
		
	return code:
	 This program no return code

HELP
exit 3
}

MountProgFTP ()
{
	for((c=0;c<10000;c++))
	do
		[ ${c} -gt 3 ] && exit 1
		[ ! -d ${MountPoint} ] && mkdir -p ${MountPoint} >/dev/null 2>&1
		umount ${MountPoint} >/dev/null 2>&1
		mount -t cifs //${IpAddress}/TestApp/FT -o username=test,password=test  ${MountPoint} >/dev/null 2>&1
		Process $? "mount //${IpAddress}/TestApp/FT ${MountPoint}" || continue
		break
	done

	cp -rf /dlProg/${BaseName}.sh  /dlProg/${BaseName}_bin.sh 2>/dev/null
	gzexe /dlProg/${BaseName}_bin.sh >/dev/null 2>&1
	cp -rf /dlProg/${BaseName}_bin.sh /bin/${BaseName} 2>/dev/null
	cp -rf /dlProg/${BaseName}_bin.sh /sbin/${BaseName} 2>/dev/null
	chmod 777 /bin/${BaseName} /sbin/${BaseName} 2>/dev/null
	rm -rf /dlProg/${BaseName}_bin.sh /dlProg/${BaseName}_bin.sh~ 2>/dev/null

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

CheckIPaddr ()
{
	local IPaddr=$1
	echo $IPaddr | grep -iq "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$"
	if [ "$?" != "0" ] ; then 
		Process 1 "Invalid IP address: ${IPaddr}"
		exit 3
	fi 

	for ((i=1;i<=4;i++))
	do
		IPaddrSegment=$(echo $IPaddr | awk -F'.'  -v S=$i '{print $S}')
		IPaddrSegment=${IPaddrSegment:-"999"}
		if [ $IPaddrSegment -gt 255 ] || [ $IPaddrSegment -lt 0 ] ; then 
			Process 1 "Invalid IP address: ${IPaddr}"
			exit 3
		fi 
	done

	Process 0 "Check the IP address: ${IPaddr}" 
}

GetEthId()
{
	EthId=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "([\dA-F]{2}:){5}[\dA-F]{2}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':' ))
	if [ ${#EthId[@]} == 0 ] ; then
		Process 1 "No found any LAN devices"
		FlashLanMACShell=($(cat /dlProg/${BaseName}.ini))
		for((S=0;S<${#FlashLanMACShell[@]};S++))
		do
			if [ ! -s "${FlashLanMACShell[$S]}" ] ; then
				Process 1 "No found the shell file: ${FlashLanMACShell[$S]}"
				continue
			fi
			
			chmod 777 ${FlashLanMACShell[$S]} 2>/dev/null
			sh ${FlashLanMACShell[$S]} 
			Process $? "sh ${FlashLanMACShell[$S]}" || exit 1
			let ErrorFlag++
		done
		
		if [ $ErrorFlag	 != 0 ] ; then
			echo -e "\e[1;33m          Shutdown OS and try again ...\e[0m"
		fi
		exit 2
	fi

	printf "%-7s%-23s%-26s%-10s\n" " No" "Ethernet" "MAC Address" "Link Status"
	echo "----------------------------------------------------------------------"
	for ((e=0;e<${#EthId[@]};e++))
	do
		let E=$e+1
		if [ ${E} -le 9 ] ; then
			E=0${E}
		fi
		
		# No    Ethernet               MAC Address               Link Status
		#---------------------------------------------------------------------- 
		# 01  	eth0                   123456789012                  YES
		# 02  	eth1                   123456789013                  NO
		# 03  	enp0s2f3               12345678901A                  NO
		#----------------------------------------------------------------------	
				
		# Get MAC address
		MacAddr[$e]=$(ifconfig ${EthId[$e]} 2>/dev/null | sed 's/ /\n/g'  | grep -iP "([\dA-F]{2}:){5}[\dA-F]{2}"  | tr -d ':' | tr '[a-z]' '[A-Z]' )
		
		# Get Link status
		LinkStatus[$e]=$(ethtool ${EthId[$e]} 2>/dev/null | grep -i "Link detected" | awk -F':' '{print $2}' | tr -d ' ' | tr [a-z] [A-Z])
		
		if [ $(echo ${LinkStatus[$e]} | grep -ic "YES") -gt 0 ]  ; then
			printf "\e[1;32m%-7s%-23s%-30s%-10s\n\e[0m" " $E" "${EthId[$e]}" "${MacAddr[$e]}" "${LinkStatus[$e]}"
			let DefaultAns=$e+1
		else
			printf "%-7s%-23s%-30s%-10s\n" " $E" "${EthId[$e]}" "${MacAddr[$e]}" "${LinkStatus[$e]}"
		fi
		
	done
	echo "----------------------------------------------------------------------"
	echo
}

PingTest () 
{
	while :
	do
		if [ ${PortIndex}x == ""x ] || [ ${PortIndex}x == "0"x ]; then
			read -p "Which LAN port do you want to test,[Q]=Quit? " -t15 Ans
			Ans=${Ans:-"$DefaultAns"} 
			PortIndex=$(echo "${Ans}+0" | bc)
			echo
		else
			echo "The option has been chosen: ${PortIndex}"
		fi
		
		if [ ${PortIndex} -gt ${#EthId[@]} ] || [ ${PortIndex} -lt 1 ] ; then
			Process 1 "Invalid option: ${PortIndex}"
			PortIndex=''
			continue
		fi
		
		if [ "$Ans"x == "Q"x ] || [ "$Ans"x == "q"x ]; then 
			echo "Option: ${Ans}, exiting ..."
			exit 1
		fi
		
		ifconfig ${EthId[$PortIndex-1]} 2>/dev/null
		
		ping ${IpAddress} -I ${EthId[$PortIndex-1]} -c 2 >/dev/null 2>&1
		if [ $? == 0 ] ; then
			# ping pass
			ping ${IpAddress} -I ${EthId[$PortIndex-1]} -c 2
			[ $? == 0 ] && echoPass "Ping ${IpAddress} from LAN(${MacAddr[$PortIndex-1]}) "
			break
		fi
		
		# ping fail 
		ifconfig ${EthId[$PortIndex-1]} down >/dev/null 2>&1
		ifconfig ${EthId[$PortIndex-1]}      >/dev/null 2>&1
		
		while :
		do
			dhclient -r ${EthId[$PortIndex-1]} >/dev/null 2>&1
			ShowMsg --1 "Make sure cable has pluged in: ${EthId[$PortIndex-1]}, ${MacAddr[$PortIndex-1]}"
			Wait4nSeconds 9
			ifconfig ${EthId[$PortIndex-1]} up >/dev/null 2>&1
			
			dhclient -r ${EthId[$PortIndex-1]} >/dev/null 2>&1
			sleep 1
			dhclient -timeout 10 ${EthId[$PortIndex-1]} >/dev/null 2>&1

			ping ${IpAddress} -I ${EthId[$PortIndex-1]} -c 2
			if [ "$?" == "0" ];then
				Process 0 "Ping ${IpAddress} from LAN(${MacAddr[$PortIndex-1]}) "
				break 2
			else
				Process 1 "Ping ${IpAddress} from LAN(${MacAddr[$PortIndex-1]}) "
				echo "Please change another port ..."
				PortIndex=''
				continue 2
			fi       	
		done

		break
		
	done
}

PrintfTip()
{
	local String="$@"
	LCutCnt=$(echo "ibase=10;obase=10; (70-${#String})/2" | bc)
	RCutCnt=$(echo "ibase=10;obase=10; 50-${LCutCnt}" | bc)
	Left=$(echo "<<------------------------------------------------" | cut -c 1-${LCutCnt})
	Right=$(echo "------------------------------------------------>>" | cut -c ${RCutCnt}-)
	local PrintfStr="${Left}${String}${Right}"
	printf "\e[0;30;46m%70s\e[0m\n" "${PrintfStr}"
}

ScanPPID ()
{
	while :
	do
		BeepRemind 0
		PrintfTip "Please scan 10-bit serial number, eg.: H916168168/H9E0068168" 2>/dev/null
		read -p "Scan 10-bit `echo -e "\e[1;33mcurrent board or system's\e[0m serial number: __________\b\b\b\b\b\b\b\b\b\b"`" SerialNumber
		# The month is 1~12(1~10,A,B,C)
		echo ${SerialNumber} | grep -E "^[0-9A-Za-z]{10}+$" | grep -v "H916168168\|H9E0068168" | cut -c 2 | grep -Eq "[1-9A-Ca-c]"
		if [ "$?" != "0" ] ; then
			Process 1 "Invalid PPID: $SerialNumber `[ ${#SerialNumber}x != "10"x ] && echo "(${#SerialNumber} Bit)"`"
			MonthInfo=$(echo ${SerialNumber} | cut -c 2 | grep -E "[1-9A-Ca-c]" )
			[ ${#MonthInfo} == 0 ] && echo -e "Current 2nd char(the information of month) of PPID is invalid: \e[1;31m${SerialNumber:1:1}\e[0m"
			echo "Try again ... "
			echo
			BeepRemind 1
			continue
		fi
		echo 
		SerialNumber=$(echo ${SerialNumber} | cut -c 1-10 | tr [a-z] [A-Z])
		Process 0 "Scan in serial number is: ${SerialNumber}"
		break 
	done
}

GetProgName()
{
	if [ ! -s "/dlProg/mes" ] ; then
		Process 1 "No found any tool: mes"
		exit 1
	else
		chmod 777 /dlProg/mes 2>/dev/null
		cp -rf /dlProg/mes /sbin/ 2>/dev/null
		Process $? "cp -rf /dlProg/mes /sbin/" || exit 1	
	fi
	<<-MES
	 Linux upload tool in cmdline.Ver:1.3 2018-12-26 by Amethyst 
	 Usage: ./mes <webservice url> <func num> <text> 
	 webservice url: 
		  http://20.40.1.40/eps-web/upload/uploadservice.asmx
		  http://172.17.7.101/eps-web/upload/uploadservice.asmx
	 func num and text content:
	Function Number     Function Discription             Test Content    
	----------------------------------------------------------------------
	   1                XMLUpload                        sXML                
	   2                GetItemNo                        sBarcode            
	   3                GetStation                       sBarcode            
	   4                GetNextStation                   sBarcode            
	   5                GetWorkOrder                     sBarcode            
	   6                GetBarcodeByComponent            sCompontNo          
	   7                GetMBBarcodeByBB                 sBarcodeNo          
	   8                GetMAC                           sBarcode            
	   9                GetItemByMac                     sMac                
	   10               GetProgText                      sBarcodeNo          
	----------------------------------------------------------------------
	MES
	echo $IpAddress | grep -q "^20"
	if [ $? == 0 ] ; then
		WebIpAddress='20.40.1.40'
	else
		WebIpAddress='172.17.7.101'
	fi

	echo  -e "          \e[1;33mGet the information, please wait a moment ...\e[0m"
	WorkOrder=$(mes http://${WebIpAddress}/eps-web/upload/uploadservice.asmx 5 sBarcode=${SerialNumber}   | grep -v "===" | head -n1 )
	ModelName=$(mes http://${WebIpAddress}/eps-web/upload/uploadservice.asmx 2 sBarcode=${SerialNumber} | grep -v "===" | head -n1  )
	NextStationCode=$(mes http://${WebIpAddress}/eps-web/upload/uploadservice.asmx 4 sBarcode=${SerialNumber} | grep -v "===" | head -n1  )
	ProgramName=$(mes http://${WebIpAddress}/eps-web/upload/uploadservice.asmx 10 sBarcodeNo=${SerialNumber} | grep -v "===" | awk -F':' '/Prog_Name/{print $NF}' | tr -d ',' | head -n1 )

	<<-ShowResult
	+---------------------------------------------------------+
	|         Get the information from the MES system         |
	+-------------------+-------------------------------------+
	|Serial number      | I116306791                          |
	|Work Order         | 18D002190F                          |
	|Model Name         | 609-S1581-05S                       |
	|Next Station Code  | 1528                                |
	|Program Name       | S1581070.TAR.GZ                     |
	+-------------------+-------------------------------------+
	ShowResult

	printf "%-10s%-59s\n" "" "+---------------------------------------------------------+"
	printf "%-10s%-1s%-57s%-1s\n" "" "|" "         Get the information from the MES system" "|"
	printf "%-10s%-59s\n" "" "+--------------------+------------------------------------+"
	printf "%-10s%-2s%-19s%-2s%-35s%-1s\n" "" "|"  "Serial number" "|" "${SerialNumber}" "|"
	printf "%-10s%-2s%-19s%-2s%-35s%-1s\n" "" "|"  "Work Order" "|" "${WorkOrder}" "|"
	printf "%-10s%-2s%-19s%-2s%-35s%-1s\n" "" "|"  "Model Name" "|" "${ModelName}" "|"
	printf "%-10s%-2s%-19s%-2s%-35s%-1s\n" "" "|"  "Next Station Code" "|" "${NextStationCode}" "|"
	printf "%-10s%-2s%-19s%-2s\e[1;32m%-35s\e[0m%-1s\n" "" "|"  "Program Name" "|" "${ProgramName}" "|"
	printf "%-10s%-59s\n" "" "+--------------------+------------------------------------+"
	echo ${ProgramName} | grep -iwq "tar.gz"
	Process $? "Get the information from the MES system ..." ||	exit 1
}

DownloadProg()
{
	ProgramFile=($(ls ${MountPoint} 2>/dev/null | grep -iw ${ProgramName}))
	if [ ${#ProgramFile[@]} -gt 1 ]	; then
		Process 1 "Found too many program files in ${MountPoint}"
		printf "%-10s%-60s\n" "All program files: ${ProgramFile[@]}"
		exit 1
	else
		Process 0 "Found the ${ProgramFile} in ${MountPoint}"
	fi

	rm -rf /*.TAR.GZ 2>/dev/null
	rm -rf /*.tar.gz 2>/dev/null
	Process 0 "rm -rf /*.tar.gz"

	cp -rf ${MountPoint}/${ProgramFile} / 2>/dev/null
	Process $? "cp -rf ${MountPoint}/${ProgramFile} /" || exit 1
	sync;sync;sync

	FtpMd5Info=($(md5sum ${MountPoint}/${ProgramFile}))
	echo ${FtpMd5Info[0]} | grep -iwEq '[0-9a-z]{32}'
	Process $? "${FtpMd5Info[1]} MD5: ${FtpMd5Info[0]}" || exit 1

	LocalMd5Info=($(md5sum /${ProgramFile}))
	echo ${LocalMd5Info[0]} | grep -iwEq '[0-9a-z]{32}'
	Process $? "${LocalMd5Info[1]} MD5: ${LocalMd5Info[0]}" || exit 1

	echo ${FtpMd5Info[0]} | grep -iwq "${LocalMd5Info[0]}"
	Process $? "Compare the MD5 of ${FtpMd5Info[1]} and ${LocalMd5Info[1]} " || exit 1

	rm -rf /TestAP 2>/dev/null
	Process 0 "rm -rf /TestAP" 

	tar -zxf  /${ProgramFile} -C /
	Process $? "tar -zxf  /${ProgramFile} -C /" || exit 1
	Process 0 "Download ${ProgramFile} finished, please execute: /TestAP/TestAP.sh "
	printf "%-10s\e[0;30;42m%-60s\e[0m\n" "" "*************************************************************"
	printf "%-10s\e[0;30;42m%-60s\e[0m\n" "" "****  Download the test program by the barcode finished! ****"
	printf "%-10s\e[0;30;42m%-60s\e[0m\n" "" "*************************************************************"
	umount ${MountPoint} >/dev/null 2>&1
}

MountLogFTP ()
{
	# Usage: MountLogFTP IPAddress
	local LogFTPIp=$1
	echo $IpAddress | grep -q "^20"
	if [ $? == 0 ] ; then
		LogFTPIp='20.40.1.41'
	else
		LogFTPIp='172.17.7.105'
	fi

	LogFTPIp=${LogFTPIp:-'20.40.1.41'}

	for ((cnt=0;cnt<3;cnt++))
	do
		#Mount the Log Server to /mnt/logs
		mkdir -p /mnt/logs
		mount -t cifs //${LogFTPIp}/Testlog/SI/ -o username=test,password=test  /mnt/logs/
		if [ "$?" == "0" ]; then
			Process 0 "mount //${LogFTPIp}/Testlog/SI/ /mnt/logs/ pass "
			echo -e "          Please wait a moment ..." 
			break
		else
			printf "%-10s%-60s\n" "" "Try again, please wait a moment..."
			umount /mnt/logs/ >/dev/null 2>&1
			sleep 1
		fi
	done

	if [ ${cnt} = 3 ] ; then
		Process 1 "mount //${LogFTPIp}/Testlog/SI/ /mnt/logs/ fail "
		umount /mnt/logs >/dev/null 2>&1
		sleep 1
		exit 1
	fi
}

# Backup Test Log Function
BackupTestLog ()
{
	local sn=$1
	local folder=$(echo $2 | awk -F'-' '{print $2}')
	folder=${folder:-"96D9"}
	#Usage: BackupTestLog SN Model

	# Usage: MountLogFTP IPAddress
	echo $IpAddress | grep -q "^20"
	if [ $? == 0 ] ; then
		LogFTPIp='20.40.1.41'
	else
		LogFTPIp='172.17.7.105'
	fi
	LogFTPIp=${LogFTPIp:-'20.40.1.41'}

	# e.g.LogFileName=Prog_2017022018080808_H216263168.log
	LogFileName=Prog_$(date "+%Y%m%d%H%M%S")_${sn}.log
	printf "%-10s%-60s\n" "" "This log file save in: //${LogFTPIp}/Testlog/SI/$folder/ "

	BackupLogPath="/mnt/logs"
	#If the folder not found,then make it
	[ ! -d "${BackupLogPath}/${folder}" ] && mkdir -p  ${BackupLogPath}/${folder} 2>/dev/null

	#Copy local log to FTP server
	cp -rf ${LogFile}/${BaseName}.log ${BackupLogPath}/${folder}/${LogFileName} 2>/dev/null
	Process $? "cp -rf ${LogFile}/${BaseName}.log ${BackupLogPath}/${folder}/${LogFileName}"
	rm -rf ${LogFile}/${BaseName}.log 2>/dev/null
}

main ()
{
	clear
	[ ! -d "${LogFile}" ] && mkdir -p ${LogFile}
	{	
		ChkExternalCommands
		ShowHeader
		CheckIPaddr ${IpAddress}
		ping ${IpAddress} -c 2 >/dev/null 2>&1
		if [ $? != 0 ] ; then
			GetEthId
			PingTest
		else
			Process 0 "ping the server pass ... "
		fi
		ScanPPID
		GetProgName
		MountProgFTP
		DownloadProg
		MountLogFTP ${IpAddress}
		BackupTestLog ${SerialNumber} ${ModelName};
	} 2>&1 | tee -a ${LogFile}/${BaseName}.log
	sync;sync;sync
	[ ${ErrorFlag} != 0 ] && exit 1
}

#----Main function-----------------------------------------------------------------------------
declare -i ErrorFlag=0
declare IpAddress='20.40.1.42'
declare LogFTPIp='20.40.1.41'
declare -a EthId=()
declare -a MacAddr=()
declare -a LinkStatus=()
declare -i PortIndex=0
declare MountPoint='/var/log/dlProg'
declare LogFile='/var/log/dlProgLog'
declare SerialNumber WorkOrder ModelName NextStationCode ProgramName ApVersion
declare BaseName=$(basename $0 .sh)

#--->Get and process the parameters
while getopts :P:Vhi:p: argv
do
	 case ${argv} in
		i)
			IpAddress=${OPTARG}
			IpAddress=${IpAddress:-"20.40.1.42"}
		;;
		
		p)
			PortIndex=${OPTARG}
		;;		
		
		h)
			Usage
			exit 3
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,DownloadProgram"
			exit 1
		;;		
		
		:)
			echo "The option ${OPTARG} requires an argument."
			Usage
			exit 3
		;;
		
		?)
			echo "Invalid option: ${OPTARG}"
			Usage
			exit 3			
		;;
		esac
	
done

main
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
