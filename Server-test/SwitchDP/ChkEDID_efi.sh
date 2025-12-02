#!/bin/bash
#FileName : ChkEDID_efi.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.1"
	local CreatedDate="2020-08-20"
	local UpdatedDate="2020-12-16"
	local Description="Get EDID information and verify the version in UEFI"
	
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
	printf "%16s%-s\n" "" "2020-12-16,從引導盤的最後分區開始查找"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet lsblk)
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
		0 : Check EDID information pass
		1 : Check EDID information fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
		<SwitchDP>
			<TestCase>
				<ProgramName>${BaseName}</ProgramName>
				<ErrorCode>TXLAQ|Not Displayed</ErrorCode>
				<!--測試PASS的條件是: 1.Manufacture Year介於1990~2099年-->
				<!--                  2.Version和Revision必須不小於以下版本 -->
				<EDIDTool>ShowEDID.efi</EDIDTool>
				<EDIDVersion>0x01</EDIDVersion>
				<EDIDRevision>0x03</EDIDRevision>
				<LogPathFile>/mnt/edid_efi.log</LogPathFile>
			</TestCase>				
		</SwitchDP>
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
	EDIDTool=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/EDIDTool" -n "${XmlConfigFile}" 2>/dev/null)
	EDIDVersion=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/EDIDVersion" -n "${XmlConfigFile}" 2>/dev/null | sed "s/0x//g")
	EDIDRevision=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/EDIDRevision" -n "${XmlConfigFile}" 2>/dev/null | sed "s/0x//g")
	LogPathFile=$(xmlstarlet sel -t -v "//SwitchDP/TestCase[ProgramName=\"${BaseName}\"]/LogPathFile" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#EDIDVersion} == 0 ] || [ ${#EDIDRevision} == 0 ] || [ ${#LogPathFile} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457

	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" |awk '{print $1}'| sed -n 1p | awk '{print $1}' | tr -d ': ')
	BootDiskVolume=$( echo $BootDiskVolume | cut -c 1-$((${#BootDiskVolume}-1))) 

	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $NF}')
}

SearchLog ()
{
	echo ${LogPathFile} | grep -iwq "^/boot" 
	if [ $? == 0 ] ; then
		if [ -f "${LogPathFile}" ] ; then
			return 0
		else
			Process 1 "No such file: ${LogPathFile}"
			exit 2
		fi
	fi

	DiskPart=($(lsblk | awk '{print $1}' | grep -vE "^[[:alpha:]]" | cut -c 3- ))
	BootDiskTeam=($(echo "${DiskPart[@]}" | tr ' ' '\n' | grep -iwE "${BootDiskSd}[1-9]{1,2}" ))
	NonBootDiskTeam=($(echo "${DiskPart[@]}" | tr ' ' '\n' | grep -viwE "${BootDiskSd}[1-9]{1,2}" ))
	DiskPart=($(echo ${BootDiskTeam[@]} ${NonBootDiskTeam[@]}))
		
	for((f=${#DiskPart[@]}-1;f>=0;f--))
	do
		umount /mnt 2>/dev/null
		mount /dev/${DiskPart[$f]} /mnt 2>/dev/null
		if [ -f "${LogPathFile}" ] ; then
			break
		else
			echo -e "\e[0;33m No found `basename ${LogPathFile}` on: ${DiskPart[$f]}, try next part: ${DiskPart[f-1]:-end}\e[0m"
		fi
	done

	if [ $f -lt 0 ] ; then
		Process 1 "No found EDID dump record ... "
		echo
		echoFail "Check the EDID information"
		GenerateErrorCode
		exit 1
	fi
}

CheckEDIDInfo()
{
	if [ ! -f "${WorkPath}/${EDIDTool}" ] ; then
		Process 1 "No such tool: ${WorkPath}/${EDIDTool}"
		exit 2
	else
		md5sum ${EDIDTool}
		chmod 777 ${EDIDTool}
	fi

	LogPath=${LogPathFile%/*}
	LogFile=${LogPathFile##*/}
	
	CheckEDIDInfoPass='NO'
	rm -rf ./${LogFile} 2>/dev/null
	cat -v ${LogPathFile} 2>/dev/null | sed  "s/\^M//g" | sed "s/\^@//g" | tee ./${LogFile}
	sync;sync;sync
	
	local PassCriteria=0
	local ManufactureYear=$(cat ./${LogFile} 2>/dev/null | grep -iw "Manufacture Year" | awk -F': ' '{print $NF}')
	local DumpEDIDVersion=$(cat ./${LogFile} 2>/dev/null | grep -iw "EDID Version" | awk -F': ' '{print $NF}' | awk '{print $1}' | sed "s/0x//g")
	local DumpEDIDRevision=$(cat ./${LogFile} 2>/dev/null | grep -iw "EDID Revision" | awk -F': ' '{print $NF}' | awk '{print $1}' | sed "s/0x//g")
	if [ ${ManufactureYear:-1900} -ge 1990 ] && [ ${ManufactureYear:-1900} -le 2099 ] ; then
		let PassCriteria++
	fi
	
	printf "%s\n" "ibose=16;${DumpEDIDVersion}-${EDIDVersion}>0" | bc | grep -iwq "1" && let PassCriteria=${PassCriteria}+2
	printf "%s\n" "ibose=16;${DumpEDIDVersion}-${EDIDVersion}==0" | bc | grep -iwq "1" && let PassCriteria++
	printf "%s\n" "ibose=16;${DumpEDIDRevision}-${EDIDRevision}>=0" | bc | grep -iwq "1" && let PassCriteria++

	if [ ${PassCriteria} -ge 3 ] ; then 
		echoPass "Check the EDID information"
		CheckEDIDInfoPass='YES'
		rm -rf ${LogPathFile} 2>/dev/null
	else
		cp -rf ./${EDIDTool} ${LogPath} 2>/dev/null
		cat<<-STARTUP >${LogPath}/${BaseName}.NSH
		@echo -off
		echo "********************************************"
		echo "*******Check EDID information in UEFI*******"
		echo "********************************************"
		 ${EDIDTool} > ${LogFile}     
		type  ${LogFile} 
		echo "********************************************"
		echo "*******Check EDID information in UEFI*******"
		echo "*******Check EDID information in UEFI*******"
		echo "********************************************"
		echo
		STARTUP
		
		sync;sync;sync		
	fi
	
	umount /mnt >/dev/null 2>&1

	if [ ${CheckEDIDInfoPass} == "NO" ] ; then	
		echoFail "Check the EDID information"
		umount  /mnt  2>/dev/null
		GenerateErrorCode	
		exit 1
	fi
	umount /mnt  2>/dev/null
}

main()
{
	GetBootDisk
	SearchLog
	CheckEDIDInfo
	[ ${ErrorFlag} != 0 ] && exit 1
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile EDIDTool EDIDVersion EDIDRevision LogPathFile BootDiskSd BootDiskVolume
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
			printf "%-s\n" "SerialTest,CheckEDIDUEFI"
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
