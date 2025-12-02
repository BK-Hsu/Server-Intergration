#!/bin/bash
#FileName : ChkTPM.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2018-08-02"
	local UpdatedDate="xxxx"
	local Description="TPM function test"
	
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
	#printf "%16s%-s\n" "" "xx,xxxxx"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//TPM/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet) # tpm_selftest for TPM2.0以下
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
		0 : TPM function test pass
		1 : TPM function test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}


DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<TPM>
		<TestCase>
			<!--在UEFI下测试,OS下检查结果-->
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>TXS37|TPM test fail</ErrorCode>
			<!--log应该在根目录下-->
			<LogPath>/dev/sda1</LogPath>
			<Version>5.62</Version>
		</TestCase>
	</TPM>
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
	TpmVersion=$(xmlstarlet sel -t -v "//TPM/TestCase[ProgramName=\"${BaseName}\"]/Version" -n "${XmlConfigFile}" 2>/dev/null)
	LogPath=$(xmlstarlet sel -t -v "//TPM/TestCase[ProgramName=\"${BaseName}\"]/LogPath" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#TpmVersion} == 0 ] || [ ${#LogPath} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

ShowHowToDo ()
{
	cat<<-mesg
	 **********************************************************************
	 ****          當前項目測試Fail,請重啟到EFI Shell測試:         ********
	 ****          [1] 打開終端輸入init 6重啟                      ********
	 ****              如果是TPM測試項，請確認TPM2.0卡已經接好     ********
	 ****          [2] 按鍵盤[F11]，選擇 EFI Shell啟動             ********
	 ****          [3] 稍等片刻，程式將自動轉回CentOS啟動          ********
	 ****          [4] 按以上操作測試還是Fail請聯繫PE確認          ********
	 **********************************************************************
	mesg
}

main()
{
	umount /mnt >/dev/null 2>&1
	mount ${LogPath} /mnt >/dev/null 2>&1
	Process $? "mount ${LogPath} /mnt" || exit 1

	#FIRMWARE VERSION
	CurTpmFwVer=$(cat -v /mnt/TPM.log 2>/dev/null | sed  "s/\\^M//g" | sed "s/\\^@//g" | grep -iw "TPM_PT_FIRMWARE_VERSION" | grep -i "version" | head -n1 | awk '{print $NF}' )
	if [ $(echo "${CurTpmFwVer}" | grep -iwc "${TpmVersion}") == 1 ] ; then 
		Process 0 "TPM firmware version now is: ${CurTpmFwVer}"
	else
		Process 1 "TPM firmware version now is: ${CurTpmFwVer:-"N/A"}, it should be: ${TpmVersion}"
		let ErrorFlag++
	fi

	#selftest
	SelftestPass=$(cat -v /mnt/TPM.log 2>/dev/null | sed  "s/\\^M//g" | sed "s/\\^@//g" | grep -ic "Full TPM selftest completed successfully" )
	if [ ${SelftestPass} -ge 1 ] ; then 
		if [ ! -z "${pcb}" ] ; then 
			echo "--------------------------------------------------------------------------------------------------------------------------------------" >> ../PPID/${pcb}.log
			cat -v /mnt/TPM.log 2>/dev/null | tr -d "^M@" >> ../PPID/${pcb}.log
			echo "--------------------------------------------------------------------------------------------------------------------------------------" >> ../PPID/${pcb}.log
			
		fi
		Process 0 "Full TPM selftest"
	else
		Process 1 "Full TPM selftest"
		cp -rf ./TpmEfi /mnt/ 2>/dev/null
		cp -rf ./TpmEfi/STARTUP.NSH /mnt 2>/dev/null
		let ErrorFlag++
	fi

	cp -rf /mnt/TPM.log . 2>/dev/null
	rm -rf /mnt/TPM.log   2>/dev/null
	umount /mnt >/dev/null 2>&1

	if [ ${ErrorFlag} != 0 ] ; then
		ShowHowToDo
		echoFail "TPM function test"
		exit 1
	else
		echoPass "TPM function test"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile TpmVersion
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
			printf "%-s\n" "SerialTest,CheckTPM"
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
