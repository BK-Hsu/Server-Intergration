#!/bin/bash
#FileName : DelLog.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.2"
	local CreatedDate="2018-07-11"
	local UpdatedDate="2020-09-07"
	local Description="Delete test record and the other file"
	
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
	printf "%16s%-s\n" "" "2020-09-07, Add FIXID.ini,OPID.ini in list"
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
	#Usage: BeepRemind Arg1
	local Status="$1"
	# load pc speaker driver
	lsmod | grep -iq "pcspkr" || modprobe pcspkr
	which beep >/dev/null 2>&1 || return 0

	case ${Status:-"0"} in
		0)beep -f 1800 > /dev/null 2>&1;;
		*)beep -f 800 -l 800 > /dev/null 2>&1;;
		esac
}

Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` -x lConfig.xml [-DV]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	
	-D : Dump the sample xml config file
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
	
	return code:
		0 : Delete logs  pass
		1 : Delete logs  fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<DeleteLog>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NULL</ErrorCode>
			
			<!-- DelLog.sh, will delete all logs when 'DelayTime' equal to zero -->
			<DelayTime>9</DelayTime>
			<!--搜索路径深度-->
			<MaxDepth>2</MaxDepth>
			
			<!-- 上一级路径下的指定深度路径如下格式的文件將全部被刪除 -->
			<FileType>txt~ log~ sh~ sh.bak txt.bak swo swp log txt proc tmp</FileType>
		</TestCase>
	</DeleteLog>
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

#--->Get the parameters from the XML config file
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
		Process 1 "Thers's no configuration information for ${BaseName}.sh"
		exit 3
	fi
	
	# Get the information from the config file(*.xml)
	DelayTime=$(xmlstarlet sel -t -v "//DeleteLog/TestCase[ProgramName=\"${BaseName}\"]/DelayTime" -n "${XmlConfigFile}" 2>/dev/null)
	MaxDepth=$(xmlstarlet sel -t -v "//DeleteLog/TestCase[ProgramName=\"${BaseName}\"]/MaxDepth" -n "${XmlConfigFile}" 2>/dev/null)
	DeleteLog=($(xmlstarlet sel -t -v "//DeleteLog/TestCase[ProgramName=\"${BaseName}\"]/FileType" -n "${XmlConfigFile}" 2>/dev/null))

	if [ ${#DelayTime} == 0 ] || [ ${#MaxDepth} == 0 ]|| [ ${#DeleteLog} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

GenerateErrorCode()
{
	[ "${#pcb}" == "0" ] && return 0

	cd ${WorkPath} >/dev/null 2>&1 
	local ErrorCodeFile='../PPID/ErrorCode.TXT'
	local ErrorCode=$(xmlstarlet sel -t -v "//DeleteLog/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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

Wait4nSeconds()
 {
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec:-"3"};p>=0;p--))
	do   
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -s -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			[ "$Ans" == "Q" ] && printf "\nSkip out delete log program ...\n" && exit 5
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
	local TargetPath='..'
	local LocalLog='/.LocalLog'
	local SN=$(cat -v /TestAP/PPID/PPID.TXT 2>/dev/null | head -n1 )
	SN=${SN:-"H916168168"}
	local LogName=$(echo "$(date "+%Y%m%d%H%M%S")_${SN}")
	[ ! -d "${LocalLog}" ] && mkdir -p "${LocalLog}" 2>/dev/null
	mkdir -p "${LocalLog}"/${LogName} > /dev/null 2>&1

	cp -rf ${TargetPath}/${SN}.log   "${LocalLog}"/${LogName}  > /dev/null 2>&1
	cp -rf ${TargetPath}/${SN}.proc  "${LocalLog}"/${LogName} > /dev/null 2>&1
	cp -rf ${TargetPath}/.procMD5    "${LocalLog}"/${LogName}/procMD5 > /dev/null 2>&1
	 
	find ../PPID/ -type f -iname "*.txt" -maxdepth ${MaxDepth:-"2"} -print 2>/dev/null | xargs -n1 -I {} cp -rf {}  "${LocalLog}"/${LogName}

	cd "${LocalLog}"
	tar -zcvf ${LogName}_part.tar.gz ${LogName}/ >/dev/null 2>&1
	if [ $? != 0 ] ;then
		Process 1 "Back up ${LogName}_part.tar.gz"
	fi 	
	rm -rf ${LogName} >/dev/null 2>&1
	cd ${WorkPath}
}  

main ()
{
	DelayTime=${DelayTime:-'0'}
	printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
	printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "Warning: all test log files will be deleted after $DelayTime secondes"  "** "
	printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
	Wait4nSeconds $DelayTime
	BackupLog2Local

	# Must reboot the system after write MAC address
	rm -rf /etc/udev/rules.d/70-persistent-net.rules
	rm -rf /etc/sysconfig/network-scripts/ifcfg-eth[0-99] 2>/dev/null

	#   No   File  type              Amount                     Result?
	# ----------------------------------------------------------------------
	#   01    *.txt~                    0                          -   
	#   02    *.log~                    0                          -   
	#   03    *.sh~                     0                          -   
	#   04    *.sh.bak                  0                          -   
	#   05    *.txt.bak                 0                          -   
	#   06    *.swo                     0                          -   
	#   07    *.swp                     0                          -   
	#   08    *.log                     0                          -   
	#   09    *.txt                     0                          -   
	#   10    *.proc                    0                          -   
	#   11    *.tmp                     0                          -   
	# ----------------------------------------------------------------------

	echo
	echo -e "\e[1m Search the test record and clear the files ... \e[0m"
	printf "\e[1m%-7s%-24s%-27s%-12s\e[0m\n" "  No" " File  type " "Amount"  "Result?"
	echo -e "----------------------------------------------------------------------"

	if [ ${#XmlConfigFile} == 0 ] ; then
		DeleteLog=(txt~ log~ sh~ sh.bak txt.bak swo swp log txt proc tmp)
	fi
	local printEnter=0
	for((d=0;d<${#DeleteLog[@]};d++))
	do	
		AllRecordFiles=($(find ..  -maxdepth ${MaxDepth:-"2"} -type f -iname "*.${DeleteLog[$d]}" -print 2>/dev/null | grep -iE "*.${DeleteLog[$d]}+$" | grep -iv "readme\|AMI"  ))
		rm -rf "${AllRecordFiles[@]}" >/dev/null 2>&1
		if [ ${#AllRecordFiles[@]} != 0 ] ; then
			if [ ${printEnter} == 1 ] ; then		
				echo
			fi

			printf "%-2s%02d%-30s%-24s\e[1;32m%-9s\n\e[0m" "" "$((d+1))" "    *.${DeleteLog[$d]}" "${#AllRecordFiles[@]}"  "Deleted" 
		else
			printf "\r%-2s%02d%-30s%-24s\e[1m%-9s\e[0m"    "" "$((d+1))" "    *.${DeleteLog[$d]}" "${#AllRecordFiles[@]}"  "   -   "
			sleep 0.05
			[ ${d} == $((${#DeleteLog[@]}-1)) ] && echo
			printEnter=1
		fi
	done

	#2023-02-28 删除log时，检查并删除time_stamp.sh 进程
	ps -ax |grep -v "awk" | awk '/time_stamp.sh/{print $1}'| while read PID
	do
		kill -9 "$PID" >& /dev/null
	done
	
	rm -rf ../*.ini  2>/dev/null
	rm -rf ../.procMD5  2>/dev/null
	rm -rf ../PPID/*.ini  2>/dev/null
	rm -rf ../PPID/.ParalleFinishflag 2>/dev/null	
	rm -rf /TestAP/Test/logs/.procMD5 2>/dev/null
	rm -rf /TestAP/Test/logs/*.proc	2>/dev/null
	rm -rf /TestAP/Test/logs/*.log	2>/dev/null
	#2023-02-28 add del time_record.log
	rm -rf /TestAP/time_record.log 2>/dev/null

	if [ ${Argc:-"0"} == 0 ] ; then
		#2018/12/24
		rm -rf ../Scan/FIXID.ini 2>/dev/null
		rm -rf ../Scan/OPID.ini  2>/dev/null
		rm -rf ../Scan/modellist.ini  2>/dev/null
		printf "%-2s%02d%-30s%-24s\e[1;32m%-9s\n\e[0m" "" "$((d+1))" "    ../Scan/FIXID.ini" "1"  "Deleted" 
		printf "%-2s%02d%-30s%-24s\e[1;32m%-9s\n\e[0m" "" "$((d+2))" "    ../Scan/OPID.ini" "1"  "Deleted"
		printf "%-2s%02d%-30s%-24s\e[1;32m%-9s\n\e[0m" "" "$((d+3))" "    ../Scan/modellist.ini" "1"  "Deleted" 		
	fi
	
	echo -e "----------------------------------------------------------------------"
	echo
	echoPass "${DeleteLog[@]} are deleted"
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile DelayTime AllRecordFiles MaxDepth ApVersion
declare Argc=$#
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

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
			printf "%-s\n" "SerialTest,DeletAllLogs"
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
main 2>/dev/null
if [ ${ErrorFlag} != 0 ] ; then
	GenerateErrorCode
	exit 1
fi
exit 0
