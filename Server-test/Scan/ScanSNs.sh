#!/bin/bash
#FileName : ScanSNs.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.5"
	local CreatedDate="2018-10-04"
	local UpdatedDate="2024-05-20"
	local Description="Scan main board serial number and save in file: SN_MODEL_TABLE.TXT"
	
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
	printf "%16s%-s\n" "" "2019-04-12,Add the debug mode"
	printf "%16s%-s\n" "" "2019-06-22,Add the tool: scanner for forbidden keyboard input"
	printf "%16s%-s\n" "" "2020-12-31,增加適用範圍,排除小卡類測試從DMI讀取SN"
	printf "%16s%-s\n" "" "2024-05-20,增加QR Code扫码提示，取消条码格式检查，仅检查条码长度，设定长度为0时，默认不检查"
	printf "%16s%-s\n" "" "2024-05-20,只有同时满足自动输入条码设定为0，只有一个机种，且该机种为主板时才启用自动输入条码，其他情况下仍需要扫码"
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
	ExtCmmds=(xmlstarlet)
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

PrintfTip()
{
	local String="$@"
	LCutCnt=$(echo "ibase=10;obase=10; (70-${#String})/2" | bc)
	RCutCnt=$(echo "ibase=10;obase=10; 50-${LCutCnt}" | bc)
	Left=$(echo "<<------------------------------------------------" | cut -c 1-${LCutCnt})
	Right=$(echo "------------------------------------------------>>" | cut -c ${RCutCnt}-)
	local PrintfStr="${Left}${String}${Right}"
	printf "\e[0;30;43m%70s\e[0m\n" "${PrintfStr}"
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
		0 : Scan all serial number pass
		1 : Scan some serial number fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Scan>
		<!--掃描程式配置文件-->	
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			
			<!--ScanSNs.sh: 批量測試時,ModelName請填寫到機種即可,ERP不需要填寫-->
			<ModelName>S165B</ModelName>
			<ModelName>S165C</ModelName>
			
			<!-- While the value file $pcb.proc are great than AutoScanProcVal,the PPID will auto scan in -->
			<!-- AutoScanProcVal == 0 ,scan PPID by manual, you can also input a shell name instead,eg.: lan_c.sh -->
			<!--設置自動掃描開始項目，可以填寫數字或測試項目-->
			<AutoScanProcVal>10</AutoScanProcVal>
			
			<!-- ScanSNs.sh: Length=0表示no limited -->
			<Length>10</Length>
			<FormatType>PCBA</FormatType>
			<SavePath>/TestAP/PPID</SavePath>				
		</TestCase>
	</Scan>
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
	ModelList_defined=($(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/ModelName" -n "${XmlConfigFile}" 2>/dev/null))
	Length=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/Length" -n "${XmlConfigFile}" 2>/dev/null)
	SavePath=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/SavePath" -n "${XmlConfigFile}" 2>/dev/null)
	FormatType=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/FormatType" -n "${XmlConfigFile}" 2>/dev/null)
	AutoScanProcVal=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/AutoScanProcVal" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#SavePath} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

ScanPPID ()
{
	local TargetModelName=$1
	cat ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null | grep -iwq "${TargetModelName}" 
	if [ $? != 0 ] && [ ${CurProcVal} -ge 1 ] ; then
		echo -e "\e[1;33m No record found as: ${TargetModelName}, skip to next model ...\e[0m"
		return 0
	fi	

	case $FormatType in
		PCBA)
			String="PCBA"
			egPPID=$(echo 'H916168168168168168168168168' | cut -c 1-$Length)
		;;
		
		BB)
			String="Chassis"
			egPPID=$(echo 'H9E0068168168168168168168168' | cut -c 1-$Length)
		;;
		
		QR)
			String="QR Code"
			egPPID=$(echo 'S32210M_H91B068168168168168168168168' | cut -c 1-$Length)
		;;
		*)
			Process 1 "Invalid parameter: $FormatType, it should be: PCBA or BB or QR"
			exit 3
		;;
		esac

	while :
	do
		BeepRemind 0
		PrintfTip "Please scan ${sLength}-bit serial number, eg.: $egPPID" 2>/dev/null
		echo -ne "Scan ${sLength}-bit \e[1;31m$TargetModelName $String\e[0m serial number: __________\b\b\b\b\b\b\b\b\b\b"
		which scanner >/dev/null 2>&1
		if [ $? == 0 ] ; then
			rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
			scanner ${WorkPath}/scan_${BaseName}.txt || continue
			# read iSN<${WorkPath}/scan_${BaseName}.txt
			iSN=$(cat ${WorkPath}/scan_${BaseName}.txt | sed 's/!/1/g' |sed 's/@/2/g' |sed 's/#/3/g' |sed 's/\$/4/g' |sed 's/%/5/g' |sed 's/\^/6/g' |sed 's/\&/7/g' |sed 's/\*/8/g' |sed 's/(/9/g' |sed 's/)/0/g')
			rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
		else
			read iSN
		fi
		
		if [ $(echo "${iSN}" | grep -ic "qqt\|pe\|qt\pte" ) == 1  ] ; then
			# Enter debug mode,because of "trap" command
			echo -e "\e[0;30;46m ******************************************************************* \e[0m"	
			echo -e "\e[0;30;46m ***                   Welcome to debug mode !                   *** \e[0m"	
			echo -e "\e[0;30;46m ******************************************************************* \e[0m"	
			exit 9
		fi
		echo
		
		if [ $(echo "${iSN}" | grep -iwc "nn\|null" ) == 1  ] ; then
			
			cat "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null | grep -iwq "${TargetModelName}"
			if [ $? == 0 ] ; then
				Process 1 "Invalid Serial number: $iSN"
				continue
			else
				return 0
			fi

			ShowMsg --1 "No the serial number of $TargetModelName input."
			echo
			let ErrorFlag++
			return 9
		fi
		# 仅检查条码的长度是否符合要求，如果有设定长度检查的话
		if [ "${Length}"x != "0"x ] && [ ${#Length} != 0 ] ; then
			echo ${iSN} | grep -v "$egPPID" | grep -Eq "^[0-9A-Za-z_]{${Length}}+$" 
			if [ $? != 0 ] ; then
				Process 1 "The Serial number Length"
				continue
			fi
		fi
	 	
	 	# 取消针对条码格式的检查
		#if [ "$?" == "0" ] ; then
		#	case ${FormatType} in
		#		BB)
		#			echo ${iSN} | cut -c 3 | grep -Eq '^[A-Za-z]'
		#			if [ "$?" != "0" ] ; then
		#				Process 1 "Invalid PPID: $iSN (${#iSN} bit)"
		#				ThirdChar=$(echo ${iSN} | cut -c 3 )
		#				echo -e "          Current 3rd char of PPID is invalid: \e[1;31m${ThirdChar}\e[0m"
		#				printf "%-10s%-60s\n" "" "Try again ... "
		#				echo
		#				continue
		#			fi
		#		;;  
		#	
		#		*)
		#			:	
		#		;;
		#		esac
		#
		#else
		#	Process 1 "Invalid PPID: $iSN `[ ${#iSN}x != ${Length}x ] && echo "(${#iSN} Bit)"`"
		#	MonthInfo=$(echo ${iSN} | cut -c 2 | grep -E "[1-9A-Ca-c]" )
		#	[ ${#MonthInfo} == 0 ] && echo -e "Current 2nd char(the information of month) of PPID is invalid: \e[1;31m${iSN:1:1}\e[0m"
		#	printf "%-10s%-60s\n" "" "Try again ... "
		#	echo
		#	continue
		#fi
			
		iSN=$(echo ${iSN} | cut -c 1-$Length | tr [a-z] [A-Z])
		local iSNCount=$(cat "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null | grep -ic "$iSN" )
		local TargetModelNameCount=$(cat "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null | grep -ic "${TargetModelName}" )
		local MaxModelNameCount=$( echo "${ModelNameList[@]}" | tr ' ' '\n' | grep -iwc "${TargetModelName}" )
		local SN_TargetModelNameCount=$(cat "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null | grep -ic "${iSN}|${TargetModelName}" )
		
		#create table: SN|Model
		if [ ${CurProcVal} -ge 1 ] ; then
		
			cat ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null | grep -iwq "${iSN}" 
			if [ $? != 0 ] && [ ${CurProcVal} -ge 1 ] ; then
				Process 1 "${iSN} has no record in file: SN_MODEL_TABLE.TXT"
				cat  ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null 
				echo
				printf "%-10s%-60s\n" "" "Try again ... "
				continue
			fi
		
			cat -v ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null |  grep -iwq "${iSN}|${TargetModelName}" 
			if [ ${?} != 0 ] ; then
				Process 1 "No found any recorded SN: $iSN"
				continue
			fi

		else
			if [ ${iSNCount} == 0 ] && [ ${TargetModelNameCount} -lt ${MaxModelNameCount} ] && [ ${SN_TargetModelNameCount} == 0 ] ; then
				echo  "$iSN|${TargetModelName}" >> ${SavePath}/SN_MODEL_TABLE.TXT
			elif [ "${iSNCount}"x == 1x ] && [ ${SN_TargetModelNameCount} == 1 ] &&  [ ${TargetModelNameCount} == ${MaxModelNameCount} ]  ; then
				:
			else
				Process 1 "${iSN} fail to write in file: SN_MODEL_TABLE.TXT"
				cat -v ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null 
				echo
				printf "%-10s%-60s\n" "" "Try again ... "
				continue
			fi
		fi
		
		if [ $(cat "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null | grep -iEc "${iSN}") == 1 ]  ; then
			echoPass "PPID: ${iSN}, write to: .../SN_MODEL_TABLE.TXT"
			break
		else
			echoFail "Invalid file(or 0KB): .../SN_MODEL_TABLE.TXT"
			cat -v "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null
			echo "Try again ... "
			echo
		fi
	done

	return 0
}

ShowTitle()
{
	echo 
	ApVersion=$(cat -v `basename $0` | grep -i "version" | head -n1 | awk '{print $3}')
	local Title="$@, version: ${ApVersion}"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

Wait4nSeconds()
 {
	local sec=$1
	sec=${sec:-'3'}
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do  
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -s -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			if [ "$Ans" == "Q" ] ; then
				echo
				echo "Skip out delete log program ..."
				exit 5
			fi
			break
		else
			continue
		fi
	done
	echo '' 
}

#Back up Test log to local disk
BackupLog2Local ()
{
	local TargetPath='../PPID'
	SN=$(cat -v ../PPID/PPID.TXT 2>/dev/null | head -n1 )
	SN=${SN:-"H916168168"}
	LocalLog='/.LocalLog'

	[ ! -d "${LocalLog}" ] && mkdir -p "${LocalLog}" 2>/dev/null

	LogName=$(echo "$(date "+%Y%m%d%H%M%S")_${SN}")
	mkdir -p "${LocalLog}"/${LogName} > /dev/null 2>&1

	cp -rf $TargetPath/${SN}.log   "${LocalLog}"/${LogName}  > /dev/null 2>&1
	cp -rf $TargetPath/${SN}.proc  "${LocalLog}"/${LogName} > /dev/null 2>&1
	cp -rf $TargetPath/.procMD5    "${LocalLog}"/${LogName}/procMD5 > /dev/null 2>&1
	 
	find ../PPID/ -type f -iname *.txt -print | xargs -n1 -I {} cp -rf {}  "${LocalLog}"/${LogName}

	cd "${LocalLog}"
	tar -zcvf ${LogName}_part.tar.gz ${LogName}/ >/dev/null 2>&1
	if [ $? != 0 ] ;then
		Process 1 "Back up ${LogName}_part.tar.gz"
	fi 	
	rm -rf ${LogName} >/dev/null 2>&1
	cd ${WorkPath}
}  

DelelteAllLog ()
{
	local DelayTime=$1
	echo -e "\e[0;30;43m ********************************************************************* \e[0m"
	echo -e "\e[0;30;43m **   Warning: all test log file will be deleted after $DelayTime secondes   ** \e[0m"
	echo -e "\e[0;30;43m ********************************************************************* \e[0m"
	Wait4nSeconds $DelayTime
	BackupLog2Local

	# Must reboot the system after write MAC address
	rm -rf /etc/udev/rules.d/70-persistent-net.rules
	rm -rf /etc/sysconfig/network-scripts/ifcfg-eth[0-99] 2>/dev/null

	echo
	echo -e "\e[1m Search the test record and clear the files ... \e[0m"
	printf "\e[1m%-7s%-24s%-27s%-12s\e[0m\n" "  No" " File  type " "Amount"  "Result?"
	echo -e "----------------------------------------------------------------------"

	DeleteLog=(txt~ log~ sh~ sh.bak txt.bak swo swp log txt proc tmp)
	for((d=0;d<${#DeleteLog[@]};d++))
	do	
		AllRecordFiles=($(find ..  -maxdepth ${MaxDepth:-"2"} -type f -iname "*.${DeleteLog[$d]}" -print 2>/dev/null | grep -iE "*.${DeleteLog[$d]}+$" | grep -iv "readme\|AMI"  ))
		rm -rf "${AllRecordFiles[@]}" >/dev/null 2>&1
		if [ ${#AllRecordFiles[@]} != 0 ] ; then
			printf "%-2s%02d%-30s%-24s\e[1;32m%-9s\n\e[0m" "" "$((d+1))" "    *.${DeleteLog[$d]}" "${#AllRecordFiles[@]}"  "Deleted" 
		else
			printf "%-2s%02d%-30s%-24s\e[1m%-9s\n\e[0m"    "" "$((d+1))" "    *.${DeleteLog[$d]}" "${#AllRecordFiles[@]}"  "   -   "
		fi
	done
	echo -e "----------------------------------------------------------------------"
	echo
	Process 0 "${DeleteLog[@]} are deleted ..."
}

AutoScanPPID () 
{
	local DMI=$1
	if [ -s "${SavePath}/PPID.TXT" ] ; then
		TempPCB=$(cat "${SavePath}/PPID.TXT")
	else
		echoFail "Invalid file: ${SavePath}/PPID.TXT"
		exit 2
	fi

	if [ ${DMI}x == 'disable'x ] ; then
		# Get LAN MAC address
		rm -rf ${BaseName}.log 2>/dev/null
		ifconfig -a 2>/dev/null | sed 's/ /\n/g'  | grep -iP "([\dA-F]{2}:){5}[\dA-F]{2}"  | tr -d ':' | tr '[a-z]' '[A-Z]' > ${BaseName}.log 2>/dev/null
		# Get BMC MAC address
		modprobe ipmi_devintf >/dev/null 2>&1 || modprobe ipmi_si 2>/dev/null 
		ipmitool lan print 1 2>/dev/null | grep 'MAC Address' | cut -c 27-43 | tr -d ':' | tr [a-z] [A-Z] >> ${BaseName}.log

		TotalMACAddr=($(cat ${BaseName}.log 2>/dev/null | grep -v "^$"))
		SoleTotalMACAddr=($(echo ${TotalMACAddr[@]} | tr ' ' '\n' | sort -u ))
		SoleTotalMACAddr=$(echo ${SoleTotalMACAddr[@]} | sed 's/ /\\|/g')

		LocalMACFile=($(find ../ -iname *mac*.txt ))
		echo -e "\e[1m Search the relationship of MAC address and PPID ... \e[0m"
		printf "\e[1m%-4s%-16s%-12s%-16s%-10s%-5s\n\e[0m" " No " " Serial  Number " " " "LAN/BMC MAC Addr"  " "  "Matches?"
		echo -e "----------------------------------------------------------------------"

		for((j=0;j<${#LocalMACFile[@]};j++))
		do 
			let J=$j+1
			ReadMacFrFile=$(cat ${LocalMACFile[$j]} 2>/dev/null)
			if [ "$(cat ${LocalMACFile[$j]} 2>/dev/null | grep -iwc "${SoleTotalMACAddr}")" != "0" ] ; then
				pcb=$(cat ${SavePath}/PPID.TXT  2> /dev/null) 
				TargetMac=$(cat ${LocalMACFile[$j]} 2>/dev/null | head -n1 )
				printf "%-4s%-16s%-12s%-16s%-10s\e[1;32m%-5s\n\e[0m" " $J " "   $TempPCB   " " " "  $ReadMacFrFile  "  " "  "success"             
				break 1
			else
				printf "%-4s%-16s%-12s%-16s%-10s\e[1;31m%-5s\n\e[0m" " $J " "   $TempPCB   " " " "  $ReadMacFrFile  "  " "  "failure"
				rm -rf ../PPID/.log 2>/dev/null
				rm -rf ../.log 2>/dev/null
			fi
		done
		echo -e "----------------------------------------------------------------------"

		# if the MAC address do not macthes with the OP Scan,then delete the TestLog first
		if [ "${j}" -ge "${#LocalMACFile[@]}" ] ; then
			[ -s ./JPG/DelLog.jpg ] && eog -f ./JPG/DelLog.jpg 2>/dev/null &
			ShowMsg --b "No MACs address found which macthes with $TempPCB."
			ShowMsg --e "All test log file will be deleted ..."
			echo
			DelelteAllLog 9	
			ScanPPIDs 0
		fi
		echo
	else
		pcb=$(cat ${SavePath}/PPID.TXT  2> /dev/null) 
	fi

	sed -n 1p ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null |  grep -iwq "$pcb"
	if [ $? != 0 ] ; then
		Process 1 "Main PPID is not macth. The main PPID verify"
		printf "%-10s%-60s\n" "" "           PPID.TXT: `cat ${SavePath}/PPID.TXT`"
		printf "%-10s%-60s\n" "" " SN_MODEL_TABLE.TXT: `cat ${SavePath}/SN_MODEL_TABLE.TXT | head -n1 | awk -F'|' '{print $1}'`"
		exit 1
	fi
	echoPass "Main PPID: $pcb, read from: $SavePath/PPID.TXT"
	return 0
}
# End of AutoScanPPID

ScanPPIDs()
{
	local FirstMDL=$1
	let Begin=${FirstMDL}-1
	if [ ${#ModelList_defined[@]} == 1 ];then
		ModelNameList=${ModelList_defined[@]}
	else
		if [ ! -s modellist.ini ];then

			printf "\e[0;30;43m%s\e[0m\n" "请按如下提示选择哪些机种将要测试 "
			for ((i=0;i<${#ModelList_defined[@]};i++))
			do
				#read -p "\r\e[1;32mif the model is ${ModelNameList[$i]}, please input $(($i+1))\e[0m" ans
				printf "\e[0;30;42m %-60s \e[0m" "如果待测机种是 ${ModelList_defined[$i]}, 请输入 Y or y, 输入其他任意键跳过此机种: " 
				read ans
				echo "$ans" |grep -iw "y" >/dev/null 2>&1 
				if [ $? == 0 ];then
				echo "${ModelList_defined[$i]}" >> modellist.ini
				fi
			done
			if [ ! -s modellist.ini ];then
				Process 1 "no model is selected or modellist.ini is not exist"
				exit 3
			fi
			itemsum=$(cat -v modellist.ini |wc -l)
			if [ ${itemsum} == 0 ];then 
				Process 1 "no model is selected"
				exit 3
			fi
			for ((i=0; i<${itemsum};i++))
			do
				temp=$(cat -v modellist.ini |grep -v "^$"|sed -n $(($i+1))p)
				#echo "continue scan processing"
				if [ "$temp" == "" ];then
					continue
				else
					ModelNameList[$i]=$temp
				fi
			done
			#for ((i=0; i<${#ModelList_defined[@]};i++))
			#do
			#	echo ${choice[$i]}
			#	if [ "${choice[$i]}" == "" ];then
			#		continue
			#	else
			#		ModelNameList[$i]=${ModelList_defined[${choice[$i]}]}
			#		echo "${ModelList_defined[${choice[$i]}]}" >> modellist.ini
			#	fi
			#done
		else
			itemsum=$(cat -v modellist.ini |wc -l)
			if [ ${itemsum} == 0 ];then 
				Process 1 "no model is selected"
				exit 3
			fi
			for ((i=0;i<${itemsum};i++))
			do
			temp=$(cat -v modellist.ini |grep -v "^$"|sed -n $(($i+1))p)
			#echo "continue scan processing"
			if [ "$temp" == "" ];then
				continue
			else
				ModelNameList[$i]=$temp
			fi
			done
		fi
	fi
	echo -e "Model ${ModelNameList[@]} will be tested"
	#Scan From 1st
	for((j=${Begin};j<${#ModelNameList[@]};j++))
	do
		let J=${j}+1
		if [ "${j}X" == "0X" ] && [ ${CurProcVal} == 0 ] ; then
			rm -rf ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null
		fi
		ScanPPID ${ModelNameList[$j]}
	done
}

main()
{
	which scanner >/dev/null 2>&1
	if [ $? != 0 ] && [ -f "scanner" ] ; then
		chmod 777 ./scanner >/dev/null 2>&1
		cp -rf ./scanner /bin >/dev/null 2>&1	 
	fi

	EOS=$(echo $SavePath | tr -d ' ' | awk -F'/' '{print $NF}')
	if [ ${#EOS} == 0 ] ; then
		let CutLength=${#SavePath}-1
		SavePath=$(echo $SavePath | tr -d ' ' | cut -c 1-${CutLength} )
	else
		SavePath=$(echo $SavePath | tr -d ' ')
	fi

	if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
		Length=''
		# Show length on screem
		sLength='No-limited'
	else
		sLength=${Length}
	fi

	echo ${AutoScanProcVal} | tr -d ' ' | grep -iEq '[0-9]'
	if [ $? == 0 ]; then
		AutoScanProcLable='number'
	else
		AutoScanProcLable='shell'
		AutoScanProcVal=$(basename ${AutoScanProcVal} .sh)
	fi

	if [ -s "${SavePath}/PPID.TXT" ] && [ -s "${SavePath}/SN_MODEL_TABLE.TXT" ] ; then
		ReadPCBFrFile=$(cat "${SavePath}/PPID.TXT")
		CurProcVal=$(cat ../PPID/${ReadPCBFrFile}.proc 2>/dev/null | head -n1 )
		CurProcVal=${CurProcVal:-"0"}
		local FirstModelName=$(sed -n 1p ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null | awk -F'|' '{print $2}' | tr '-' '\n' | grep -iwE '[0-9A-Z]{4,9}')
		echo "${FirstModelName: -1:1}" 2>/dev/null | grep -iEq "[A-Z]"
		if [ $? == 0 ] ; then
			local ModelType="Card"
		else
			local ModelType="MB"
		fi
		# 当自动输入为enable,且只有一个机种，并且该机种为主板时才执行自动扫码动作
		if [ "${AutoScanProcVal}"x != "0"x ] && [ "$(grep -v "^$" "${SavePath}/SN_MODEL_TABLE.TXT" | wc -l)"x == "1"x ] ; then
			# 当DMI 不匹配时，如果AutoScanMode 为disable时，针对主办检查MAC号，如果为Card，直接跳过，检查MAC
			if [ "${ModelType}"x == "Card"x ] ; then
				local AutoScanMode="Card"
			else
				local AutoScanMode="disable"
			fi
			ReadSN=0
			#如果不是小卡類（機種名稱最後為字母）的,不從DMI讀SN,避免了使用帶SN的主板測試讀出的SN和PPID.TXT不一致而刪除測試記錄
			case ${FormatType} in
			PCBA)
				ReadSN=$(dmidecode -t2 -t2 2>/dev/null | grep -iw "Serial Number" | grep -iwc "${ReadPCBFrFile}" )
				;;
				
			BB)
				ReadSN=$(dmidecode -t1 -t2 2>/dev/null | grep -iw "Serial Number" | grep -iwc "${ReadPCBFrFile}" )
			;;
			esac

			if [ ${ReadSN} -ge 1 ] && [ "${ModelType}"x == "MB"x ] ; then
				#For System SN or BaseBoard SN is flashed.
				AutoScanPPID "enable"
				ScanPPIDs 2
			else
				# if [ ${CurProcVal} != 0 ] && [ $(ls "${WorkPath}" | grep -iEc "MAC[1-9]{1,3}.TXT") -gt 0 ]; then
				if [ ${CurProcVal} != 0 ] ; then
					case ${AutoScanProcLable} in
					number)
						# AutoScanProcVal is a number
						if [ ${AutoScanProcVal} -ge 1 ] && [ ${CurProcVal} -gt ${AutoScanProcVal} ] ; then
							AutoScanPPID "${AutoScanMode}"
							ScanPPIDs 2
						else
							ScanPPIDs 1
						fi
					;;
					
					shell)
						# AutoScanProcVal is a shell name
						if [ $(cat -v ../PPID/${ReadPCBFrFile}.log | grep -iw "${AutoScanProcVal}" | tr -d ' ' |grep -ic "TestPass") -ge 1 ] ; then
							AutoScanPPID "${AutoScanMode}"
							ScanPPIDs 2
						else
						# AutoScanProcVal is a shell name
							ScanPPIDs 1
						fi
					;;
					esac
				else
					#${CurProcVal} == 0
					ScanPPIDs 1
				fi
			fi
		else
			ScanPPIDs 1
		fi
	else
		ScanPPIDs 1
	fi
	if [ ! -s "${SavePath}/SN_MODEL_TABLE.TXT" ] ; then
		Process 1 "No such file or 0 KB size of file: ${SavePath}/SN_MODEL_TABLE.TXT"
		exit 2
	fi
	
	# Create serial number and model relational table
	#+------------------------+-------------------------------------------+
	#|       Model Name       |               Serial Number               |
	#+------------------------+-------------------------------------------+
	#|       S165B            |                T123456789                 |
	#+------------------------+-------------------------------------------+
	
	ShowTitle "Create serial number and model relational table"
	printf "%s\n" "+------------------------+-------------------------------------------+"
	printf "%-1s%-24s%-1s%-43s%-1s\n" "|" "       Model Name" "|" "               Serial Number" "|"
	printf "%s\n" "+------------------------+-------------------------------------------+"
	for line in  `cat -v "${SavePath}/SN_MODEL_TABLE.TXT" 2>/dev/null`
	do
		printf "%-1s%-24s%-1s" "|" "       ` echo $line | awk -F'|' '{print $2}' `" "|"
		printf "%-43s%-1s\n" "                ` echo $line | awk -F'|' '{print $1}' `" "|"
	done
	printf "%s\n" "+------------------------+-------------------------------------------+"

	cat -v ${SavePath}/SN_MODEL_TABLE.TXT 2>/dev/null | grep -v "#" | grep -v "^$" | head -n 1 | awk -F'|' '{print $1}' > ${SavePath}/PPID.TXT
	pcb=$(cat ${SavePath}/PPID.TXT  2> /dev/null)
	sync;sync;sync
	if [ ! -s "${SavePath}/PPID.TXT" ] ; then
		Process 1 "No such file or 0 KB size of file: ${SavePath}/PPID.TXT"
		exit 2
	fi

	[ ${ErrorFlag} != 0 ] && exit 1
	echo "${WorkPath}/${BaseName}.sh test pass ..."
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare ReadPCBFrFile=0
declare CurProcVal=0
declare FormatType='PCBA'
declare SavePath='../PPID'
declare Length=10 #eg.: H916168168, 10Bit
declare ModelNameList=()
declare XmlConfigFile sLength AutoScanProcVal
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
			printf "%-s\n" "SerialTest,ScanSerialNumber"
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
	
main 2>&1 | tee ${BaseName}.log
sync;sync;sync

cat -v "${BaseName}.log" 2>&1 | grep -iwq "Welcome to debug mode" && exit 9
cat -v "${BaseName}.log" 2>&1 | grep -iwq "${WorkPath}/${BaseName}.sh test pass" || exit 1

exit 0

