#!/bin/bash
#FileName : upload.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.4"
	local CreatedDate="2018-10-08"
	local UpdatedDate="2020-11-03"
	local Description="upload test pass message"
	
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
	printf "%16s%-s\n" "" "2019-01-18, Show the XML on the srceem"
	printf "%16s%-s\n" "" "2020-09-23, PE可以自定義上傳log路徑"
	printf "%16s%-s\n" "" "2020-11-03, 修正dhclient --timeout/-timeout都适用"
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
	ExtCmmds=(xmlstarlet mes)
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

ShowTitle()
{
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
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
		0 : upload pass
		1 : upload fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<UpLoad>
		<ProgramName>${BaseName}</ProgramName>	
		<StationCode>1528</StationCode>
		
		<!--測試log上傳路徑設置-->
		<UpLoadLog>				
			<FtpAddress>
				<FtpIP>20.40.1.41</FtpIP>
				<FtpDir>Testlog/SI</FtpDir>
			</FtpAddress>
				
			<LoginInfo>
				<Username>test</Username>
				<Password>test</Password>
			</LoginInfo>
		</UpLoadLog>
		
		<UrlAddress>
			<IndexInUse>1</IndexInUse>
			<NgLock index="1">http://20.40.1.40/EPS-Web/TestFail/GetInfo.ashx</NgLock>
			<NgLock index="2">http://172.17.7.101/EPS-Web/TestFail/GetInfo.ashx</NgLock>
			<MesWeb index="1">http://20.40.1.40/eps-web/upload/uploadservice.asmx</MesWeb>
			<MesWeb index="2">http://172.17.7.101/eps-web/upload/uploadservice.asmx</MesWeb>		
		</UrlAddress>
			
		<Model>
			<ForModel>609-S1651-02S</ForModel>
			<KeyWord>TPVER MODEL</KeyWord>
			<FileList>TPVER.TXT MODEL.TXT</FileList>
		</Model>
		
		<Model>
			<ForModel>609-S145A-020</ForModel>
			<KeyWord>BIOS TPVER MODEL</KeyWord>
			<FileList>BIOSVER.TXT TPVER.TXT MODEL.TXT</FileList>
		</Model>
		
		<FileListPath>/TestAP/PPID</FileListPath>		
	</UpLoad>
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
	FtpIP=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpAddress/FtpIP" -n "${XmlConfigFile}" 2>/dev/null)
	FtpDir=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpAddress/FtpDir" -n "${XmlConfigFile}" 2>/dev/null)
	Username=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/LoginInfo/Username" -n "${XmlConfigFile}" 2>/dev/null)
	Password=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/LoginInfo/Password" -n "${XmlConfigFile}" 2>/dev/null)
	SlotFtpIP=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotFtpIP" -n "${XmlConfigFile}" 2>/dev/null)
	SlotFtpDir=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotFtpDir" -n "${XmlConfigFile}" 2>/dev/null)
	SlotUsername=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotUsername" -n "${XmlConfigFile}" 2>/dev/null)
	SlotPassword=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotPassword" -n "${XmlConfigFile}" 2>/dev/null)
	SlotSCMFile=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotSCMFile" -n "${XmlConfigFile}" 2>/dev/null)
	SlotBoardFile=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotBoardFile" -n "${XmlConfigFile}" 2>/dev/null)
	SlotNodeFile=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UpLoadLog/FtpSlotAddress/SlotNodeFile" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#FtpIP} == 0 ] ; then
		Process 1 "Error setting : /UpLoad/UpLoadLog/FtpAddress/FtpIP"
		let ErrorFlag++
	fi

	if [ ${#FtpDir} == 0 ] ; then
		Process 1 "Error setting : /UpLoad/UpLoadLog/FtpAddress/FtpDir"
		let ErrorFlag++
	fi
	
	if [ ${#Username} == 0 ] ; then
		Process 1 "Error setting : /UpLoad/UpLoadLog/LoginInfo/Username"
		let ErrorFlag++
	fi
	
	if [ ${#Password} == 0 ] ; then
		Process 1 "Error setting : /UpLoad/UpLoadLog/LoginInfo/Password"
		let ErrorFlag++
	fi	
	
	[ ${ErrorFlag} != 0 ] && exit 3
	
	TEST_STATION=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/StationCode" -n "${XmlConfigFile}" 2>/dev/null)
	SlotNum=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/SlotNum" -n "${XmlConfigFile}" 2>/dev/null)
	PATH_DATA=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/FileListPath" -n "${XmlConfigFile}" 2>/dev/null)
	FileListPath=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/FileListPath" -n "${XmlConfigFile}" 2>/dev/null)
	IndexInUse=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UrlAddress/IndexInUse" -n "${XmlConfigFile}" 2>/dev/null)
	MesWebSite=$(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/UrlAddress/MesWeb[@index=${IndexInUse}]" -n "${XmlConfigFile}" 2>/dev/null)
	
	if [ ${#TEST_STATION} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

MountLogFTP ()
{
	local LogFTPIp=$1
	LogFTPIp=${LogFTPIp:-'20.40.1.41'}
	for ((cnt=0;cnt<3;cnt++))
	do
		#Mount the Log Server to /mnt/logs
		mkdir -p /mnt/logs
		mount -t cifs //${LogFTPIp}/${FtpDir}/ -o rw,username=${Username},password=${Password},vers=1.0  /mnt/logs/
		if [ "$?" == "0" ]; then
			Process 0 "Mount //${LogFTPIp}/${FtpDir}/"
			printf "%-10s%-60s\n" "" "Please wait a moment ..." 
			break
		else
			printf "%-10s%-60s\n" ""  " Try again, please wait a moment..."
			umount /mnt/logs/ >/dev/null 2>&1
			sleep 1
		fi
	done

	if [ ${cnt} == 3 ] ; then
		Process 1 "Mount //${LogFTPIp}/${FtpDir}/"
		umount /mnt/logs >/dev/null 2>&1
		sleep 1
		exit 1
	fi
	return 0
}

MountSlotLogFTP ()
{
	local LogFTPIp=$1
	LogFTPIp=${LogFTPIp:-'20.40.1.41'}
	for ((cnt=0;cnt<3;cnt++))
	do
		#Mount the Log Server to /mnt/Slotlogs
		mkdir -p /mnt/Slotlogs
		mount -t cifs //${LogFTPIp}/${SlotFtpDir}/ -o rw,username=${SlotUsername},password=${SlotPassword},vers=1.0  /mnt/Slotlogs/
		if [ "$?" == "0" ]; then
			Process 0 "Mount //${LogFTPIp}/${SlotFtpDir}/"
			printf "%-10s%-60s\n" "" "Please wait a moment ..." 
			break
		else
			printf "%-10s%-60s\n" ""  " Try again, please wait a moment..."
			umount /mnt/Slotlogs >/dev/null 2>&1
			sleep 1
		fi
	done

	if [ ${cnt} == 3 ] ; then
		Process 1 "Mount //${LogFTPIp}/${SlotFtpDir}/"
		umount /mnt/Slotlogs >/dev/null 2>&1
		sleep 1
		exit 1
	fi
	return 0
}

CheckKeyWord ()
{
	local ShowStdKW=0
	for ((k=0;k<${#KEY_WORD[@]};k++))
	do
		echo "${StdKeyWord[@]}" | grep -wq "${KEY_WORD[$k]}"
		if [ $? != 0 ] ; then
			Process 1 "${KEY_WORD[$k]} is an error key word ..."
			let ErrorFlag++
			let ShowStdKW++
		fi
	done

	if [ "${ErrorFlag}" != 0 ] ; then 
		[ ${ShowStdKW} != 0 ] && echo "The standard keyword: `echo "${StdKeyWord[@]}" | sed 's/ /,/g'`"
		return 1   
	fi
	  
	if [ ${#KEY_WORD[@]} != ${#FILE_LIST[@]} ] ; then 
		Process 1 "The amount of \"KEY_WORD\" do not match with \"FILE_LIST\" ..." 
		return 1
	fi

	return 0
}
 
CheckStationCode ()
{
	echo "${StdStationCode[@]}" | grep -wq "${TEST_STATION}" 2>/dev/null
	if [ $? != 0 ] ; then
		Process 1 "${TEST_STATION} is an error station code ..."
		printf "%-10s%-60s\n" "" "The standard code: `echo "${StdStationCode[@]}" | sed 's/ /,/g'`"
		let ErrorFlag++
		return 1   
	fi
}

CheckFilesList ()
{
	local FilesList=(`echo "PPID.TXT OPID.TXT FIXID.TXT ${FILE_LIST[@]}"`)
	for ((x=0;x<${#FilesList[@]};x++))
	do
		if [ $(cat -v "${FilesList[$x]}" 2>/dev/null | grep -iEc '[0-9A-Z]') == 0 ]; then
			Process 1 "No such file or 0 KB size of file: ${FilesList[$x]}"
			let ErrorFlag++
			continue 
		fi
	done

	if [ "$ErrorFlag" != 0 ] ; then
		return 1
	else
		return 0
	fi
}

#Check the format of key file  
CheckFormatOfFile ()
{
	local FileType=$(echo "$1" | tr "[a-z]" "[A-Z]" )
	local FileValue=$(cat -v "$2" 2>/dev/null)

	if [ ${#FileValue} == 0 ] ; then
		Process 1 "$2 is a null file, check $2 fail ..."
		return 1
	fi

	case ${FileType} in
		#PPID)
			#e.g.: H516060641,H5E0000176
		#	echo ${FileValue} | grep -qE '^[A-Z0-9][1-9A-C][0-9A-Z]{8}+$' 
		#	if [ $? != 0 ] ; then
		#		Process 1 "Check the format of $2(${FileValue}) fail ..."
		#		return 1
		#	fi  
		#;;

		OPID)
			while :
			do	
				#eg.: 00157193
				echo ${FileValue} | grep -Ewq '^[0-9]{8}+$' 
				if [ $? != 0 ] ; then
					Process 1 "Check the format of $2(${FileValue}) fail ..."
					if [ -f "../Scan/OPID.ini" ] ; then 
						cat ../Scan/OPID.ini 2>/dev/null | grep -iE "[0-9A-Z]" | tail -n1 >${WorkPath}/OPID.TXT 
						sync;sync;sync
						continue
					else
						return 1
					fi
				else
					break
				fi
			done
		;;

		FIXID)
			while :
			do
				#eg.: format exclude like：D8CB8A79C54D
				echo ${FileValue} | grep -vwEq '^[0-9A-Fa-f]{12}+$'
				if [ $? != 0 ] ; then
					Process 1 "Check the format of $2(${FileValue}) fail ..."
					if [ -f "../Scan/FIXID.ini" ] ; then
						cat ../Scan/FIXID.ini 2>/dev/null | grep -iE "[0-9A-Z]" | tail -n1 > ${WorkPath}/FIXID.TXT
						sync;sync;sync
						continue
					else
						return 1
					fi
				else
					break
				fi
			done
		;;

		MAC|BMC)
			#eg.: D8CB8A79C54D
			echo ${FileValue} | grep -iwEq '^[0-9A-F]{12}+$'
			if [ $? != 0 ] ; then
				Process 1 "Check the format of $2(${FileValue}) fail ..."
				return 1
			fi
		;;

		IFB_MAC)
			#eg.: D8CB8A79C54D4520
			echo ${FileValue} | grep -qE '^[0-9A-F]{16}+$'
			if [ $? != 0 ] ; then
				Process 1 "Check the format of $2(${FileValue}) fail ..."
				return 1
			fi
		;;	


		MODEL)
			#eg.: 609-S1761-010,709-S158-01S
			echo ${FileValue} | grep -q '[6-7]0[6-9]-[A-Z0-9]\{4,5\}-[A-Z0-9]\{3\}'
			if [ $? != 0 ] ; then
				Process 1 "Check the format of $2(${FileValue}) fail ..."
				return 1
			fi
		;;

		TPVER)
			for((i=0;i<999;i++))
			do
				[ ${i} -ge 10 ] && return 1
				#eg.: V4.1.0.4sl
				echo ${FileValue} | grep -q 'V[0-9]\.[0-9A-Za-z]\{1,3\}\.[0-9A-Za-z]\{1,3\}\.[0-9A-Za-z]\{1,3\}'
				if [ $? != 0 ] ; then
					Process 1 "Check the format of $2(${FileValue}) fail ..."
					echo "${APVersion}" > ${WorkPath}/TPVER.TXT
					sync;sync;sync
					continue
				else
					break
				fi
			done
		;;

		SSID|SVID)
			#eg.: 1462,0391
			echo ${FileValue} | grep -iqE '^[0-9A-Z]{4}-[0-9A-Z]{4}+$'
			TypeOne=$?

			echo ${FileValue} | grep -iqE '^[0-9A-Z]{4}+$'
			TypeTwo=$?
			
			let Type=${TypeOne}*${TypeTwo}
			if [ ${Type} != 0 ] ; then
				Process 1 "Check the format of $2(${FileValue}) fail ..."
				return 1
			fi
		;;

		SAS)
			#eg.: D8CB8A
			echo ${FileValue} | grep -E '^[0-9A-F]{8}+$' >/dev/null 2>&1
			if [ $? != 0 ] ; then
				Process 1 "Check the format of $2(${FileValue}) fail ..."
				return 1
			fi
		;;

		BIOS|BMC_REV1|BMC_REV2|REV|EMM_GROUPNO)
			:
		;;
		esac
		return 0
}

CheckFormatOfFilesList ()
{
	All_KEY_WORD=(`echo "PPID OPID FIXID ${KEY_WORD[@]}"`)
	All_FILE_LIST=(`echo "PPID.TXT OPID.TXT FIXID.TXT ${FILE_LIST[@]}"`)
	for ((w=0,v=0;w<${#All_KEY_WORD[@]},v<${#All_FILE_LIST[@]};w++,v++))
	do
		CheckFormatOfFile "${All_KEY_WORD[$w]}" "${All_FILE_LIST[$v]}"
		[ $? != 0 ] && let ErrorFlag++
	done

	if [ $ErrorFlag != 0 ] ; then 
		return 1
	else
		return 0
	fi
}

BackupSlotTestLog ()
{
	local sn=$1
	local SaveInFolder=$2
	SaveInFolder=${SaveInFolder:-"96D9"}
	# Backup Test Log Function
	#Usage: BackupTestLog SN Model IPAddress SlotFlag SlotSerial SlotNode

	local LogFTPIp=$3
	local SlotFlag=$4
	local SlotSerial=$5
	local SlotNode=$6
	LogFTPIp=${LogFTPIp:-'20.40.1.41'}
	case ${TEST_STATION} in
		1528)FLAG="FT";;
		2415)FLAG="EBT";;
		2597)FLAG="SCSI";;
		2937)FLAG="FT2";;
		1543)FLAG="PF";;
		1547)FLAG="BiT";;
		1545)FLAG="AF";;
		1655)FLAG="OQA";;
		1855)FLAG="OQA";;
		2515)FLAG="PT";;
		esac

	echo -e " Back up test Log ... "
	read text < ${PATH_DATA}${FILE_PPID}

	# e.g.:backup_log_name=FT_2017022018080808_H216263168_S368M0N_O81B273505_047C11223344.log
	# 格式为站别_时间_系统条码_主板条码_S368D_BMCMAC1_Node1
	CurYearMonth=$(date +%Y%m)
	CurYear=$(date +%Y)
	CurMonth=$(date +%m)
	LogFileName=${FLAG}_$(date "+%Y%m%d%H%M%S")_${sn}_${SlotSerial}_${SlotFlag}_${SlotNode}.log

	grep -iwq "This log file save in: //${LogFTPIp}/${SlotFtpDir}/${SaveInFolder}/${sn}"  ${WorkPath}/${pcb}.log 
	if [ $? != 0 ] ; then
		echo -e "\n\n This log file save in: //${LogFTPIp}/${SlotFtpDir}/${SaveInFolder}/${sn} " >> ${WorkPath}/${pcb}.log
		sync;sync;sync
	fi
	

	#If the SaveInFolder not found,then make it
	# 直接以条码来命名文件夹的名字，取消以年月的方式来进行创建
	[ ! -d "${BackupSlotLogPath}/${SaveInFolder}/${sn}" ] && mkdir -p  ${BackupSlotLogPath}/${SaveInFolder}/${sn} 2>/dev/null
	#Copy local log to FTP server
	cp -rf ${WorkPath}/${pcb}.log ${BackupSlotLogPath}/${SaveInFolder}/${sn}/${LogFileName} 2>/dev/null
	if [ $? -ne 0 ] ;then
		Process 1 "Back up test log of ${sn} to /mnt/Slotlogs/${SaveInFolder}/${sn}" 
		return 1
	else
		# Get the test record in this month and last month   
		# case ${CurMonth} in
		# 01)
		# 	LastYear=$(echo "obase=10; ibase=10; ${CurYear}-1" | bc)
		# 	LastMonth="12"
		# 	LastYearMonth=$(echo ${LastYear}${LastMonth})
		# ;;

		# 0[2-9]|10)
		# 	CurYear=$(echo ${CurYear})
		# 	LastMonth=$(echo "obase=10; ibase=10; ${CurMonth}-1" | bc)
		# 	LastYearMonth=$(echo ${CurYear}0${LastMonth})
		# ;;

		# *)
		# 	CurYear=$(echo ${CurYear})
		# 	LastMonth=$(echo "obase=10; ibase=10; ${CurMonth}-1" | bc)
		# 	LastYearMonth=$(echo ${CurYear}${LastMonth})
		# ;;
		# esac

		# ls -l /mnt/logs/${SaveInFolder}/${CurYearMonth} 2>/dev/null | grep -i ".*${CurYearMonth}.*_[A-Za-z0-9]\{10\}.log" | grep -v "Fail" > /.TestRecord_${SaveInFolder}.rcd
		# ls -l /mnt/logs/${SaveInFolder}/${LastYearMonth} 2>/dev/null | grep -i ".*${LastYearMonth}.*_[A-Za-z0-9]\{10\}.log" | grep -v "Fail"  >> /.TestRecord_${SaveInFolder}.rcd
		sync;sync;sync
		Process 0 "Back up test log of ${sn} to /mnt/Slotlogs/${SaveInFolder}/${sn}"
	fi	

	return 0
}

BackupTestLog ()
{
	local sn=$1
	local SaveInFolder=$2
	SaveInFolder=${SaveInFolder:-"96D9"}
	# Backup Test Log Function
	#Usage: BackupTestLog SN Model IPAddress

	local LogFTPIp=$3
	LogFTPIp=${LogFTPIp:-'20.40.1.41'}

	case ${TEST_STATION} in
		1528)FLAG="FT";;
		2415)FLAG="EBT";;
		2597)FLAG="SCSI";;
		2937)FLAG="FT2";;
		1543)FLAG="PF";;
		1547)FLAG="BiT";;
		1545)FLAG="AF";;
		1655)FLAG="OQA";;
		1855)FLAG="OQA";;
		2515)FLAG="PT";;
		esac

	echo -e " Back up test Log ... "
	read text < ${PATH_DATA}${FILE_PPID}

	# e.g.:backup_log_name=FT_2017022018080808_H216263168.log
	CurYearMonth=$(date +%Y%m)
	CurYear=$(date +%Y)
	CurMonth=$(date +%m)
	LogFileName=${FLAG}_$(date "+%Y%m%d%H%M%S")_${sn}.log

	grep -iwq "This log file save in: //${LogFTPIp}/${FtpDir}/${SaveInFolder}/${CurYearMonth}"  ${WorkPath}/${pcb}.log 
	if [ $? == 0 ] ; then
		echo -e "\n\n This log file save in: //${LogFTPIp}/${FtpDir}/${SaveInFolder}/${CurYearMonth} " >> ${WorkPath}/${pcb}.log
	fi
	sync;sync;sync

	#If the SaveInFolder not found,then make it
	[ ! -d "${BackupLogPath}/${SaveInFolder}/${CurYearMonth}" ] && mkdir -p  ${BackupLogPath}/${SaveInFolder}/${CurYearMonth} 2>/dev/null

	#Copy local log to FTP server
	cp -rf ${WorkPath}/${pcb}.log ${BackupLogPath}/${SaveInFolder}/${CurYearMonth}/${LogFileName} 2>/dev/null
	if [ $? -ne 0 ] ;then
		Process 1 "Back up test log of ${sn} to /mnt/logs/${SaveInFolder}/${CurYearMonth}" 
		return 1
	else
		# Get the test record in this month and last month   
		case ${CurMonth} in
		01)
			LastYear=$(echo "obase=10; ibase=10; ${CurYear}-1" | bc)
			LastMonth="12"
			LastYearMonth=$(echo ${LastYear}${LastMonth})
		;;

		0[2-9]|10)
			CurYear=$(echo ${CurYear})
			LastMonth=$(echo "obase=10; ibase=10; ${CurMonth}-1" | bc)
			LastYearMonth=$(echo ${CurYear}0${LastMonth})
		;;

		*)
			CurYear=$(echo ${CurYear})
			LastMonth=$(echo "obase=10; ibase=10; ${CurMonth}-1" | bc)
			LastYearMonth=$(echo ${CurYear}${LastMonth})
		;;
		esac

		ls -l /mnt/logs/${SaveInFolder}/${CurYearMonth} 2>/dev/null | grep -i ".*${CurYearMonth}.*_[A-Za-z0-9]\{10\}.log" | grep -v "Fail" > /.TestRecord_${SaveInFolder}.rcd
		ls -l /mnt/logs/${SaveInFolder}/${LastYearMonth} 2>/dev/null | grep -i ".*${LastYearMonth}.*_[A-Za-z0-9]\{10\}.log" | grep -v "Fail"  >> /.TestRecord_${SaveInFolder}.rcd
		sync;sync;sync
		Process 0 "Back up test log of ${sn} to /mnt/logs/${SaveInFolder}/${LastYearMonth}"
	fi	

	return 0
}

