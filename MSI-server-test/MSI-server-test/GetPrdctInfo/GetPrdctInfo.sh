#!/bin/bash
#FileName : GetPrdctInfo.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2019-03-28"
	local UpdatedDate="2019-07-04"
	local Description="Get -- Model name|NextStation|MAC|MB Serial Number"
	
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
	#printf "%16s%-s\n" "" " , "
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
			<!--GetPrdctInfo.sh-->
			
			<!--BB SN: 以此為查詢條件查詢，BB SN將從如下路徑讀取，不設定的默認是 /TestAP/PPID/PPID.TXT -->
			<BBSN>/TestAP/PPID/PPID.TXT</BBSN>
			<!--Component: MB PPID or MAC address or card PPID-->
			<!--Get: Model name|NestStation|MAC|MB Serial Number-->
			<!--如下設定為空則不再從MES獲取信息-->
			<Model>/TestAP/GetPrdctInfo/mes_MDL.TXT</Model>
			<NextStation>/TestAP/GetPrdctInfo/mes_NextStation.TXT</NextStation>
			<MAC>/TestAP/GetPrdctInfo/mes_MAC.TXT</MAC>
			<MbSn>/TestAP/GetPrdctInfo/mes_MBSN.TXT</MbSn>
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

	BBSNFile=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/BBSN" -n "${XmlConfigFile}" 2>/dev/null)
	ModelSaveFile=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/Model" -n "${XmlConfigFile}" 2>/dev/null)
	NextStationSaveFile=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/NextStation" -n "${XmlConfigFile}" 2>/dev/null)
	MACSaveFile=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/MAC" -n "${XmlConfigFile}" 2>/dev/null)
	MbSnSaveFile=$(xmlstarlet sel -t -v "//GetPrdctInfo/TestCase[ProgramName=\"${BaseName}\"]/MbSn" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#BBSNFile} == 0 ] || [ ${#ModelSaveFile} == 0 ]  || [ ${#NextStationSaveFile} == 0 ]  || [ ${#MACSaveFile} == 0 ] || [ ${#MbSnSaveFile} == 0 ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi
	return 0
}

main()
{
	WebSite=${WebSite:-"http://20.40.1.40/eps-web/upload/uploadservice.asmx"}
	IPAddr=$(echo ${WebSite} | awk -F'/' '{print $3}')
	BBSNFile=${BBSNFile:-"../PPID/PPID.TXT"}

	# Ping Server
	ping $IPAddr -c 2
	if [ $? != 0 ] ; then
		Process 1 "Ping server(${IPAddr}) test"
		exit 1
	fi

	# Get BB SN information
	TargetBardCode=$(cat ${BBSNFile} 2>/dev/null | head -n 1)
	echo "${TargetBardCode}" | grep -iwEq "[0-9A-Z]{10,17}"
	if [ $? == 0 ] ; then
		Process 0 "Get the BB serial number: ${TargetBardCode}"
	else
		TargetBardCode=${TargetBardCode:-"NULL"}
		Process 1 "Invalid BB serial number: ${TargetBardCode}" || exit 1
	fi


	<<-Show
	[  OK  ] Get the BB serial number: J5E0002019
	[  OK  ] Get the model name: 609-S0851-080
	[  OK  ] Get the next station code is: 1528
	[  OK  ] Get the MAC Address are: 448A5BF58736
			 MAC Address 01: 448A5BF58737
			 MAC Address 02: 448A5BF58738
			 MAC Address 03: 448A5BF58739
			 MAC Address 04: 448A5BF5873A
	[  OK  ] Get the MB serial number is: J416002019                           
	Show

	#Get MODEL NAME
	if [ ${#ModelSaveFile} != 0 ] ; then
		ModelName=$(mes ${WebSite} 2 "sBarcode=${TargetBardCode}" 2>/dev/null | grep -iE "[0-9A-Z]")
		if [ ${#ModelName} == 0 ] ; then
			Process 1 "Get the model name: NULL"
			let ErrorFlag++
		else
			Process 0 "Get the model name: ${ModelName}"
			echo ${ModelName} > ${ModelSaveFile} 
			sync;sync;sync
		fi
	fi

	# Get NextStation
	if [ ${#NextStationSaveFile} != 0 ] ; then
		NextStation=$(mes ${WebSite} 4 "sBarcode=${TargetBardCode}" 2>/dev/null | grep -iwE "[0-9]{1,4}")
		if [ ${#NextStation} == 0 ] ; then
			Process 1 "Get the next station code is: NULL"
			let ErrorFlag++
		else
			Process 0 "Get the next station code is: ${NextStation}"
			echo ${NextStation} > ${NextStationSaveFile} 
			sync;sync;sync
		fi
	fi

	# Get MAC address
	if [ ${#MACSaveFile} != 0 ] ; then
		mes ${WebSite} 8 "sBarcode=${TargetBardCode}" 2>/dev/null | grep -iw "root" | sed "s/&lt;/</g" | sed "s/&gt;/>/g" > MAC_${BaseName}.xml
		sync;sync;sync

		MacAddress=($(xmlstarlet sel -t -v "//root/MAC_ADDRESS" MAC_${BaseName}.xml 2>/dev/null | sort -s ))
		if [ ${#MacAddress[@]} == 0 ] ; then
			Process 1 "No found any MAC address." 
			let ErrorFlag++
		else
			for((m=0;m<${#MacAddress[@]};m++))
			do
				[ $m == 0 ] && rm -rf ${MACSaveFile} >/dev/null 2>&1
				printf "%-10s%12s%02d%-46s\n" "" "MAC Address " "$((m+1))" ": ${MacAddress[$m]}"
				echo ${MacAddress[$m]} >> ${MACSaveFile}
				printf "%s" "${MacAddress[$m]}" > ../Scan/MAC$((m+1)).TXT
				sync;sync;sync
			done
			Process 0 "Get the amount of MAC Address is: ${#MacAddress[@]} PCs"
		fi
		rm -rf  MAC_${BaseName}.xml 2>/dev/null
	fi

	# Get MB Serial Number
	if [ ${#MbSnSaveFile} != 0 ] ; then
		MBBardCode=$(mes ${WebSite} 7 "sBarcodeNo=${TargetBardCode}" 2>/dev/null | grep -iwE "[0-9A-Z]{10,17}")
		if [ ${#MBBardCode} == 0 ] ; then
			Process 1 "Get the MB serial number is: NULL"
			let ErrorFlag++
		else
			Process 0 "Get the MB serial number is: ${MBBardCode}"
			echo ${MBBardCode} > ${MbSnSaveFile} 
			sync;sync;sync
		fi
	fi

	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "Get the information of barcode(${TargetBardCode}) " 
		GenerateErrorCode
		exit 1
	else
		echoPass "Get the information of barcode(${TargetBardCode})"
	fi	
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare XmlConfigFile 
declare WebSite IPAddr
declare ModelSaveFile=''
declare NextStationSaveFile=''
declare MACSaveFile=''
declare MbSnSaveFile=''
declare ModelName NextStation WorkOrder TargetBardCode MBBardCode MacAddress
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
			printf "%-s\n" "SerialTest,GetInfofrMES"
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
[ ${ErrorFlag} != 0 ]  && exit 1
exit 0
