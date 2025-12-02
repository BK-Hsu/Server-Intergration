#!/bin/bash
#FileName : ChkMD5.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.2"
	local CreatedDate="2018-08-14"
	local UpdatedDate="2020-12-10"
	local Description="Calculate the md5sum value of *.sh and check the MD5 value "
	
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
	printf "%16s%-s\n" "" "2018-12-14,排除部份後面生成的shell程式"
	printf "%16s%-s\n" "" "2020-12-10,更新對二進制可執行文件的管控(通過MD5)"
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
`basename $0` [-Vv] [-C] [-c CheckList] [ -x lConfig.xml ]
	eg.: `basename $0` -V
	eg.: `basename $0` -v
	eg.: `basename $0` -C
	eg.: `basename $0` -C -c lConfig.ini
	eg.: `basename $0` -C -x lConfig.xml

	-h : Show help message
	-V : MD5 value verify
	-C : Calculate the MD5 value of all *.sh file in /TestAP
	-v : Display version number and exit(1)	
	
	-c : Check list file
		/TestAP/Scan/ScanOPID.sh
		/TestAP/Scan/ScanFixID.sh
		/TestAP/ChkBios/ChkBios.sh
		/TestAP/lan/lan_w.sh
		/TestAP/Shutdown/ShutdownOS.sh
		/TestAP/lan/lan_w.sh
	
	-x : config file,format as: *.xml
	<Programs>
		<Item index="1">/TestAP/Scan/ScanOPID.sh</Item>
		<Item index="2">/TestAP/Scan/ScanFixID.sh</Item>
		<Item index="3">/TestAP/ChkBios/ChkBios.sh</Item>
		<Item index="4">/TestAP/lan/lan_w.sh</Item>
	</Programs>
	
	return code:
		0 : Calculate/check MD5 pass
		1 : Calculate/check MD5 fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

#--->Get the parameters from the XML config file
GetParametersInConfig ()
{
	local TestItem=Programs

	xmlstarlet val "${XmlConfigFile}" >/dev/null 2>&1
	if [ $? != 0 ] ; then
		xmlstarlet fo ${XmlConfigFile}
		Process 1 "Invalid XML file: ${XmlConfigFile}"
		exit 3
	fi 

	# Get the parameters information from the config file(*.xml)
	xmlstarlet sel -t -v "//${TestItem}" ${XmlConfigFile} | tr -d '\t ' | grep -v "^$" | awk -F'|' '{print $1}' >${BaseName}.ini 2>/dev/null
	MD5ConfigFile=${BaseName}.ini
	if [ ! -s "${MD5ConfigFile}" ] ; then
		Process 1 "No such file or 0 KB size of file: ${MD5ConfigFile}"
		exit 2
	fi
}