CreateXML()
{	
	local sn=$1
	local TEST_STATUS=$(echo "$2" | cut -c 1 | tr '[a-z]' '[A-Z]')
	local ERROR_CODE=$3
	# Usage: CreateXML SN
	# Create Test XML Function

	echo " Creating test XML... "
	XML_TEXT="<root>"

	# Write Test station 
	XML_TEXT=${XML_TEXT}"<TestStation>$TEST_STATION</TestStation>"

	# Write Test Machine
	read text < ${PATH_DATA}${FILE_FIXID}
	if [ -z "$text" ] ;then
		Process 1 "Read fixid failure ..."
		return 1
	fi

	XML_TEXT=${XML_TEXT}"<TestMachine>$text</TestMachine>"

	# Write Test OP ID
	read text < ${PATH_DATA}${FILE_OPID}
	if [ -z "$text" ] ;then
		Process 1 "Read OperID failure ..."
		return 1
	fi

	XML_TEXT=${XML_TEXT}"<Tester>$text</Tester>"

	# Write Test Barcode,# read text < ${PATH_DATA}$FILE_PPID
	text=${sn} 
	if [ -z "$text" ] ;then
		Process 1 "Read PPID failure ..."
		return 1
	fi
	XML_TEXT=${XML_TEXT}"<BarcodeNo>$text</BarcodeNo>"

	# Write Test Status
	XML_TEXT=${XML_TEXT}"<TestStatus>$TEST_STATUS</TestStatus>"

	# Write Customer
	XML_TEXT=${XML_TEXT}"<Customer></Customer>"

	# Write Test Time
	XML_TEXT=${XML_TEXT}"<TestTime>"$(date "+%Y-%m-%d %H:%M:%S")"</TestTime>"	

	# CMOS date and time
	while :
	do
		CMOSDT_val=$(date -d "`hwclock -r`" +%s)
		CMOSDT=$(date -d @${CMOSDT_val} +"%Y-%m-%d %H:%M:%S")
		[ "${#CMOSDT}" -gt 0 ] && break
	done	
	XML_TEXT=${XML_TEXT}"<CMOSTime>"${CMOSDT}"</CMOSTime>"

	# Write Test Info
	XML_TEXT=${XML_TEXT}"<TestInfo>"
	for ((i=0;i<${#KEY_WORD[@]};i=i+1))
	do
		read text < ${PATH_DATA}${FILE_LIST[$i]}
		if [ -z "$text" ] ;then
			Process 1 "Read ${KEY_WORD[$i]} failure ..."
			return 1
		fi
		
		if [ $i == 0 ] ; then
			# Write OS Version
			XML_TEXT=${XML_TEXT}"<TestItem Key=\"OS\">"$(uname -r)"</TestItem>"
		fi
		XML_TEXT=${XML_TEXT}"<TestItem Key=\"${KEY_WORD[$i]}\">$text</TestItem>"
		
	done

	XML_TEXT=${XML_TEXT}"</TestInfo>"

	# Write Ng Info
	XML_TEXT=${XML_TEXT}"<NgInfo>"
	XML_TEXT=${XML_TEXT}"<Errcode>$ERROR_CODE</Errcode>"
	XML_TEXT=${XML_TEXT}"<Pin></Pin><Local></Local>"
	XML_TEXT=${XML_TEXT}"</NgInfo>"
	XML_TEXT=${XML_TEXT}"</root>"

	echo "${XML_TEXT}" | xmlstarlet fo 
	Process $? "Create test XML of ${sn} ..." || exit 1
	return 0
}
# Create Test XML End

Backuplog2Local ()
{
	local Model=$1
	local sn=$2
	Model=${Model:-"SI_Moedl"}
	# Usage: Backuplog2Local Model SN
	#Back up Test log to local disk
	echo "${Model}" | grep -q '-'
	if [ $? == 0 ]; then
		Model=$(echo "${Model}" | awk -F'-' '{print $2}')
	fi

	local Name=$(echo "$(date "+%Y%m%d%H%M%S")_${sn}")
	mkdir -p  /."${Model}"/${Name} > /dev/null 2>&1
	cp -rf ${WorkPath}/${pcb}.log   /."${Model}"/${Name}/         > /dev/null 2>&1
	cp -rf ${WorkPath}/${pcb}.proc  /."${Model}"/${Name}/         > /dev/null 2>&1
	cp -rf ${WorkPath}/.procMD5     /."${Model}"/${Name}/procMD5  > /dev/null 2>&1
	for iFILE in ${FILE_LIST[@]}
	do
		cp -rf ${WorkPath}/${iFILE} /."${Model}"/${Name}/ > /dev/null 2>&1
	done

	cd /."${Model}"/ 2>/dev/null
	tar -zcvf ${Name}.tar.gz ${Name}/ >/dev/null 2>&1 
	rm -rf ${Name}/ 2>/dev/null
	cd ${WorkPath} 2>/dev/null
}

Wait4nSeconds ()
{
	local WaitTime=$1
	for ((p=${WaitTime:-5};p>0;p--))
	do   
		printf "\rPlug in lan cable ,press \e[1;33m[Y/y]\e[0m,time remaining: %02d seconds ...\e[0m" "${p}"
		read -s -t 1 -n1 Answer
		case ${Answer} in
		Y|y)
			 echo
			 break
		;;
			
		Q)
			# Ignoring  OP hit on Ctrl+C(2), Ctrl+/(3),Ctrl+Z(24), e.g.
			trap '-' INT QUIT TSTP HUP 
			echo
			echo -ne "\e[1;33mPress [Ctrl]+[C] to exit ...\e[0m"
			read -t 20
		 ;;
		 
		 *)
		 :
		 ;;
		esac
	done
	echo
} 

