#!/bin/bash
#FileName : Pass.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.3"
	local CreatedDate="2018-10-09"
	local UpdatedDate="2020-12-09"
	local Description="Upload test pass message"
	
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
	printf "%16s%-s\n" "" "2020-09-07,Add NTF information"
	printf "%16s%-s\n" "" "2020-12-09,修改以適用於Ubuntu OS"
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
	ExtCmmds=(xmlstarlet md5sum stat)
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
		0 : Upload pass
		1 : Upload fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Programs>
		<Item index="1">/TestAP/Scan/ScanOPID.sh</Item>
		<Item index="2">/TestAP/Scan/ScanFixID.sh</Item>
		<Item index="3">/TestAP/ChkBios/ChkBios.sh|S1651</Item>
		<Item index="4">/TestAP/lan/lan_w.sh|S165B|S1651</Item>
		<Item index="5">/TestAP/Shutdown/ShutdownOS.sh</Item>
		<Item index="6">/TestAP/lan/lan_w.sh</Item>
		<Item index="7">/TestAP/BMC/BMCMAC_w.sh</Item>
		<Item index="8">/TestAP/BMC/BMCMAC_c.sh</Item>
		<Item index="9">/TestAP/BMC/NCSITest.sh</Item>	
		<Item index="10">/TestAP/AMIDLNX/SrlNum_c.sh</Item>	
		<Item index="11">/TestAP/AMIDLNX/SrlNum_w.sh</Item>	
	</Programs>	
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
	
	# Get the parameters information from the config file(*.xml)
	TotalItemIndex=($(xmlstarlet sel -t -v "//Programs/Item/@index" -n ${XmlConfigFile} | sort -nu ))
	AllTestItemsSet=($(xmlstarlet sel -t -v "//Programs/Item" -n ${XmlConfigFile} | tr -d '\t ' | awk -F'|' '{print $1}')) 
	if [ "${#AllTestItemsSet[@]}" == 0 ] ; then
		Process 1 "No found test items in the XML file: ${XmlConfigFile}"
		exit 2
	fi
}

CheckSizeOfLog ()
{
	local TargetLog=$1
	local FileSize=$(ls -l ${TargetLog} | awk '{print $5}')
	#大於5MB的文件不給上傳FTP
	# Usage: CheckSizeOfLog logName
	FileSize=${FileSize:-"1048"}
	if [ "${FileSize}" -gt 5242880 ] ; then
		Process 1 "The size of ${TargetLog} is too big(size=${FileSize} B, bigger than 5MB) ..."
		ls -lh ${TargetLog} 2>/dev/null
		exit 1
	fi
}

