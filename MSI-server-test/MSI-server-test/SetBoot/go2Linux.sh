#!/bin/bash
#FileName : go2Linux.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.3"
	local CreatedDate="2019-09-12"
	local UpdatedDate="2020-12-16"
	local Description="set the first boot as linux"
	
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
	printf "%16s%-s\n" "" "2020-08-20,不限制設備位置"
	printf "%16s%-s\n" "" "2020-12-16,新增將程式或文件拷貝到指定路徑功能"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Grub4EFI/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	   0 : Set the default boot menu pass
	   1 : Set the default boot menu fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Grub4EFI>
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NULL</ErrorCode>
			<MenuFile>Menu/linux.cfg</MenuFile>
			<GrubMenu>/boot/efi/boot/grub/grub-efi-64.cfg</GrubMenu>
			<CopyListing>
				<!--程式將Source指定的文件拷貝覆蓋Target指定的文件,指定文件事先要存在-->
				<File Source="Source/background.png" Target="/mnt/boot/grub/themes/Vimix/background.png"/>
			</CopyListing>			
		</TestCase>	
	</Grub4EFI>
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
	MenuFile=$(xmlstarlet sel -t -v "//Grub4EFI/TestCase[ProgramName=\"${BaseName}\"]/MenuFile" -n "${XmlConfigFile}" 2>/dev/null)
	GrubMenu=$(xmlstarlet sel -t -v "//Grub4EFI/TestCase[ProgramName=\"${BaseName}\"]/GrubMenu" -n "${XmlConfigFile}" 2>/dev/null)
	if [ ${#MenuFile} == 0 ] || [ ${#GrubMenu} == 0 ] ; then
		Process 1 "Menu file is invalid: null!"
		let ErrorFlag++
	fi
	if [ ! -f "${MenuFile}" ] ; then
		Process 1 "No such file: ${MenuFile}"
		let ErrorFlag++	
	fi
	[ ${ErrorFlag} != 0 ] && exit 2
	return 0
}

CopyListingFiles()
{
	local FilesCnt=$(xmlstarlet sel -t -v "//Grub4EFI/TestCase[ProgramName=\"${BaseName}\"]/CopyListing/File/@Source" -n "${XmlConfigFile}" 2>/dev/null | grep -iEc '[0-9A-Z]')
	if [ ${FilesCnt} == 0 ] ; then
		return 0
	fi
	
	for((v=1;v<=${FilesCnt};v++))
	do
		local SourceFile=$(xmlstarlet sel -t -v "//Grub4EFI/TestCase[ProgramName=\"${BaseName}\"]/CopyListing/File[$v]/@Source" -n "${XmlConfigFile}" 2>/dev/null)
		local TargetFile=$(xmlstarlet sel -t -v "//Grub4EFI/TestCase[ProgramName=\"${BaseName}\"]/CopyListing/File[$v]/@Target" -n "${XmlConfigFile}" 2>/dev/null)
		if [ -f "${SourceFile}" ] && [ -f "${TargetFile}" ] ; then
			cp -rf "${SourceFile}" "${TargetFile}" 2>/dev/null
			Process $? "Copy ${SourceFile} to ${TargetFile}" || let ErrorFlag++
		else
			if [ ! -f "${SourceFile}" ] ; then
				Process 1 "No such file: ${SourceFile}" 
			fi
			if [ ! -f "${TargetFile}" ] ; then
				Process 1 "No such file: ${TargetFile}" 
			fi
			let ErrorFlag++
		fi
	done	
}

main()
{
	if [ ! -e "${MenuFile}" ] ; then
		Process 1 "No such file: ${MenuFile}"
		exit 2
	fi
	
	StorageDevices=($(lsblk | awk '{print $1}' | grep -vE "^[[:alpha:]]" | cut -c 3- ))
	for((f=0;f<${#StorageDevices[@]};f++))
	do
		umount /mnt 2>/dev/null
		mount /dev/${StorageDevices[$f]} /mnt 2>/dev/null
		if [ -f "${GrubMenu}" ]; then
			cp -rf "${MenuFile}" "${GrubMenu}" 2>/dev/null
			Process $? "Copy ${MenuFile} to ${GrubMenu}"
			if [ $? == 0 ] ; then
				CopyListingFiles
				break
			fi			
		else
			echo -e "\e[0;33m No found ${GrubMenu} on: /dev/${StorageDevices[$f]}, try next disk: /dev/${StorageDevices[$f+1]:-null}\e[0m"
		fi
	done
	[ $f -ge ${#StorageDevices[@]} ] && let ErrorFlag++
	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Set the new menu as ${MenuFile}"
		exit 1
	else
		echoPass "Set the new menu as ${MenuFile}"
	fi
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile
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
			printf "%-s\n" "SerialTest,BootfromLinux"
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