CalculateMD5()
{
	local AllSricpts=()
	ShowTitle "Calculate and verify for Linux Program"
	while :
	do
		command -v whiptail >/dev/null 2>&1
		if [ $? == 0 ] ; then
			psw=$(whiptail --title "Enter Password" --passwordbox "Enter the password to calculate the md5sum of programs and choose OK to continue." 10 60 3>&1 1>&2 2>&3)
		else
			read -p "Please input a password: " -s psw
		fi
		echo -n $psw  | md5sum | grep -iwq "$Password"
		if [ $? == 0  ]; then
			cp -rf ${StdMD5} OriginalStdMD5 2>/dev/null
			echo
			
			AllSricpts=($(find /${RootPath}/ -type f -maxdepth 2 2>/dev/null | grep -iwE "(xml|sh|py)" | grep -iEv 'lan[0-9]{1,3}_' | grep -iv 'run' | grep -iv ' ' | tr '\n' ' '))
			command -v xargs >/dev/null 2>&1
			if [ $? == 0 ]; then
				AllBinaryFiles=($(find /${RootPath}/ -type f -maxdepth 2 2>/dev/null | xargs -I {} file {} 2>/dev/null | grep -iw "LSB executable" | awk -F':' '{print $1}' ))
			else
				AllBinaryFiles=()
			fi
			AllFiles=($(echo ${AllSricpts[@]} ${AllBinaryFiles[@]} | tr ' ' '\n' | sort -u))
			for((a=0;a<${#AllFiles[@]};a++))
			do
				if [ ! -f "${AllFiles[$a]}" ] ; then
					Process 1 "No such file: ${AllFiles[$a]}"
					let ErrorFlag++
				fi
			done
			[ ${ErrorFlag} -ne 0 ] && exit 1
			
			md5sum ${AllFiles[@]} | tee ${StdMD5}
			if [ -s ${StdMD5} ] ; then
				SricptsCnt=$(echo ${AllFiles[@]} | tr ' ' '\n'| grep  -iwEvc "xml+$")
				XMLCnt=$(echo ${AllFiles[@]} | tr ' ' '\n' | grep  -iwEc "xml+$")
				echo				
				echoPass "Sricpt and Binary files: ${SricptsCnt}, XML files: ${XMLCnt}, have been encrypted"
				break
			fi
		else
			echo
			command -v whiptail >/dev/null 2>&1
			if [ $? == 0 ] ; then
				whiptail --title "Invalid password" --msgbox "Invalid password, please try again." 10 60
			else
				echo -e "\033[0;30;41m--Invalid password. Please try again!--\033[0m"
			fi
		fi
	done 
	exit 0
}

main()
{
	if [ ${#MD5ConfigFile} == 0 ] || [ ! -f ${MD5ConfigFile} ] ; then
		SoleShellList='[0-9A-Za-z]'
	else
		# Get a unique name
		ShellList=$(cat ${MD5ConfigFile} 2>/dev/null | awk -F'|' '{print $1}'  )
		SoleShellList=($(echo ${ShellList[@]} | tr ' ' '\n' | sort -u ))
		SoleShellList=$(echo ${SoleShellList[@]} | sed 's/ /\\|/g')
	fi

	FailList=($(md5sum -c $StdMD5 2>/dev/null | grep -iv "OK" | awk -F':' '{print $1}' | grep "${SoleShellList}\|TestAP.sh\|TestAP"))
	if [ ${#FailList[@]} == 0 ] ; then
		return 0
	fi

	ShowTitle "MD5 verify tool for Linux Shell"
	printf "%-29s%-10s%-10s%-19s\n"  "   Program" "Ori. MD5" "Cur. MD5" "   Modify Time"
	echo "----------------------------------------------------------------------"
	for((f=0;f<${#FailList[@]};f++))
	do
		# Cut the 25-32bit
		OriMD5SUM=$(cat -v $StdMD5 2>/dev/null | grep -w "${FailList[$f]}" | awk '{print $1}' | cut -c 25- )
		CurMD5SUM=$(md5sum "${FailList[$f]}" 2>/dev/null | awk '{print $1}' | cut -c 25- )
		CurMD5SUM=${CurMD5SUM:-"--------"}
		ModifyTime=$(stat "${FailList[$f]}" 2>/dev/null | grep -iw "modify" | awk -F'fy:' '{print $2}' | awk -F'.' '{print $1}' )
		ModifyTime=${ModifyTime:-" No such file"}
		#    Program                   Orig MD5   Curr MD5      Modify Time
		# ----------------------------------------------------------------------
		# /TestAP/TestAP.sh            95a32a0f   95a32a0f   2018-07-08 14:12:32
		# /TestAP/Scan/ScanOPID.sh     95a32a0f   95a32a0f   2018-07-08 14:12:32
		# /TestAP/Scan/ScanFixID.sh    95a32a0f   95a32a0f   2018-07-08 14:12:32	
		# /TestAP/ChkBios/ChkBios.sh   95a32a0f   95a32a0f   2018-07-08 14:12:32	
		# ----------------------------------------------------------------------
		PrintFailList=$(echo ${FailList[$f]} | awk -F'/' -v p='/' '{print $(NF-1) p $NF}')
		printf "%-29s%-10s%-10s%-19s\n"  "${PrintFailList}" "${OriMD5SUM}" "${CurMD5SUM}" "${ModifyTime}"

	done
	echo "----------------------------------------------------------------------"
	echo
	echoFail "Do not modify any program. MD5 verify"
	let ErrorFlag++
	[ ${ErrorFlag} != 0 ] && exit 1
}
#----Main function-----------------------------------------------------------------------------
LANG=en_US.UTF-8
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare RootPath=$(echo ${WorkPath} | awk -F'/' '{print $2}')
declare Password='abcf314e470e139bf3c06c859761d560'
declare -i ErrorFlag=0
declare MD5Verify='disable'
declare StdMD5="${WorkPath}/StdMD5"
declare XmlConfigFile MD5ConfigFile ShellList SoleShellList ApVersion

#--->Get and process the parameters
while getopts :P:vhVCc:x: argv
do
	 case ${argv} in
		x)
			XmlConfigFile=${OPTARG}
			GetParametersInConfig
			break
		;;
		
		C)
			# if calculate the md5sum pass then exit 0
			CalculateMD5
		;;
		
		V)
			MD5Verify='enable'
		;;
		
		h)
			Usage
		;;

		v)
			VersionInfo
			exit 1
		;;	
		
		c)
			MD5ConfigFile=${OPTARG}
			if [ ! -s "${MD5ConfigFile}" ] ; then
				Process 1 "No such file or 0 KB size of file: ${MD5ConfigFile}"
				exit 2
			fi
			break
		;;

		P)
			printf "%-s\n" "SerialTest,CheckMD5SUM"
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