CreateTestResult ()
{
	if [ $(cat -v PCBAProductInfo.TXT 2>/dev/null | grep -iEc "[0-9A-Z]") -le 1 ] ; then
		if [  "${FinalProcID}" -ge ${#TotalItemIndex[@]} ] ; then
			echo "${pcb}|`cat -v PCBAProductInfo.TXT 2>/dev/null| awk -F'|' '{print $2}'`|Pass" > TestResult.txt 2>/dev/null
			if [ $(cat -v ./Output/cap.out | grep -iwc "${pcb},`cat -v OPID.TXT`" ) == 0 ]; then
				echo "${pcb},`cat -v OPID.TXT`" >> ./Output/cap.out
			fi
		else
			#SN|Model|Fail|ErrorCode
			echo "${pcb}|`cat -v PCBAProductInfo.TXT  2>/dev/null| awk -F'|' '{print $2}'`|Fail|`cat -v FailureTestResult.txt 2>/dev/null| awk -F'|' '{print $4}'`" > TestResult.txt 2>/dev/null
		fi
		sync;sync;sync
		return 0
	fi

	# PCBAProductInfo.TXT include: SN|Model|1525
	rm -rf TestResult.txt 2>/dev/null
	if [  "${FinalProcID}" -ge "${#TotalItemIndex[@]}" ] ; then
		local SerialNumbers=($(cat -v PCBAProductInfo.TXT 2>/dev/null | awk -F'|' '{print $1}'))
	else
		local SerialNumbers=($(cat -v FailureTestResult.txt 2>/dev/null | awk -F'|' '{print $1}'))
	fi
	for ((s=0;s<${#SerialNumbers[@]};s++))
	do
		if [  "${FinalProcID}" -ge "${#TotalItemIndex[@]}" ] ; then
			echo "${SerialNumbers[$s]}|`grep "${SerialNumbers[$s]}" PCBAProductInfo.TXT 2>/dev/null | awk -F'|' '{print $2}'`|Pass" >> TestResult.txt 2>/dev/null
			if [ $(cat -v ./Output/cap.out | grep -iwc "${SerialNumbers[$s]},`cat -v OPID.TXT`" ) == 0 ]; then
				echo "${SerialNumbers},`cat -v OPID.TXT`" >> ./Output/cap.out
			fi
		else
			echo "${SerialNumbers[$s]}|`grep "${SerialNumbers[$s]}" PCBAProductInfo.TXT 2>/dev/null | awk -F'|' '{print $2}'`|Fail|`grep "${SerialNumbers[$s]}" FailureTestResult.txt 2>/dev/null| awk -F'|' '{print $4}'`" >> TestResult.txt 2>/dev/null
		fi
		sync;sync;sync		
	done
	return 0
}

CheckTestPassRecord()
{
	local TargetLog=$1
	# Usage: CheckTestPassRecord logName
	# Get a unique name
	local IgnoredItems=(Shutdown Multithread Multi-thread)
	local SoleIgnoredItems=($(echo ${IgnoredItems[@]} | tr ' ' '\n' | sort -u ))
	SoleIgnoredItems=$(echo ${SoleIgnoredItems[@]} | sed 's/ /\\|/g')
	local CheckItems=($(echo "${AllTestItemsSet[@]}"| tr " " "\n" | grep -v '_w.sh' | grep -v '_w' | grep -v "${SoleIgnoredItems}"))
	#   Test Items                               NTF Cnt          Pass Cnt
	#----------------------------------------------------------------------
	# /TestAP/chkbios/chkbios.sh                    5                 1
	# /TestAP/chkbios/chkbios.sh                    7                 0
	# /TestAP/chkbios/chkbios.sh                    0                 1
	#----------------------------------------------------------------------
	ShowTitle "Check NTF and Pass Record in ${WorkPath}/${pcb}.log"
	printf "%-44s%-17s%-9s\n" "   Test Items" "NTF Cnt" "Pass Cnt"
	echo "----------------------------------------------------------------------"
	for ((i=0;i<${#CheckItems[@]};i++))
	do
		local NtfCnt=$(cat -v ${TargetLog} | tr -d '\t ' | grep -i "`echo "${CheckItems[$i]}" | awk -F'/' '{print $NF}'`" | grep -ic "TestFail")
		local PassCnt=$(cat -v ${TargetLog} | tr -d '\t ' | grep -i "`echo "${CheckItems[$i]}" | awk -F'/' '{print $NF}'`" | grep -ic "TestPassin")
		printf "%-47s%-18s%-5s\n" "${CheckItems[$i]}" "${NtfCnt}" "${PassCnt}"
		
		if [ ${PassCnt} == 0 ] ; then
			let ErrorFlag++
		fi
	done
	echo "----------------------------------------------------------------------"
	if [ "$ErrorFlag" != 0 ] ; then
		Process 1 "Some items no found test pass record. Check the log fail ..."
		printf "%-10s%-s\n" "" "Pass Count should greater than zero ..."
		exit 1
	fi
}

CheckMD5()
{
	local ShellList=($(xmlstarlet sel -t -v "//Programs/Item" ${XmlConfigFile} 2>/dev/null | tr -d '\t ' | grep -v "^$" | awk -F'|' '{print $1}' ))
	local SoleShellList=($(echo ${ShellList[@]} | tr ' ' '\n' | sort -u ))
	local SoleShellList=$(echo ${SoleShellList[@]} | sed 's/ /\\|/g')

	if [ -s "${StdMD5}" ] ; then
		local FailList=($(md5sum -c ${StdMD5} 2>/dev/null | grep -iv "OK" | awk -F':' '{print $1}' ))
		local PassList=($(md5sum -c ${StdMD5} 2>/dev/null | grep -i "OK" | awk -F':' '{print $1}' | grep "${SoleShellList}\|${BaseName}.sh\|${BaseName}" ))
		md5sum -c ${StdMD5} 2>&1 | grep -iwq "NOT MATCH"
		if [ $? != 0 ] && [ ${#PassList[@]} -ge ${#ShellList[@]} ] ; then
			return 0
		fi
	fi
	
	if [ ${#FailList[@]} == 0 ] ; then
		return 0
	fi
	
	ShowTitle "MD5 verify tool for Linux Shell"
	printf "%-29s%-10s%-10s%-19s\n"  "   Program" "Ori. MD5" "Cur. MD5" "   Modify Time"
	echo "----------------------------------------------------------------------"
	for((f=0;f<${#FailList[@]};f++))
	do
		# Cut the 25-32bit
		OriMD5SUM=$(cat -v ${StdMD5} 2>/dev/null | grep -w "${FailList[$f]}" | awk '{print $1}' | cut -c 25- )
		CurMD5SUM=$(md5sum "${FailList[$f]}" 2>/dev/null | awk '{print $1}' | cut -c 25- )
		ModifyTime=$(stat "${FailList[$f]}" 2>/dev/null | grep -iw "modify" | awk -F'fy:' '{print $2}' | awk -F'.' '{print $1}' )
		#    Program                   Ori. MD5   Cur. MD5      Modify Time
		# ----------------------------------------------------------------------
		# /TestAP/TestAP.sh            95a32a0f   95a32a0f   2018-07-08 14:12:32
		# /TestAP/Scan/ScanOPID.sh     95a32a0f   95a32a0f   2018-07-08 14:12:32
		# /TestAP/Scan/ScanFixID.sh    95a32a0f   95a32a0f   2018-07-08 14:12:32	
		# /TestAP/ChkBios/ChkBios.sh   95a32a0f   95a32a0f   2018-07-08 14:12:32	
		# ----------------------------------------------------------------------
		PrintFailList=$(echo ${FailList[$f]} | awk -F'/' -v p='/' '{print $(NF-1) p $NF}')
		printf "%-29s%-10s%-10s%-19s\n"  "${PrintFailList}" "${OriMD5SUM}" "${CurMD5SUM:-"--------"}" "${ModifyTime:-" No such file"}"

	done
	echo "----------------------------------------------------------------------"
	Process 1 "Do not modify any program. MD5 verify ..."
	return 1
}

main()
{
	if [ ${#pcb} == 0 ] ; then
		Process 1 "Execute this program alone is forbiden."
		exit 1
	fi
	
	local Tools=(./upload.sh ./Output/Output.sh ./CycleTime/CycleTime.sh  ./upload ./Output/Output ./CycleTime/CycleTime)
	for((t=0;t<${#Tools[@]};t++))
	do
		[ -f "${Tools[f]}" ] && chmod 777 "${Tools[f]}" >/dev/null 2>&1
	done
	
	CheckMD5 || exit 1
	CheckSizeOfLog "${LogFile}"
	FinalProcID=${FinalProcID:-"0"}
	if [  "${FinalProcID}" -ge ${#TotalItemIndex[@]} ] ; then
		# Pass(Proc進程數不小於index數量時表示Pass) 上傳則必須保證所有的項目測試pass
		# Fail上傳不會進行測試項目pass記錄的檢查
		CheckTestPassRecord "${LogFile}"
	fi

	#生成TestResult.txt（SN|Model全名稱|測試狀態Pass還是fail|Fail時的ErrorCode）測試結果
	CreateTestResult
	if [ -f "./CycleTime/CycleTime" ] ; then
		./CycleTime/CycleTime -l "${LogFile}"
	else
		./CycleTime/CycleTime.sh -l "${LogFile}"
	fi
	
	if [ -f "./Output/Output" ] ; then
		./Output/Output -f './Output/cap.out' 2>/dev/null
	else
		./Output/Output.sh -f './Output/cap.out' 2>/dev/null
	fi
	
	# Upload log
	if [ -f "./upload" ] ; then
		./upload -x ${XmlConfigFile}
	else
		./upload.sh -x ${XmlConfigFile}
	fi
	if [ "$?" == "0" ]; then
		PassCnt=$(cat -v ./Upload-Result.log 2>/dev/null | tr -d "^M" | grep -iwc "OK")
		SNCnt=$(cat -v ./TestResult.txt 2>/dev/null | tr -d "^M" | grep -ic "[0-9A-Z]")
		while :
		do
			if [ "${PassCnt}" == 0 ] || [ "${PassCnt}" -lt "${SNCnt}" ]; then
				echo -e "\e[0;30;41m ********************************************************************** \e[0m"
				echo -e "\e[0;30;41m *      Warning! Upload MES is incomplete,as shown in red font!!      * \e[0m"
				echo -e "\e[0;30;41m *      The current station is fault!  F/T test is failure!!          * \e[0m"
				echo -e "\e[0;30;41m ********************************************************************** \e[0m"
				read -p "Press `echo -e "\e[32m[AnyKey]\e[0m"` to break.Input `echo -e "\e[31m[GO]\e[0m"` to continue ... "  -n2 Ans
				Ans=$(echo "${Ans}" | tr [a-z] [A-Z])
				case ${Ans} in
					GO)	break;;
					 
					*)
						echo -e "\n Upload MES has been interrupted ..."
						exit 1
					 ;;
					esac	 
					echo
			else
				break
			fi
		done
			
		# test the next board must shutdown os first
		InitFlagFolder="${WorkPath}/.InitFlag"
		mkdir -p ${InitFlagFolder} 2>/dev/null
		last | head -n1 > ${InitFlagFolder}/ShutdownFlag 2>/dev/null
		sync;sync;sync
		echoPass "All items test"
		exit 0
	else
		echoFail "Some items test"
		exit 1
	fi
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile TotalItemIndex ApVersion
declare StdMD5="${WorkPath}/ChkMD5/StdMD5"
declare LogFile="${WorkPath}/${pcb}.log"
declare FinalProcID=$(cat ${WorkPath}/${pcb}.proc | tr -d ' ')
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
			printf "%-s\n" "SerialTest,AllTestPASS"
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