Connet2Server ()
{
	while :
	do
		ping ${IPAddress} -c 2 -w 3 2>/dev/null 
		if [ "$?" != "0" ] ; then 
			dhclient -r
			echo -e "\033[0;30;44m ********************************************************************** \033[0m"
			echo -e "\033[0;30;44m ***       Plug LAN cable in a LAN port to connect the server       *** \033[0m"
			echo -e "\033[0;30;44m ********************************************************************** \033[0m"  
			Wait4nSeconds 6 
			if [ $(dhclient --help 2>&1 | grep -wFc "[--timeout" ) == 1 ] ; then
				dhclient --timeout 5  >/dev/null 2>&1
			elif [ $(dhclient --help 2>&1 | grep -wFc "[-timeout" ) == 1 ] ; then
				dhclient -timeout 5 >/dev/null 2>&1
			else
				Process 1 "No argument 'timeout' for dhclient ..."
				exit 1
			fi		
		else
			break
		fi
		
	done
}


DefineKeyWord ()
{
	local IndexName=$1
	# Usage: DefineKeyWord Model
	KEY_WORD=($(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/Model[ForModel=\"${IndexName}\"]/KeyWord" -n "${XmlConfigFile}" 2>/dev/null))
	FILE_LIST=($(xmlstarlet sel -t -v "//UpLoad[ProgramName=\"${BaseName}\"]/Model[ForModel=\"${IndexName}\"]/FileList" -n "${XmlConfigFile}" 2>/dev/null))
	if [ ${#KEY_WORD[@]} == 0 ] || [ ${#FILE_LIST[@]} == 0 ] ; then
		Process 1 "Do not support the model name: ${IndexName}"
		return 1
	else
		return 0
	fi
}

main ()
{
	IPAddress=${FtpIP:-"20.40.1.41"}
	SlotIPAddress=${SlotFtpIP:-"20.40.1.41"}
	#IPAddress=$(echo $MesWebSite | awk -F'/' '{print $3}')

	if [ $(echo "${PATH_DATA}" | awk -F'/' '{print $NF}' | grep -iEc "[0-9A-Z]") != 0 ] ; then
		PATH_DATA=$(echo "${PATH_DATA}/")
	fi

	echo -e "\033[1;33m Upload test result to the MES ... \033[0m"

	#VER is Version of program,Show the test program version and chksum
	printf "%-s\n" "Upload.sh program, md5sum: `md5sum "${ShellFile}" | awk '{print $1}'`"	

	#Check the Station code is valid
	CheckStationCode ${TEST_STATION}

	# Get all test result
	TestResult=($(cat -v TestResult.txt 2>/dev/null))
	if [ ${#TestResult[@]} == 0 ] ; then
		Process 1 "Function test unfinished yet ..."
		exit 1
	fi
	
	# Step 1 check all data are OK
	for ((t=0;t<${#TestResult[@]};t++))
	do
		SerialNumber=$(echo ${TestResult[$t]} | awk -F'|' '{print $1}')
		ModelName=$(echo ${TestResult[$t]}  | awk -F'|' '{print $2}')
		TestResultFlag=$(echo ${TestResult[$t]}  | awk -F'|' '{print $3}')
		ErrorCode=$(echo ${TestResult[$t]}  | awk -F'|' '{print $4}')  # Fail的時候TestResult.txt存有ErrorCode，pass的情形則沒有
			
		[ ! -z "${ModelName}" ] && echo "${ModelName}" > MODEL.TXT
		sync;sync;sync
		
		# Define and check the keyword,key file;if the model is not support ,then skip it
		if [ ${#ErrorCode} == 0 ] ; then
			DefineKeyWord ${ModelName} 
		else
			DefineKeyWord "Failure" 
		fi
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			continue 		
		fi
		
		CheckKeyWord
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			continue 		
		fi
		
		CheckFilesList  
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			continue 		
		fi
		
		CheckFormatOfFilesList  
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			continue 		
		fi 	
		
		# Create Test XML and check it
		CreateXML ${SerialNumber} ${TestResultFlag} ${ErrorCode} >/dev/null
		[ "${t}"x == "0"x ] && echo -e '\n----------------------------------------------------------------------'
		echo ${XML_TEXT} | xmlstarlet fo
		echo -e '----------------------------------------------------------------------\n'
		sleep 1.5
	done

	[ ${ErrorFlag} -ne 0 ] && exit 1

	# Auto link server,network_segment=172(172.17.x.x),or 20(20.40.x.x)
	Connet2Server

	# mount the FTP to /mnt/logs
	# MountLogFTP ${FtpIP} 2>/dev/null
	MountSlotLogFTP ${SlotFtpIP} 2>/dev/null

	# Serial Number   Model Name     Backup Log   Create XML   Upload MES 
	#----------------------------------------------------------------------
	# H123456789     609-S1561-010     Pass         Pass          Pass
	# H123456789     609-S1561-010     Pass         Pass          Fail
	# H123456789     609-S1561-010     Pass         Fail          ----
	# H123456789     609-S1561-010     Fail         ----          ----
	#----------------------------------------------------------------------

	ShowTitle "Backup the Test Log and Upload to the MES"
	printf "%-17s%-15s%-13s%-13s%-12s\n"  "Serial Number" "Model Name" "Backup Log" "Create XML" "Upload MES"
	echo "----------------------------------------------------------------------"
	## Step 2 upload test result to MES
	for ((t=0;t<${#TestResult[@]};t++))
	do
		SerialNumber=$(echo ${TestResult[$t]} | awk -F'|' '{print $1}')
		ModelName=$(echo ${TestResult[$t]}  | awk -F'|' '{print $2}')
		TestResultFlag=$(echo ${TestResult[$t]}  | awk -F'|' '{print $3}')
		ErrorCode=$(echo ${TestResult[$t]}  | awk -F'|' '{print $4}')
		
		[ ! -z "${ModelName}" ] && echo "${ModelName}" > MODEL.TXT
		sync;sync;sync
		
		# Backup Log,MidModelName is the logs where store in FTP,e.g.: MidModelName=S1761
		MidModelName=$(echo ${ModelName} | tr -d ' ' | awk -F'-' '{print $2}')
		MidModelName=${MidModelName:-'96D9'}

		if [ ${#ErrorCode} == 0 ] ; then
			DefineKeyWord ${ModelName} 
		else
			DefineKeyWord "Failure" 
		fi
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			continue 		
		fi
		
		printf "%-16s%-18s" " ${SerialNumber}" "${ModelName}"
		local SlotSCMFlag=$(cat -v ${SlotSCMFile} | tr -d ' ')
		if [ ${#SlotSCMFlag} == 0 ];then
			Process 1 "SlotSCMFlag is empty, please check!"
			exit 1
		fi
		local SlotBoardSerial=$(cat -v ${SlotBoardFile} | tr -d ' ')
		if [ ${#SlotBoardSerial} == 0 ];then
			Process 1 "SlotBoardSerial is empty, please check!"
			exit 1
		fi
		local SlotNodeId=$(cat -v ${SlotNodeFile} | tr -d ' ')
		if [ ${#SlotNodeId} == 0 ];then
			Process 1 "SlotNodeId is empty, please check!"
			exit 1
		fi
		BackupSlotTestLog ${SerialNumber} ${MidModelName} ${SlotIPAddress} ${SlotSCMFlag} ${SlotBoardSerial} ${SlotNodeId} 1>/dev/null
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			printf "\e[31m%-13s\e[0m%-14s%-9s\n" "Fail" "----" "----"
			continue
		else
			printf "\e[32m%-13s\e[0m" "Pass"
		fi
		echo	
		# Back up Test log to local disk
		Backuplog2Local ${ModelName} ${SerialNumber} ${SlotIPAddress}
		# 检查测试log数量是否足够，如果足够则开始上传并将所有log 拷贝到制定服务器上
		python3 -u log_analyze.py ${BackupSlotLogPath} ${MidModelName} ${SerialNumber} ${SlotNum} ${MesWebSite}
		log_analyze_res=$?
		# FinishSlotNum=$(ls -l ${BackupSlotLogPath}/${MidModelName}/${SerialNumber} | sort -u | grep -iE "${SerialNumber}" | awk -F "_" '{print $NF}' | sort -u | grep -ivc "^$")
		if [ "${log_analyze_res}" == "0" ]; then
		# if [ ${FinishSlotNum} -eq ${SlotNum} ]; then
			MountLogFTP ${FtpIP} 2>/dev/null
			CurYearMonth=$(date +%Y%m)
			local new_folder="$(date "+%Y%m%d%H%M%S")_${SerialNumber}" 
			[ ! -d "${BackupLogPath}/${MidModelName}/${CurYearMonth}" ] && mkdir -p  ${BackupLogPath}/${MidModelName}/${CurYearMonth} 2>/dev/null 
			# [ ! -d "//${FtpIP}/${FtpDir}/${ModelName}/${CurYearMonth}" ] && mkdir -p  //${FtpIP}/${FtpDir}/${ModelName}/${CurYearMonth} 2>/dev/null
			cp -rf ${BackupSlotLogPath}/${MidModelName}/${SerialNumber} ${BackupLogPath}/${MidModelName}/${CurYearMonth}/${new_folder} 2>/dev/null
			if [ $? -ne 0 ] ;then
				Process 1 "Back up test log of ${SerialNumber} from /mnt/Slotlogs/${MidModelName}/${SerialNumber} to /mnt/logs/${MidModelName}/${new_folder}" 
				return 1
			else
				[ -d "${BackupSlotLogPath}/${MidModelName}/${SerialNumber}" ] && rm -rf "${BackupSlotLogPath}/${MidModelName}/${SerialNumber}" 2>/dev/null
				sync;sync;sync
				Process 0 "Back up test log of ${SerialNumber} from /mnt/Slotlogs/${MidModelName}/${SerialNumber} to /mnt/logs/${MidModelName}/${new_folder}"
			fi
		elif [ "${log_analyze_res}" == "2" ]; then
		# elif [ ${FinishSlotNum} -lt ${SlotNum} ]; then
			UploadResult[$t]=$(echo "OK, ${SerialNumber}, ${ModelName} upload skip")
			echo
			echo -e "\e[1;32m ***       该模块已经测试PASS，但是还需等待其他模块都测试PASS，才能进行上传，请做好标记区分       *** \e[0m"
			continue
		else
			Process 1 "该系统实际上传log 解析报错,请检查报错信息！"
			exit 1
		fi
		# Create Test XML 
		CreateXML ${SerialNumber} ${TestResultFlag} ${ErrorCode} >/dev/null
		if [ $? -ne 0 ] ; then
			let ErrorFlag++
			# printf "\e[31m%-14s\e[0ms%-9s\n" "Fail" "----"
			Process 1 "${SerialNumber} Creat XML"
			continue 
		else
			# printf "\e[32m%-14s\e[0m" "Pass"
			Process 0 "${SerialNumber} Creat XML"
		fi
		
		if [ $(echo "${TestResultFlag}" | grep -ic "Pass\|OK\|FAIL\|Failure") -ge 1 ] ; then
			
			rm -rf .UploadMesResult.log 2>/dev/null
			mes "${MesWebSite}" 1 "sXML=${XML_TEXT}" > .UploadMesResult.log
			cat -v .UploadMesResult.log | grep -iq "[0-9A-Z]"
			if [ $? -ne 0 ] ;then
				# printf "\e[31m%-9s\e[0m\n"  "Fail"
				Process 1 "${SerialNumber} Upload MES"
				let ErrorFlag++
			else
				UploadMesResult=$(cat -v .UploadMesResult.log | grep -v "=" | head -n1 | tr -d "^M")
				if [ $(echo ${UploadMesResult} | grep -ic "OK") -ge "1" ] ; then
					# printf "\e[32m%-9s\e[0m\n" "Pass"
					Process 0 "${SerialNumber} Upload MES"
					if [ $(echo "${TestResultFlag}" | grep -iwc "Fail") -ge 1 ] ; then
						#Fail 上傳顯示OK，但程式退出應該為fail
						UploadResult[$t]=$(echo "NG upload, ${SerialNumber}, ${ModelName} upload pass")
						let ErrorFlag++
					else
						UploadResult[$t]=$(echo "OK, ${SerialNumber}, ${ModelName} upload pass")
					fi
				else
					UploadResult[$t]=$(echo "${SerialNumber}, ${ModelName} upload fail: ${UploadMesResult}")
					# printf "\e[31m%-9s\e[0m\n" "Fail"
					Process 1 "${SerialNumber} Upload MES"
					let ErrorFlag++
				fi			
			fi
		fi	
	done 
	echo "----------------------------------------------------------------------"
	echo
	# merge the test record in a file: /.TestRecord.rcd
	cat -v /.TestRecord_*.rcd | sort -u  > /.TestRecord.rcd

	if [ "${ErrorFlag}A" != "0"A ] ; then
		echo -e "\033[1;33mThe detail of upload the MES: \033[0m"
		echo -e "\033[0;33m==============================================================================\033[0m"
	fi
	
	# /TestAP/PPID/Upload-Result.log: for check the upload result
	rm -rf Upload-Result.log 2>/dev/null

	for ((t=0;t<${#TestResult[@]};t++))
	do
		# Show the failure message only
		if [ $(echo ${UploadResult[$t]} | grep -ic 'OK' ) -ge "1" ] ; then 
			echo -e "\e[1;32m[$(($t+1))] ${UploadResult[$t]}\e[0m" >> Upload-Result.log
		else
			echo -e "\e[1;31m[$(($t+1))] ${UploadResult[$t]}\e[0m" | tee -a Upload-Result.log
		fi
		sync;sync;sync
	done
	
	if [ "${ErrorFlag}A" != "0"A ] ; then
		echo -e "\033[0;33m==============================================================================\033[0m"
		echo -e "\033[0;33m==============================================================================\033[0m"
	fi
	umount /mnt/logs/ >/dev/null 2>&1
	umount /mnt/Slotlogs/ >/dev/null 2>&1

	[ ${ErrorFlag} -ne 0 ] && exit 1
	exit 0
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile
declare TEST_STATION PATH_DATA KEY_WORD FILE_LIST ERROR_CODE 
declare FILE_PPID="PPID.TXT"
declare FILE_OPID="OPID.TXT"
declare FILE_FIXID="FIXID.TXT"
declare BackupLogPath=/mnt/logs
declare BackupSlotLogPath=/mnt/Slotlogs
declare XML_TEXT=""
declare LogFileName=${WorkPath}/${pcb}.log
declare MesWebSite IPAddress FtpIP FtpDir Username Password
declare SlotIPAddress SlotFtpIP SlotFtpDir SlotUsername SlotPassword SlotSCMFile SlotNum SlotBoardFile SlotNodeFile
declare SerialNumber ModelName TestResult MidModelName ApVersion
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

#------------------------------------------------------------
# FT service commonly used key words,match case!!
	#       MAC  : LAN MAC
	#       BMC  : BMC MAC
	#     MODEL  : Model name,e.g.: 609-S1681-010
	#      BIOS  : BIOS version,e.g.:ES168IMS.100
	#  BMC_REV1  : Revision of BMC,e.g.: S165K131.ima
	#  BMC_REV2  : Revision of BMC
	#     TPVER  : TestAP version,e.g.:V4.1.0.0sl
	#      SSID  : Service Set Identifier
	#      SVID  : Subsystem Vendor ID
	#       SAS  : SAS Address
	#       REV  : Revision of others
	#   IFB_MAC  : UID MAC address,like S125B
	#    MBPPID  : Mother Board PPID
	#   SYS_REV  : Revision of System 
	#   SDR_REV  : Revision of SDR
	#EMM_GROUPNO : Equipment group number
	# You can also define the key word
#------------------------------------------------------------
# Test Station code
	# 1528 : Function Test
	# 2415 : EBT,Burn in in Test after function test
	# 2597 : SCSI,AC OFF/ON,DC OFF/ON
	# 2937 : FT2,Function Test2
	# 2015 : High Voltage Test
	# 1543 : Pretest
	# 1547 : Burn In Test
	# 1545 : After test
	# 1655 : OQA CHECK
	# 1855 : ASSY OQA
	# 2515 ：Pack Test
#------------------------------------------------------------
# Warning!!Do not modify this information
declare StdKeyWord=(MAC BMC MODEL BIOS BMC_REV1 BMC_REV2 TPVER SSID SVID SAS REV MBPPID SYS_REV SDR_REV IFB_MAC FAIL EMM_GROUPNO)
declare StdStationCode=(1528 2415 2597 2937 2015 1543 1547 1545 1655 1855 2515)

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
			printf "%-s\n" "SerialTest,uploadTestToMES"
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
