#!/bin/bash
#FileName : ScanPPID.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.1"
	local CreatedDate="2018-07-10"
	local UpdatedDate="2019-06-27"
	local Description="Scan main board serial number and save in file PPID.TXT"
	
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
	printf "%16s%-s\n" "" "2019-06-27,Add the tool: scanner for forbidden keyboard input"
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
		0 : Scan main board serial number pass
		1 : Scan main board serial number fail
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
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			
			<!--ScanPPID.sh: 批量測試時-->
			<ModelName>S165B</ModelName>
			
			<!-- While the value file $pcb.proc are great than AutoScanProcVal,the PPID will auto scan in -->
			<!-- AutoScanProcVal == 0 ,scan PPID by manual, you can also input a shell name instead,eg.: lan_c.sh -->
			<!--設置自動掃描開始項目，可以填寫數字或測試項目-->
			<AutoScanProcVal>10</AutoScanProcVal>
			
			<!-- ScanPPID.sh: Length=0表示no limited -->
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
	
	# Get the information from the config file
	ModelName=$(xmlstarlet sel -t -v "//Scan/TestCase[ProgramName=\"${BaseName}\"]/ModelName" -n "${XmlConfigFile}" 2>/dev/null)
	ModelName=${ModelName:-"609-Sxxxx-0x0"}
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
	case $FormatType in
		PCBA)
			String="PCBA"
			egPPID=$(echo 'H916168168168168168168168168' | cut -c 1-$Length)
		;;
		
		BB)
			String="Chassis"
			egPPID=$(echo 'H9E0068168168168168168168168' | cut -c 1-$Length)

		;;
		
		*)
			Process 1 "Invalid parameter: $FormatType, it should be: PCBA or BB"
			exit 3
		;;
		esac
		

	while :
	do
		BeepRemind 0
		PrintfTip "Please scan ${sLength}-bit serial number, eg.: $egPPID" 2>/dev/null
		echo -ne "Scan ${sLength}-bit \e[1;31m$ModelName $String\e[0m serial number: __________\b\b\b\b\b\b\b\b\b\b"
		which scanner >/dev/null 2>&1
		if [ $? == 0 ] ; then
			rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
			scanner ${WorkPath}/scan_${BaseName}.txt || continue
			read pcb<${WorkPath}/scan_${BaseName}.txt
			rm -rf ${WorkPath}/scan_${BaseName}.txt >/dev/null 2>&1
		else
			read pcb
		fi
		
		if [ $(echo "${pcb}" | grep -ic "qqt\|pe\|qt\pte" ) == 1  ] ; then
			# Enter debug mode,because of "trap" command
			echo -e "\e[0;30;46m ******************************************************************* \e[0m"	
			echo -e "\e[0;30;46m ***                   Welcome to debug mode !                   *** \e[0m"	
			echo -e "\e[0;30;46m ******************************************************************* \e[0m"	
			exit 9
		else
			# The month is 1~12(1~10,A,B,C)
			if [ "${Length}"x == "0"x ] || [ ${#Length} == 0 ] ; then
				echo ${pcb} | grep -E "^[0-9A-Za-z]{1,50}" | grep -v "$egPPID" | cut -c 2 | grep -Eq "[1-9A-Ca-c]"
			else
				echo ${pcb} | grep -E "^[0-9A-Za-z]{${Length}}+$" | grep -v "$egPPID" | cut -c 2 | grep -Eq "[1-9A-Ca-c]"
			fi
		fi
	 
		if [ "$?" == "0" ] ; then
			case ${FormatType} in
				BB)
					echo ${pcb} | cut -c 3 | grep -Eq '^[A-Za-z]'
					if [ "$?" != "0" ] ; then
						Process 1 "Invalid PPID: $pcb (${#pcb} bit)"
						ThirdChar=$(echo ${pcb} | cut -c 3 )
						echo -e "          Current 3rd char of PPID is invalid: \e[1;31m${ThirdChar}\e[0m"
						printf "%-10s%-60s\n" "" "Try again ... "
						echo
						continue
					fi
				;;  

				*)
					:	
				;;
				esac

		else
			Process 1 "Invalid PPID: $pcb `[ ${#pcb}x != ${Length}x ] && echo "(${#pcb} Bit)"`"
			MonthInfo=$(echo ${pcb} | cut -c 2 | grep -E "[1-9A-Ca-c]" )
			[ ${#MonthInfo} == 0 ] && echo -e "Current 2nd char(the information of month) of PPID is invalid: \e[1;31m${pcb:1:1}\e[0m"
			echo "Try again ... "
			echo
			continue
		fi
		
		pcb=$(echo ${pcb} | cut -c 1-$Length | tr [a-z] [A-Z])
		echo "$pcb" > ${SavePath}/PPID.TXT
		if [ ! -s "${SavePath}/SN_MODEL_TABLE.TXT" ] ; then
			echo "$pcb|${ModelName}" > ${SavePath}/SN_MODEL_TABLE.TXT
		fi
		sync;sync;sync
		if [ $(cat "${SavePath}/PPID.TXT" | grep -iEc "[0-9A-Z]") == 1 ]  ; then
			echoPass "PPID: $pcb, write to: $SavePath/PPID.TXT"
			break
		else
			echoFail "Invalid file(0KB): $SavePath/PPID.TXT"
			echo "Try again ... "
			echo
		fi
	done

	exit 0
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

AutoScanPPID () 
{
	if [ -s "${SavePath}/PPID.TXT" ] ; then
		TempPCB=$(cat "${SavePath}/PPID.TXT")
	else
		Process 1 "Invalid file: ${SavePath}/PPID.TXT"
		exit 2
	fi

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
		ScanPPID
	fi

	echo
	echoPass "PPID: $pcb, read from: $SavePath/PPID.TXT"
	exit 0
}
# End of AutoScanPPID

Wait4nSeconds()
 {
	local sec=$1
	sec=${sec:-'3'}
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do   
		echo -ne "\e[1;33m`printf "\rAfter %02d seconds will auto continue ...\n" "${p}"`\e[0m"
		read -t1 -n1 Ans
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
	printf "\e[1m%-4s%-16s%-6s%-16s%-16s%-5s\n\e[0m" " No " "   File  type   " " " "     Amount     "  " "  "Result?"
	echo -e "----------------------------------------------------------------------"

	DeleteLog=(txt~ log~ sh~ sh.bak txt.bak swo swp log txt proc)
	for((d=0;d<${#DeleteLog[@]};d++))
	do	
		let D=$d+1
		if [ $D -le 9 ] ; then
			D="0$D"
		fi

		AllRecordFiles=($(find .. -type f -iname *.${DeleteLog[$d]} -print 2>/dev/null | grep -iE "*.${DeleteLog[$d]}+$" | grep -iv "readme\|AMI"  ))
		rm -rf "${AllRecordFiles[@]}" >/dev/null 2>&1
		if [ ${#AllRecordFiles[@]} != 0 ] ; then
			printf "%-4s%-17s%-11s%-16s%-10s\e[1;32m%-5s\n\e[0m" " $D " "    *.${DeleteLog[$d]}    " " " "  ${#AllRecordFiles[@]}  "  " "  "Deleted" 
		else
			printf "%-4s%-17s%-11s%-16s%-10s\e[1m%-5s\n\e[0m" " $D " "    *.${DeleteLog[$d]}    " " " "  ${#AllRecordFiles[@]}  "  " "  "   -   "

		fi
	done
	echo -e "----------------------------------------------------------------------"
	echo
	Process 0 "All test record file(~ sh.bak txt.bak swo swp log txt) are deleted"

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


	if [ -s "${SavePath}/PPID.TXT" ] ; then
		ReadPCBFrFile=$(cat "${SavePath}/PPID.TXT")
		CurProcVal=$(cat ../${ReadPCBFrFile}.proc 2>/dev/null | head -n1 )
		if [ ${#CurProcVal} == 0 ] ; then
			ScanPPID
		else
			echo ${AutoScanProcVal} | tr -d ' ' | grep -iq '.sh$'
			if [ $? != 0 ]; then
				# AutoScanProcVal is a number
				if [ ${AutoScanProcVal} -ge 1 ] && [ ${AutoScanProcVal} -le ${CurProcVal} ] ; then
					AutoScanPPID
				else
					ScanPPID
				fi
			else
				# AutoScanProcVal is a shell name
				if [ $(cat -v ../${ReadPCBFrFile}.log | grep -iw "${AutoScanProcVal}" | tr -d ' ' |grep -ic "TestPass") -ge 1 ] ; then
					AutoScanPPID
				else
					ScanPPID
				fi
			
			fi
		fi
	else
		ScanPPID
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile Length SavePath FormatType AutoScanProcVal sLength
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
			printf "%-s\n" "SerialTest,ScanPPID"
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

