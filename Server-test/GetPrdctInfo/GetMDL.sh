#!/bin/bash
#FileName : GetMDL.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.3"
	local CreatedDate="2018-09-10"
	local UpdatedDate="2020-12-31"
	local Description="Get -- Model name|NextStation"
	
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
	printf "%16s%-s\n" "" "2019-12-10,更新了配置檔的格式"
	printf "%16s%-s\n" "" "2020-07-06,更新了站別檢測"
	printf "%16s%-s\n" "" "2020-12-31,顯示結果優化讓信息更容易看懂"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	local BlankCnt=0
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(80-${#Title})/2
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
		0 : Get product Infomation pass
		1 : Get product Infomation fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<GetPrdctInfo>
		<UrlAddress>
			<!--Web網的選擇: 1或2-->
			<IndexInUse>1</IndexInUse>
			<MesWeb index="1">http://20.40.1.40/eps-web/upload/uploadservice.asmx</MesWeb>
			<MesWeb index="2">http://172.17.7.101/eps-web/upload/uploadservice.asmx</MesWeb>		
		</UrlAddress>
		
		<TestCase>
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NULL</ErrorCode>
			<!--GetMDL.sh-->
			<!--Get the infomation of PCBA board / BB system -->			
			<!--Get: Model name|NestStation,并比對機種名稱-->
			<!--需要依據以下文件（格式如上）內容才能獲取，SN_MODEL_TABLE.TXT由ScanSNs.sh創建-->
			<MBSerialNumberPath>/TestAP/PPID/SN_MODEL_TABLE.TXT</MBSerialNumberPath>
			
			<!--獲取結果存在: /TestAP/PPID/PCBAProductInfo.TXT-->
			<!--文件內容是: 主板條碼|MES的Model名稱|下一個工站代碼-->
			<!--Station: 當前的工站代碼,如填寫則程式將檢測待測主板或小卡是否和設置的一致;空白則不檢測-->
			<Station>1528</Station>
		</TestCase>
	</GetPrdctInfo>
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
	IndexInUse=$(xmlstarlet sel -t -v "//GetPrdctInfo/UrlAddress/IndexInUse" -n "${XmlConfigFile}" 2>/dev/null)
	WebSite=$(xmlstarlet sel -t -v "//GetPrdctInfo/UrlAddress/MesWeb[@index=\"${IndexInUse}\"]" -n "${XmlConfigFile}" 2>/dev/null)
	MBSerialNumberFile=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/MBSerialNumberPath" -n "${XmlConfigFile}" 2>/dev/null)
	StdStation=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/Station" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#MBSerialNumberFile} == 0 ] || [ ${#WebSite} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi

	if [ ! -f "${MBSerialNumberFile}" ] ; then
		Process 1 "No such file: ${MBSerialNumberFile}"
		exit 2
	else
		MBSerialNumber=($(cat ${MBSerialNumberFile} | awk -F'|' '{print $1}'))
	fi

	return 0
}

main()
{
	WebSite=${WebSite:-"http://20.40.1.40/eps-web/upload/uploadservice.asmx"}
	IPAddr=$(echo ${WebSite} | awk -F'/' '{print $3}')

	# Ping Server
	ping $IPAddr -c 2
	if [ $? != 0 ] ; then
		Process 1 "Ping server(${IPAddr}) test"
		exit 1
	fi

	# Get information
	if [ ${#MBSerialNumber[@]} == 0 ] ; then
		echoFail "No serial number found, get information"
		GenerateErrorCode
		exit 1
	fi
	
	# +------------+----------+-------------+---------------+---------------+--------+
	# |   Serial   |  Actual  |    Expect   |    Actual     |    Expect     |        |
	# |   Number   | Next STN |   Next STN  |  Model(MES)   |  Model(Scan)  | Match? |
	# +------------+----------+-------------+---------------+---------------+--------+
	# | K616844575 |   1528   | 2695,1528,0 | 609-S238A-A01 |   S238A       |   Yes  |
	# +------------+----------+-------------+---------------+---------------+--------+

	ShowTitle "Obtain and compare the SN and MDL relational tables"
	rm -rf ${SaveFile} 2>/dev/null
	cat <<-Ttile
	+------------+----------+-------------+---------------+---------------+--------+
	|   Serial   |  Actual  |    Expect   |    Actual     |    Expect     |        |
	|   Number   | Next STN |   Next STN  |  Model(MES)   |  Model(Scan)  | Match? |
	+------------+----------+-------------+---------------+---------------+--------+
	Ttile
	for((s=0;s<${#MBSerialNumber[@]};s++))
	do
		# Get Model
		MesModelName=$(mes $WebSite 2 "sBarcode=${MBSerialNumber[$s]}" 2>/dev/null | grep -E "[0-9]" | awk '{print $1}' | tr -d ':')
		if [ $(echo $MesModelName | grep -ic "${MBSerialNumber[$s]}") -ge 1 ] ; then
			MesModelName="Invalid SN"
			let ErrorFlag++
		fi
		
		# Get NextStation
		NextStation=$(mes $WebSite 4 "sBarcode=${MBSerialNumber[$s]}" 2>/dev/null | grep -E "[0-9]" | awk '{print $1}' | tr -d ':')
		if [ $(echo $NextStation | grep -ic "${MBSerialNumber[$s]}") -ge 1 ] ; then
			NextStation="N/A"
		fi
		
		if [ ${#StdStation} != 0 ] ; then
			echo "${StdStation}" | grep -iwq "${NextStation:-'null'}" 
			if [ $? != 0 ] ; then
				let ErrorFlag++
				let StationError++
			fi
		fi
		
		# Get WorkOrder
		#WorkOrder=$(mes $WebSite 5 "sBarcode=${MBSerialNumber[$s]}" 2>/dev/null | grep -E "[0-9]" | awk '{print $1}')	
		if [ ${#MesModelName} == 0 ] || [ ${#NextStation} == 0 ] ; then
			let ErrorFlag++
		fi
		
		if [ ${#MBSerialNumberFile} != 0 ] && [ -f "${MBSerialNumberFile}" ]; then
			ScanModelName=$(cat ${MBSerialNumberFile} 2>/dev/null | grep -iw "${MBSerialNumber[$s]}" | awk -F'|' '{print $2}')	
		fi
		
		printf "%-1s%-12s%-1s%-10s%-1s%-13s%-1s%-15s%-1s%-15s%-1s" "|" " ${MBSerialNumber[$s]}" "|" "   ${NextStation}" "|" " ${StdStation}" "|" " ${MesModelName}" "|" "   ${ScanModelName}" "|" 
		if [ "${ScanModelName}"x == "x" ] ; then
			printf "%-8s%-1s\n" "   ---" "|"
		else
			if [ $(echo "${MesModelName}" | grep -ic "${ScanModelName}") -ge 1 ]; then
				printf "\e[32m%-8s\e[0m%-1s\n" "   Yes" "|"
			else
				printf "\e[31m%-8s\e[0m%-1s\n" "   No" "|"
				let ErrorFlag++
			fi
		fi
		
		# SN|Model|1525
		echo "${MBSerialNumber[$s]}|${MesModelName}|${NextStation}"	>>  ${SaveFile}	
		sync;sync;sync
	done
	echo "+------------+----------+-------------+---------------+---------------+--------+"
	
	#當單機種測試的時候
	cat ${SaveFile}	| grep -iEc "[0-9A-Z]" |  grep -iwq "1"
	if [ $? == 0 ] ; then
		printf "%s\n" "${MesModelName}" > ../PPID/MODEL.TXT
		sync;sync;sync
	fi
	
	if [ ${ErrorFlag} != 0 ] ; then
		[ ${StationError} -ge 1 ] && echo "待測主板/小卡站別錯誤..."
		echoFail "Get the model name" 
		rm -rf ${SaveFile} 2>/dev/null
		GenerateErrorCode
		exit 1
	else
		echoPass "Get the model name or compare modle name"
	fi	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -i StationError=0
declare XmlConfigFile 
declare MBSerialNumberFile MBSerialNumber WebSite IPAddr ApVersion
declare MesModelName NextStation WorkOrder
declare SaveFile='../PPID/PCBAProductInfo.TXT'
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
			printf "%-s\n" "SerialTest,GetModel"
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
