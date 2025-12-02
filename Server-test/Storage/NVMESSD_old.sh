#!/bin/bash
#FileName : Storage.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.2.6"
	local CreatedDate="2018-06-04"
	local UpdatedDate="2020-12-11"
	local Description="SATA,SAS,mSATA,CF,SATADOM,PCIE SSD,SD,M.2 read and write function test"
	
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
	printf "%16s%-s\n" "" "2019-01-12,Not suitable for USB read and write test"
	printf "%16s%-s\n" "" "2019-03-21,識別TL396的規則由容量修改為Model name為TL396,此適用性更佳"
	printf "%16s%-s\n" "" "2019-10-15,新增並行測試功能"
	printf "%16s%-s\n" "" "2020-08-18,支持NVMe SSD定位"
	printf "%16s%-s\n" "" "2020-11-18,（優先使用StroageRW.sh）"
	printf "%16s%-s\n" "" "2020-12-11,優化Gen的判定方法"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet hdparm )
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			hdparm)printf "%10s%s\n" "" "Please install: hdparm-9.43-5.el7.x86_64.rpm";;
		esac
		
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

ShowTitle()
{
	local BlankCnt=0
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}

Wait4nSeconds()
 {
	local sec=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${sec};p>=0;p--))
	do   
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			break
		else
			continue
		fi
	done
	echo '' 
}
 
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [-x lConfig.xml] [-DV] [-f /dev/sda]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D
	eg.: `basename $0` -V

	-D : Dump the sample xml config file
	-f : format /dev/sda	
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)	

	return code:
		0 : Read and write test pass
		1 : Read and write test fail
		2 : File is not exist
		3 : Parameters error
		Other : Fail

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<Storage>
		<!--除U盤外所有的儲存功能接口讀寫測試程式-->
		<!-- Amount			: 接口/設備數量                   -->
		<!-- LowBoundSpeed	: 最低速率                        -->
		<!-- Location		: 絲印名稱                        -->
		<!-- Generation		: 第n代硬盤,Gen1.0,Gen2.0,Gen3.0  -->
		
		<!--DRDY ERROR 檢查開關-->
		<CheckDrdyBus>disable</CheckDrdyBus>		

		<TestCase>
			<ProgramName>Sata</ProgramName>
			<ErrorCode>TXS1U|SATA port test fail</ErrorCode>
			<!--  ByAddr來測試可以準確的將硬盤和位置（PCB 絲印）關係對應得上，其他模式的方式對應關係不一定準確-->
			<!-- BySize:按容量大小測試, ByModel:按名稱測試, ByAddr:按設備位置測試 -->
			<TestMethod>ByAddr</TestMethod>
			
			<!--R: read only, RW: Read and write-->
			<ReadWrite>R</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>SATA</Module>			
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<!--一般情形不需要修改此數據，當有新型號且使用按容量/型號測試時才使用此數據做參數-->
				<Capacity>
					<!--Unit: MB/GB-->
					<Case>40</Case>
					<Case>60</Case>
					<Case>80</Case>
					<Case>160</Case>
					<Case>320</Case>
					<Case>500</Case>
				</Capacity>
				
				<Model>
					<Case>MSIK-TL39610-001</Case>
					<Case>ST[3,5][0-5]0.*</Case>
					<Case>WD.*</Case>
					<Case>HGST.*</Case>
					<Case>ADATA*</Case>
				</Model>
			</ModelData>
			
			<!-- Define the relationship of location and lable -->
			<!-- Gen3.0(6.0Gbps),Gen2.0(3.0Gbps),Gen1.0(1.5Gbps) -->
			<!-- 	   address | Generation | LowBoundSpeed  Unit: MB/s| PCB marking -->
			<!-- ls -l /sys/block 即可查看當前設備的對應關係；調試方法：先單獨插一個硬盤，使用指令打印出來  -->
			<Port>ata1|Gen3.0|200|miniSAS-3-0</Port>
			<Port>ata2|Gen3.0|200|miniSAS-3-1</Port>
			<Port>ata3|Gen3.0|200|miniSAS-3-2</Port>
			<Port>ata4|Gen3.0|200|miniSAS-3-3</Port>
			<Port>ata5|Gen2.0|20|SSATA4</Port>
			<Port>ata6|Gen3.0|200|SSATA5</Port>
			<Port>ata7|Gen3.0|200|miniSAS-1-0</Port>
			<Port>ata8|Gen3.0|200|miniSAS-1-1</Port>
			<Port>ata9|Gen3.0|200|miniSAS-1-2</Port>
			<Port>ata10|Gen3.0|200|miniSAS-1-3</Port>
			<Port>ata11|Gen3.0|200|miniSAS-2-0</Port>
			<Port>ata12|Gen3.0|200|miniSAS-2-1</Port>
			<Port>ata13|Gen3.0|200|miniSAS-2-2</Port>
			<Port>ata14|Gen3.0|200|miniSAS-2-3</Port>
		</TestCase>

		<TestCase>
			<ProgramName>SataDom</ProgramName>
			<ErrorCode>TXS1U|SATA port test fail</ErrorCode>
			<!-- BySize:按容量大小測試, ByModel:按名稱測試 -->
			<TestMethod>ByModel</TestMethod>
			<!--R: read only, RW: Read and write-->
			<ReadWrite>RW</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			
			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>SATADOM</Module>					
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>2011</Case>
					<Case>4011</Case>
					<Case>31</Case>
					<Case>32</Case>
				</Capacity>
				
				<Model>
					<Case>SATADOM.*</Case>
					<Case>KDM-SA.72-032GMJ</Case>
					<Case>SDH-32</Case>
				</Model>
			</ModelData>
			
			<Amount>1</Amount>
			<!--LowBoundSpeed Unit: MB/s-->
			<LowBoundSpeed>60</LowBoundSpeed>
			<Location>DOM_SATA1</Location>
		</TestCase>					

		<TestCase>
			<ProgramName>CFCard</ProgramName>
			<ErrorCode>TXC02|SD/MS/CF Card test fail</ErrorCode>
			<!--R: read only, RW: Read and write-->
			<ReadWrite>RW</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			
			<!-- BySize:按容量大小測試, ByModel:按名稱測試 -->
			<TestMethod>ByModel</TestMethod>

			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>CFCARD</Module>				
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>7994</Case>
					<Case>128</Case>
					<Case>8019</Case>
					<Case>4017</Case>
					<Case>3997</Case>
					<Case>4059</Case>
				</Capacity>
				
				<Model>
					<Case>CF.Card</Case>
					<Case>SATADOM-SL.*</Case>
					<Case>128MB.Comp.*</Case>
					<Case>ELITE.PRO.CF.CAR*</Case>
					<Case>Multiple.Reader</Case>
					<Case>TS8GCF133</Case>
				</Model>
			</ModelData>
			
			<Amount>1</Amount>
			<!--LowBoundSpeed Unit: MB/s-->
			<LowBoundSpeed>20</LowBoundSpeed>
			<Location>CF1</Location>
		</TestCase>

		<TestCase>
			<ProgramName>M2Sata</ProgramName>
			<ErrorCode>TXS1U|SATA port test fail</ErrorCode>
			<!-- BySize:按容量大小測試, ByModel:按名稱測試 -->
			<TestMethod>ByModel</TestMethod>
			
			<!--R: read only, RW: Read and write-->
			<ReadWrite>RW</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			
			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>M2</Module>				
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>32</Case>
					<Case>256</Case>
				</Capacity>
				
				<Model>
					<Case>KINGSTON.*</Case>
					<Case>TS32GMTS400</Case>
				</Model>
			</ModelData>
			
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>1967</Case>
					<Case>3965</Case>
					<Case>8068</Case>
				</Capacity>
				
				<Model>
					<Case></Case>
				</Model>
			</ModelData>
			
			<Amount>1</Amount>				
			<!--LowBoundSpeed Unit: MB/s-->
			<LowBoundSpeed>20</LowBoundSpeed>
			<Location>M2_SATA1</Location>				
		</TestCase>
		
		<TestCase>
			<ProgramName>PCIESSD</ProgramName>
			<ErrorCode>TXS1T|PCIe function fail</ErrorCode>
			<!-- BySize:按容量大小測試, ByModel:按名稱測試 -->
			<TestMethod>ByModel</TestMethod>
			
			<!--R: read only, RW: Read and write-->
			<ReadWrite>RW</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			
			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>PCIESSD</Module>				
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>128</Case>
					<Case>256</Case>
					<Case>400</Case>
					<Case>800</Case>
				</Capacity>
				
				<Model>
					<Case>8086:0953</Case>
					<Case>126f:2260</Case>
					<Case>144d:a802</Case>
					<Case>144d:a808</Case>
				</Model>
			</ModelData>

			<Amount>5</Amount>				
			<!--LowBoundSpeed Unit: MB/s-->
			<LowBoundSpeed>400</LowBoundSpeed>
			<Location>OCULink1</Location>			
			<Location>OCULink2</Location>				
			<Location>OCULink3</Location>				
			<Location>OCULink4</Location>				
			<Location>M2SSD</Location>				
		</TestCase>

		<TestCase>
			<ProgramName>mSATA</ProgramName>
			<ErrorCode>TXS1U|SATA port test fail</ErrorCode>
			<!-- BySize:按容量大小測試, ByModel:按名稱測試 -->
			<TestMethod>ByModel</TestMethod>
			
			<!--R: read only, RW: Read and write-->
			<ReadWrite>RW</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			
			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>MSATA</Module>
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>8012</Case>
				</Capacity>
				
				<Model>
					<Case>UGBA.*</Case>
					<Case>UBA.*</Case>
				</Model>
			</ModelData>
			
			<!-- DefineFunc=(0/1 4),mSATA-->
			<Amount>1</Amount>
			<!--LowBoundSpeed Unit: MB/s-->
			<LowBoundSpeed>40</LowBoundSpeed>				
			<Location>mSATA1</Location>
		</TestCase>
		
		<TestCase>
			<ProgramName>SDCard</ProgramName>
			<ErrorCode>TXC02|SD/MS/CF Card test fail</ErrorCode>
			<!-- BySize:按容量大小測試, ByModel:按名稱測試 -->
			<TestMethod>ByModel</TestMethod>

			<!--R: read only, RW: Read and write-->
			<ReadWrite>RW</ReadWrite>
			<!--ParallelNumber: 并行測試硬盤數量，填1為逐個測試；不填則按CPU的核心數量並行測試-->
			<ParallelNumber>5</ParallelNumber>
			
			<!--Module:模塊描述,請不要修改此此參數-->
			<Module>SDCARD</Module>				
			<ModelData>
				<!--存儲設備型號和容量數據，by 型號測試時會使用到此數據-->
				<Capacity>
					<Case>8012</Case>
				</Capacity>
				
				<Model>
					<Case></Case>
				</Model>
			</ModelData>
			
			<!-- DefineFunc=(0 3), SD card-->
			<Amount>1</Amount>
			<!--LowBoundSpeed Unit: MB/s-->
			<LowBoundSpeed>20</LowBoundSpeed>
			<Location>SD1</Location>				
		</TestCase>	
	</Storage>
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
	Module=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Module" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]' )
	TestMethod=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/TestMethod" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]' )
	ReadWrite=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/ReadWrite" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]' )
	ParallelNumber=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/ParallelNumber" -n "${XmlConfigFile}" 2>/dev/null | tr '[a-z]' '[A-Z]' )
	
	CheckDrdy=$(xmlstarlet sel -t -v "//Storage/CheckDrdyBus" -n "${XmlConfigFile}" 2>/dev/null)
	DeviceAddr=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $1}'))
	DeviceGeneration=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $2}'))
	StdReadSpeed=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $3}'))
	Location=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null | awk -F'|' '{print $4}'))
	DeviceAmount=${#DeviceAddr[@]}
	if [ "${DeviceAmount}" == "0" ] ; then
		#按model或容量測試
		DeviceAmount=$(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Amount" -n "${XmlConfigFile}" 2>/dev/null )
		StdReadSpeed=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/LowBoundSpeed" -n "${XmlConfigFile}" 2>/dev/null))
		Location=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/Location" -n "${XmlConfigFile}" 2>/dev/null ))
	fi

	if [ "${DeviceAmount}" == "0" ] ; then
		Process 1 "Error config file: ${XmlConfigFile}"
		exit 3
	fi

	if [ "${#ParallelNumber}" == "0" ] || [ ${ParallelNumber} -le 0 ] ; then
		ParallelNumber=$(cat /proc/cpuinfo | grep -ic "processor")
	fi
	
	Capacity=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/ModelData/Capacity/Case" -n "${XmlConfigFile}" 2>/dev/null ))
	DeviceModelName=($(xmlstarlet sel -t -v "//Storage/TestCase[ProgramName=\"${BaseName}\"]/ModelData/Model/Case" -n "${XmlConfigFile}" 2>/dev/null ))
	AllDeviceModelName=($(xmlstarlet sel -t -v "//Storage/TestCase/ModelData/Model/Case" -n "${XmlConfigFile}" 2>/dev/null | sort -u ))
	return 0
}

CheckEnvironment()
{
	if [ $(grep -ic "release 6.[5-9]\|release [7-9].[0-9]" /etc/redhat-release  2>/dev/nul ) -ne 1 ]; then
		#The OS version should new than Linux 6.5
		Process 1 "The OS should new than Linux 6.5, e.g: 6.5,6.7,7.x"
		printf "%-10s%-60s\n" "" "Current OS version: `cat /etc/redhat-release 2>/dev/null | cut -c 1-50`"
		exit 4
	fi
}

DetectDrDyBusError ()
{
	local DrDyErrorFlag=0
	dmesg | grep -i "ata" | grep -iwq 'ata bus error' 2>/dev/null
	if [ $? == 0 ] ; then
		ShowMsg --b "Detected [ ATA bus error ] information"
		ShowMsg --e "Reset the OS and try again!"
		printf "\e[1;31m%-s\e[0m\n" "注意: 偵測到\"ATA bus error\"資訊!! 你可能需要重新開機或更換硬盤再試試看!"
		let DrDyErrorFlag++
		echo
	fi

	dmesg | grep -i "drdy.*.err" 2>/dev/null
	if [ $? == 0 ] ; then
		ShowMsg --b "Detected [ DRDY bus error ] information"
		ShowMsg --e "Reset the OS and try again!"
		printf "\e[1;31m%-s\e[0m\n" "注意: 偵測到\"DRDY bus error\"資訊!! 你可能需要重新開機或更換硬盤再試試看!"
		let DrDyErrorFlag++
	fi
	
	if [ ${#pcb} != 0 ] ; then
		cat ../PPID/${pcb}.log 2>/dev/null | grep -iwq "ata bus error\|drdy.*.err"
		if [ $? != 0 ] ; then
			dmesg | grep -i "ata" | grep -iw 'ata bus error' >> ../PPID/${pcb}.log
			dmesg | grep -i "ata" | grep -iw 'drdy.*.err' >> ../PPID/${pcb}.log
			sync;sync;sync
		fi
	fi
	
	echo "${CheckDrdy}" | grep -iwq "enable" 
	if [ "$?" == "0" ] ; then
		if [ ${DrDyErrorFlag} -gt 0 ] ; then
			let ErrorFlag++
			exit 4
		fi
	else
		if [ ${DrDyErrorFlag} -gt 0 ] ; then
			printf "\e[1;31m%-s\e[0m\n" "以上報錯已被忽略,但是該資訊將被記錄下來!!"
		fi
		DrDyErrorFlag=0
	fi
}

GetBootDisk ()
{
	BootDiskUUID=$(cat -v /etc/fstab | grep -iw "uuid" | awk '{print $1}' | sed -n 1p | cut -c 6-100 | tr -d ' ')
	# Get the main Disk Label
	# BootDiskUUID=7b862aa5-c950-4535-a657-91037f1bd457

	# BootDiskVolume=/dev/sda
	BootDiskVolume=$(blkid | grep -iw "${BootDiskUUID}" |awk '{print $1}'| sed -n 1p | awk '{print $1}' | tr -d ': ')
	#BootDiskVolume=$( echo $BootDiskVolume | cut -c 1-$((${#BootDiskVolume}-1))) 
	BootDiskVolume=$(lsblk | grep -wB30 "`basename ${BootDiskVolume}`" | grep -iw "disk" | tail -n1 | awk '{print $1}')
	BootDiskVolume=$(echo "/dev/${BootDiskVolume}" )
	
	# BootDiskSd=sda
	BootDiskSd=$(echo ${BootDiskVolume} | awk -F'/' '{print $NF}')
}

GetAmountByModelName ()
{
	DeviceModelNameString=$(echo ${DeviceModelName[@]} | sed 's/ /\\|/g')
	case ${Module} in
		PCIESSD)
			CurDeviceAmount=$(lspci -n | grep -ic "${DeviceModelNameString}")
		;;
		
		*)
			CurDeviceAmount=$(cat /proc/scsi/scsi | grep -iw "Model" | grep -ic "${DeviceModelNameString}")
		;;
		esac

	if [ "${CurDeviceAmount}" != "${DeviceAmount}" ]; then
		Process 1 "Check ${Module} device amount"
		printf "%-10s%-60s\n" "" "Current: ${CurDeviceAmount} Pcs , Standard should be: $DeviceAmount Pcs"
		ModelName=$(cat /proc/scsi/scsi | grep -iw "Model" | grep -i "${DeviceModelNameString}") 
		[ ${CurDeviceAmount} != 0 ] && echo "----------------------------------------------------------------------"
		case ${Module} in
			PCIESSD)
				lspci -n | grep -i "${DeviceModelNameString}"
			;;

			*)
				cat /proc/scsi/scsi | grep -iw "Model" | grep -i "${DeviceModelNameString}" | sort -s | cat -n 2>/dev/null
			;;
			esac

		[ ${CurDeviceAmount} != 0 ] && echo "----------------------------------------------------------------------"
		exit 1
	fi

}

GetPathByCapacity () 
{
	[ ! -d .temp ] && mkdir -p ${WorkPath}/.temp 2>/dev/null

	# Get a unique capacity: 40 40 60 120 250 --> 40\|60\|120\|250
	SoleCapacity=($(echo ${Capacity[@]} | tr ' ' '\n' | sort -u ))
	SoleCapacity=$(echo ${SoleCapacity[@]} | sed 's/ /\\|/g')

	# Get the /dev/sdX of storage device by Capacity,Get the Device Capacity information
	# Because of the same capacity:SATA SSD=256GB, M.2 SSD=256GB
	case ${Module} in
		PCIESSD|M2)
			#PCIE SSD,M.2 SSD
			DevType='/dev/nvme'
		;;
		
		SDCARD)
			#SD Card
			DevType='/dev/mm'
		;;
		
		SATA|SATADOM|CFCARD|MSATA)
			#SataAndSas/SATADOM/CFCard/mSATA
			DevType='/dev/sd'
		;;
		
		*)
			Process 1 "Unknown function defined: ${Module}"
			exit 3
		;;
		esac

	#Include the SATA,PCIE SSD,SD Card
	PathStrings="Disk /dev/nvme.*:\|Disk /dev/sd.:\|Disk /dev/mm.*:"
		
	DevPath=($(fdisk -l 2>/dev/null | grep -iw "${PathStrings}" | grep -i "${DevType}" | grep -w ${SoleCapacity} | awk '{print $2}' |tr -d ':'))
	# Remove the repeat paths,DevPath=(/dev/sda /dev/sdb /dev/sdc ...)
	DevPath=($(echo ${DevPath[@]} | tr ' ' '\n' | sort -u ))
	if [ "${#DevPath[@]}"x == "0"x ] ; then
		Process 1 "No found any device name: ${Module} "
		printf "%-10s%-60s\n" "" "${Module} include: "
		echo "${DeviceModelName[@]}" | tr ' ' '\n' | cat -n
		exit 2
	fi

	if [ "${#DevPath[@]}"x != "${DeviceAmount}"x ]; then 
		Process 1 "Check the amount of ${Module} device .."
		printf "%-10s%-60s\n" "" "Current: ${#DevPath[@]} Pcs , Standard: $DeviceAmount Pcs"

		echo "----------------------------------------------------------------------"
		for((R=0;R<${#DevPath[@]};R++))
		do
			let A=$R+1
			DevPathSN=$(hdparm -I ${DevPath[$R]} 2>/dev/null | grep -i "Serial Number" | awk '{print $3}')
			DevPathSN=${DevPathSN:-NULL}
			#Disk /dev/nvme0n1: 400.1 GB, 400088457216 bytes, 781422768 sectors
			DevPathInfo=$(fdisk -l 2>/dev/null | grep -iw "Disk ${DevPath[$R]}" | grep -w "${SoleCapacity}" | awk -v BLK='  ' '{print $1 BLK $2 BLK $3$4}')
			echo -e "\t$A\t${DevPathInfo}  SN: ${DevPathSN}" 2>/dev/null		
		done
		echo "----------------------------------------------------------------------"
		exit 2
	else
		rm -rf ${CurRelationship} 2>/dev/null
		#1:0:0:0|/dev/sda|4701|SATA1
		for((R=0;R<${#DevPath[@]};R++))
		do
			
			DevPathSN=$(hdparm -I ${DevPath[$R]} 2>/dev/null | grep -i "Serial Number" | awk '{print $3}')
			DevPathSN=${DevPathSN:-NULL}
			echo "|${DevPath[$R]}|${DevPathSN}|${Location[$R]}" >> ${CurRelationship}
			sync;sync;sync
		done
	fi
}

DefineKeyAddress()
{
	KeyAddress=()
	for ((E=0;E<${#DeviceAddr[@]};E++))
	do
		echo "${DeviceAddr[$E]}" | grep -iEq "^ata" 		&& KeyAddress[$E]=ATA
		echo "${DeviceAddr[$E]}" | grep -iEq "^host" 		&& KeyAddress[$E]=HOST
		echo "${DeviceAddr[$E]}" | grep -iEq "^target"		&& KeyAddress[$E]=TARGET
		echo "${DeviceAddr[$E]}" | grep -iEq "^[0-9]{1,3}"	&& KeyAddress[$E]="[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}"
		echo "${DeviceAddr[$E]}" | grep -iEq "^mmc"			&& KeyAddress[$E]="MMC[0-9]\{1,2\}"
		echo "${DeviceAddr[$E]}" | grep -iEq "^nvme"		&& KeyAddress[$E]="nvme[0-9]\{1,2\}"
		echo "${DeviceAddr[$E]}" | grep -iEq "^[0-9A-F]{4}"	&& KeyAddress[$E]="[0-9A-F]\{4\}:[0-9A-F]\{2\}:[0-9A-F]\{2\}.[0-9A-F]"

		echo "${DeviceAddr[$E]}" | grep -iq "${KeyAddress[$E]}" 2>/dev/null
		if [ $? != 0 ] ; then
			Process 1 "Wrong config word: ${DeviceAddr[$E]}"
			let ErrorFlag++
		fi
	done
	if [ "${ErrorFlag}" != 0 ] ; then
		exit 4
	else
		return 0
	fi
}

ShowDetectDeviceResult ()
{
	echo "${#Location[@]}" | grep -iq "usb"
	if [ $? == 0 ] ; then
		Process 1 "Current ${ShellFile} is not suitable for USB function test"
		exit 3	
	fi

	# ata1|/dev/sda|4562(Last 4bit SN)
	rm -rf ${CurRelationship} 2>/dev/null

	# ata1|Gen3.0|200|miniSAS-3-0,address=ata1
	# host0/target0:0:0/0:0:0:0/block/sda 
	[ ! -d .temp ] && mkdir -p ${WorkPath}/.temp 2>/dev/null

	DefineKeyAddress

	# ../devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0/block/sda
	# ../devices/pci0000:00/0000:00:1b.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0
	# ../devices/pci0000:ae/0000:ae:02.0/0000:b0:00.0/nvme/nvme0/nvme0n1
	# ../devices/pci0000:ae/0000:ae:03.0/0000:b1:00.0/nvme/nvme1/nvme1n1

	for ((F=0;F<${#DeviceAddr[@]};F++))
	do
		# KeyAddress,eg.: ata2
		Block2DeviceAddr[$F]=$(ls -l /sys/block/ | grep -iw "${DeviceAddr[$F]}" | tr '/' '\n' | grep -v ">" | grep  -iA20 "${KeyAddress[$F]}" | head -n1 )

		# sda
		Block2DeviceName[$F]=$(ls -l /sys/block/ | grep -iw "${DeviceAddr[$F]}" | tr '/' '\n' | grep  -iA20 "${KeyAddress[$F]}" | tail -n1 )
		DeviceSN[$F]=$(hdparm -I "/dev/${Block2DeviceName[$F]}" 2>/dev/null | grep -i "Serial Number" | head -n1 | awk '{print $3}') 	
		# 1:0:0:0|/dev/sda|4701|SATA1 --> ${CurRelationship}
		if [ ${#Block2DeviceAddr[$F]} == 0 ] ; then
			echo "NULL|NULL|NULL|${Location[$F]}">> ${CurRelationship}
		else
			echo "${Block2DeviceAddr[$F]}|/dev/${Block2DeviceName[$F]}|${DeviceSN[$F]:0-4:4}|${Location[$F]}">> ${CurRelationship}
		fi
		
		sync;sync;sync
	done

	# DevPath=(/dev/sda /dev/sdb /dev/sdc ...)
	SolePcbMarking=($(echo ${Location[@]} | tr ' ' '\n' | sort -u ))
	SolePcbMarking=$(echo ${SolePcbMarking[@]} | sed 's/ /\\|/g')
	DevPath=($(cat ${CurRelationship} | grep -w ${SolePcbMarking} | awk -F'|' '{print $2}' | sort -u ))
	echo 
}

GetDeviceGeneration ()
{
	local TargetDeviceAddr=$1                        # Addr
	local StdGeneration=$(echo $2 | tr -d [A-Za-z])  #Gen3.0, 6.0 Gbps,or Gbps
	# Usage: GetDeviceGeneration 1:1:0:0 SATA1 /dev/sda 6.0 

	echo  "${TargetDeviceAddr}" | grep -iq "nvme\|mmc"
	if [ $? == 0 ] || [ "${#StdGeneration}" == "0" ] ; then
		echo "0.0 pass"
		return 0
	fi

	local TargetKeyAddress=NULL
	echo "${TargetDeviceAddr}" | grep -iEq "^ata" 			&& TargetKeyAddress=ATA
	echo "${TargetDeviceAddr}" | grep -iEq "^host" 			&& TargetKeyAddress=HOST
	echo "${TargetDeviceAddr}" | grep -iEq "^target"		&& TargetKeyAddress=TARGET
	echo "${TargetDeviceAddr}" | grep -iEq "^[0-9]{1,3}"	&& TargetKeyAddress="[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}:[0-9]\{1,3\}"
	echo "${TargetDeviceAddr}" | grep -iEq "^mmc"			&& TargetKeyAddress="MMC[0-9]\{1,2\}"
	echo "${TargetDeviceAddr}" | grep -iEq "^nvme"			&& TargetKeyAddress="nvme[0-9]\{1,2\}"
	echo "${TargetDeviceAddr}" | grep -iEq "^[0-9A-F]{4}"	&& TargetKeyAddress="[0-9A-F]\{4\}:[0-9A-F]\{2\}:[0-9A-F]\{2\}.[0-9A-F]"

	# ../devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0/block/sda
	# ../devices/pci0000:00/0000:00:1b.0/mmc_host/mmc0/mmc0:e624/block/mmcblk0
	# ../devices/pci0000:ae/0000:ae:02.0/0000:b0:00.0/nvme/nvme0/nvme0n1
	# ../devices/pci0000:ae/0000:ae:03.0/0000:b1:00.0/nvme/nvme1/nvme1n1

	# ata1, host0, target0:0:0; 0:0:0:0
	Block2DeviceAddr=$(ls -l /sys/block/ | grep -iw "${TargetDeviceAddr}" | tr '/' '\n' | grep -v ">" | grep  -iA20 "${TargetKeyAddress}" | head -n1 )
	Block2DeviceAddrID=$(echo ${Block2DeviceAddr} | awk -F':' '{print $1}' | tr -d [[:alpha:]] )

	[ "${TargetKeyAddress}" != "ATA" ] && let Block2DeviceAddrID++
	#DeviceVolAddr=$(echo ata${Block2DeviceAddrID})   #e.g.: ata2
	DeviceVolAddr=$(ls -l /sys/block/ | grep -iw "${TargetDeviceAddr}" | tr '/' '\n' | grep -iwE "ata[0-9]{1,3}")
	DeviceVolAddr=${DeviceVolAddr:-"NULL_STRING"}
	CurGenSpeed=$(dmesg | grep -i sata | grep -iw "${DeviceVolAddr}:" | grep "link up" |awk -F'link up' '{print $2}' | awk '{print $1}' | tr -d [A-Za-z] | tr -d ' ' | tail -n1 )
	CurGenSpeed=${CurGenSpeed:-0.0}
	GenUnit=$(dmesg | grep -i sata | grep -iw "${DeviceVolAddr}:" | grep "link up" |awk -F'link up ' '{print $2}' | awk '{print $2}' | tr -d [.0-9] | tr -d ' ' | tail -n1 )
	GenUnit=${GenUnit:-"Gbps"}
	case $StdGeneration in
		1.0)StdGenSpeed=1.5;;
		2.0)StdGenSpeed=3.0;;
		3.0)StdGenSpeed=6.0;;
		*)
			echo "Invalid generation: Gen${StdGeneration}"
			exit 3
		;;
		esac

	echo CurGenSpeed = $CurGenSpeed
	echo StdGenSpeed = $StdGenSpeed
	pause
	 
	echo "${CurGenSpeed}>=${StdGenSpeed}" | bc | grep -wq "1"
	if [ "$?" == 0 ] ; then
		printf "%-s" "${StdGenSpeed} pass"
	else
		echo "${CurGenSpeed}>0.0" | bc | grep -wq "1"
		if [ "$?" == 0 ] ; then
			printf "%-s" "${CurGenSpeed} fail"
		else
			printf "%-s" "${CurGenSpeed} error"
		fi
		return 1
	fi
}

GetDevicePath ()
{
	local TargetDevice=$1
	# TargetDevice=/dev/sda ...

	<<-FDISK
	Disk /dev/nvme0n1: 400.1 GB, 400088457216 bytes, 781422768 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0x00000000

			Device Boot      Start         End      Blocks   Id  System
	/dev/nvme0n1p1              63   781417664   390708801   83  Linux

	Disk /dev/nvme1n1: 400.1 GB, 400088457216 bytes, 781422768 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0xcd3de4ad

			Device Boot      Start         End      Blocks   Id  System
	/dev/nvme1n1p1            2048      206847      102400   83  Linux
	/dev/nvme1n1p2          206848   781422767   390607960   83  Linux

	Disk /dev/sda: 60.0 GB, 60022480896 bytes, 117231408 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0x000bf75c

	   Device Boot      Start         End      Blocks   Id  System
	/dev/sda1   *        2048     1026047      512000   83  Linux
	/dev/sda2         1026048    63940607    31457280   83  Linux
	/dev/sda3        63940608    63944703        2048   82  Linux swap / Solaris


	Disk /dev/mmcblk0: 3965 MB, 3965190144 bytes, 7744512 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0x00000000

			Device Boot      Start         End      Blocks   Id  System
	/dev/mmcblk0p1            2048     7744511     3871232   83  Linux

	FDISK

	# as above, FullVolnumeNum = /dev/sda3, VolnumeNum=3 
	FullVolnumeNum=($(fdisk -l 2>/dev/null | grep "${TargetDevice}" | grep -v "^Disk" | awk '{print $1}' | tr -d ' ' | sort -r ))
	[ ! -d /home ] && mkdir -p /home >/dev/null 2>&1

	FullDevPath=''
	for((p=0;p<${#FullVolnumeNum[@]};p++))
	do
		umount /home >/dev/null 2>&1
		ls ${FullVolnumeNum[$p]} >/dev/null 2>&1
		if [ $? == 0 ] ; then
			mount "${FullVolnumeNum[$p]}" /home #>/dev/null 2>&1
			if [ $? != 0 ] ; then
				continue
			else
				# Return value
				FullDevPath="${FullVolnumeNum[$p]}"
				break
			fi
		else
			continue
		fi
	done

	if [ ${#FullDevPath} == 0 ] ; then
		printf "%-s\n" "NG"
		FullDevPath=${FullVolnumeNum[${#FullVolnumeNum[@]}-1]}
		return 1
	else
		printf "%-s\n" "OK"
		return 0
	fi
}

GetPcieSSDSerialNumber ()
{
	local TargetNvmeAddr=$1
	local BusID=$(ls -l /sys/block/ | grep -iw "${TargetNvmeAddr}" | tr '/' '\n' | grep -v ">" | grep -iEw "[0-9A-F]{2}:[0-9A-F]{2}.[0-9A-F]" | tail -n1 | cut -c 6-)
	local NvmeSN=$(lspci -n -s ${BusID} -vvv 2>/dev/null | grep -iw "serial number" | awk '{print $NF}' | tr -d '-')
	NvmeSN=${NvmeSN:-"Nvme"}
	
	printf "%-s\n" "${NvmeSN}" | tr '[a-z]' '[A-Z]'
}

FormatDevice ()
{
	local TargetDevice=$1
	# Define Argument TargetDevice= /dev/sdX
	# Usage
	if [ -z "$TargetDevice" ] ; then
		echo "Usage: FormatDevice /dev/sdX"
		exit 3
	fi

	if [ $(echo "${TargetDevice}" | grep -ic "${BootDiskVolume}") -gt 0 ] ; then
		Process 1 "Warnning !! ${TargetDevice} is the boot disk ..."
		return 0
	fi

	local TargetDeviceSN=$(hdparm -I ${TargetDevice} 2>/dev/null | grep -i "Serial Number" | awk '{print $3}')
	echo -e "\e[1;31mBegin to format ${TargetDevice},SN: ${TargetDeviceSN} ...\e[0m"
	Wait4nSeconds 5 

	# Format the device
	FormatResult="failure"
	dd if=/dev/zero of=${TargetDevice} bs=512 count=1 >/dev/null 2>&1 &&
	echo -e "n\np\n1\n\n+100M\nn\np\n2\n\n\nw\n" | fdisk ${TargetDevice} >/dev/null 2>&1 &&
	GetDevicePath ${TargetDevice} 
	if [ $? != 0 ] ; then
		mkfs.ext2 ${FullDevPath} >/dev/null 2>&1 && FormatRresult="success"
	fi

	echo
	#echo -e "n\ne\n1\n\n+100M\nn\nl\n\n\nt\n5\nb\nw\n" | fdisk ${device} >/dev/null 2>&1

	# Check disk is ok?
	[ ! -d /home/ ] && mkdir -p /home 2>/dev/null
	umount /home/ >/dev/null 2>&1
	mount ${FullDevPath} /home/ >/dev/null 2>&1
	if [ $? == 0 ] ; then
		Process 0 "${TargetDevice}, SN: ${TargetDeviceSN} formated"
		umount /home/ >/dev/null 2>&1
		return 0
	else
		Process 1 "${TargetDevice}, SN: ${TargetDeviceSN} mount /home"
		[ $FormatResult == "failure" ] && Process 1 "${TargetDevice}, SN: ${TargetDeviceSN} formated"
		return 1
	fi
}

ReadWriteTest ()
{
	PPIDKILL=$$
	if [ ${ParallelNumber} != 1 ] ; then
		printf "%s\n" "Begin to test ..."
		for ((c=1;c<=${DeviceAmount};c++))
		do
			local TestDeviceName=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $2}')
			# BootDisk 也可以测试读的动作
			#if [ ${TestDeviceName} == NULL ] || [ "${TestDeviceName}"x == "${BootDiskVolume}"x ] ; then
			if [ ${TestDeviceName} == NULL ] ; then
				continue
			fi
			local LogName=$(basename ${TestDeviceName})
			rm -rf  ${LogName}.log 2>/dev/nul
			hdparm -t ${TestDeviceName} 2>/dev/null > ${LogName}.log &
			printf "%s" "${TestDeviceName} "
			if [ $((c%ParallelNumber)) == 0 ] ; then
				for((s=1;s>0;s++))
				do
					ChildenProcesses=($(pgrep -P ${PPIDKILL} hdparm))
					if [ ${#ChildenProcesses[@]} == 0 ] ; then
						echo
						break
					else
						sleep 1s
						printf "%s" ">"
						if [ $((s%70)) == 0 ] ; then
							printf "\r%s\r" "                                                                       "
						fi
					fi
				done
			fi
		done
		
		printf "\n%s\n" "Please wait a moment ..."
		for((s=1;s>0;s++))
		do
			ChildenProcesses=($(pgrep -P ${PPIDKILL} hdparm))
			if [ ${#ChildenProcesses[@]} == 0 ] ; then
				echo
				break
			else
				sleep 1s
				printf "%s" ">"
				if [ $((s%70)) == 0 ] ; then
					printf "\r%s\r" "                                                                       "
				fi
			fi
		done
		sync;sync;sync
		wait
	fi	
	ShowTitle "Storage function test"
	#No Location     Device            SN       Gen      Read Spd     Result
	#----------------------------------------------------------------------
	#01 SATA1        /dev/mmcblk0p1   4527      1.5      245 MB/s      Pass
	#02 SATA1        /dev/sdc         4522      3.0      243 MB/s      Pass
	#03 SATA1        /dev/sdc         4522      6.0      145 MB/s      Skip
	#----------------------------------------------------------------------

	printf "%-3s%-13s%-18s%-9s%-9s%-13s%-7s\n" "No" "Location"  "Device"  "SN" "Gen" "Read Spd"  "Result"
	echo "------------------------------------------------------------------------"
	for ((c=1;c<=${DeviceAmount};c++))
	do
		local rwErrorFlag=0
		# ${CurRelationship} >> 1:0:0:0|/dev/sda|4701|SATA1
		local TestDeviceAddr=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $1}')
		local TestDeviceName=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $2}')
		local TestDeviceSN=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $3}')
		local LogName=$(basename ${TestDeviceName})

		if [ ${#TestDeviceSN} == 0 ] ; then
			TestDeviceSN=$(GetPcieSSDSerialNumber "${TestDeviceAddr}")
		fi

		local TestDeviceMarking=$(sed -n ${c}p ${CurRelationship} | awk -F'|' '{print $4}')
		if [ ${TestDeviceName} == NULL ] ; then
			printf "%02d%-1s%-13s%-17s%-10s%-9s%-14s\e[1;31m%-6s\e[0m\n" "${c}" "" "${TestDeviceMarking}" "NULL" "NULL" "---" "--------" "Fail"
			let ErrorFlag++
			continue 
		fi
		
		printf "%02d%-1s%-13s%-17s%-10s" "${c}" "" "${TestDeviceMarking}" "${TestDeviceName}" "${TestDeviceSN:0-4:4}"
		# BootDisk 一并参与测试
		#if [ "${TestDeviceName}"x == "${BootDiskVolume}"x ] ; then
		#	printf "%-9s%-14s\e[1;33m%-6s\e[0m\n" "---" "BootDisk" "Skip"
		#	continue
		#fi

		# Check then generation
		if [ ${#TestDeviceAddr} != 0 ]; then

			GetDeviceGeneration "${TestDeviceAddr}" "${DeviceGeneration[c-1]}"
			#local TestGen=($(GetDeviceGeneration "${TestDeviceAddr}" "${DeviceGeneration[c-1]}"))
			echo TestGen = $TestGen
			if [ "${TestGen[0]}" == "0.0" ]; then
				CurGen=0.0
			else
				CurGen=$(printf "%s\n" "${TestGen[0]}/3.0+1" | bc)
			fi
			
			if [ ${TestGen[1]} == error ] ; then
				printf "\e[1;31m%-9s\e[0m%-14s\e[1;31m%-6s\e[0m\n" "`printf "%.1f" "${CurGen}"`" "--------" "Fail"
				let ErrorFlag++
				continue
			elif [ ${TestGen[1]} == fail ] ; then
				printf "\e[1;31m%-7s\e[0m"  "`printf "%.1f" "${CurGen}"`"
				let ErrorFlag++
				let rwErrorFlag++			
			else
				printf "%-9s"  "`printf "%.1f" "${CurGen}"`"
			fi
		else
			printf "%-9s" "---"
		fi
		
		# Unmount Device and Remove the folder
		#2023-03-06 取消如下三行指令，测试中有发现此位置指令导致测试时测试hang up
		#umount /mnt/$DiskPath >/dev/null 2>&1
		#rm -rf /mnt/$DiskPath >/dev/null 2>&1
		#mkdir -p /mnt 2>/dev/null

		# Get the read speed
		if [ ! -f "${LogName}.log" ] ; then
			CurReadSpeed=$(hdparm -t ${TestDeviceName} 2>/dev/null | grep "MB/sec" | awk -F'=' '{print $2}' | awk -F'.' '{print $1}' | tr -d ' ')
		else
			CurReadSpeed=$(cat ${LogName}.log 2>/dev/nul | grep "MB/sec" | awk -F'=' '{print $2}' | awk -F'.' '{print $1}' | tr -d ' ')
		fi
		CurReadSpeed=${CurReadSpeed:-0}
		local StdReadSpeed_c=0
		if [ "${StdReadSpeed[c-1]}"x = "x" ] ; then
			StdReadSpeed_c=${StdReadSpeed[0]}
		else
			StdReadSpeed_c=${StdReadSpeed[c-1]}
		fi
		echo "${CurReadSpeed}>=${StdReadSpeed_c}" | bc | grep -wq "1"
		if [ $? == 0 ] ; then
			printf "%-14s" "${CurReadSpeed} MB/s"
		else
			printf "\e[1;31m%-14s\e[0m\e[1;31m%-6s\e[0m\n"  "${CurReadSpeed} MB/s" "Fail"
			let ErrorFlag++
			continue
		fi

		# For TL396,read only
		# fdisk -l 2>/dev/null | grep "Disk ${TestDeviceName}" | grep "GB" | grep -iwq "40.0" 
		hdparm -I "${TestDeviceName}" 2>/dev/null | grep -iwq "TL396"
		if [ $? == 0 ] ; then
			printf "\e[1;32m%-6s\e[0m\n" "Pass"
			continue
		fi
		
		echo "${ReadWrite}" | grep -iwq "R"
		if [ $? == 0 ]; then 
			if [ ${rwErrorFlag} == 0 ] ; then
				printf "\e[1;32m%-6s\e[0m\n" "Pass"
			else
				printf "\e[1;31m%-6s\e[0m\n" "Fail"
				let ErrorFlag++
			fi
			continue
		fi
		
		# Mount the disk
		#MountTest=`GetDevicePath ${TestDeviceName}`
		#echo "$MountTest" | grep -iwq "ok"
		GetDevicePath ${TestDeviceName} >/dev/null 2>&1
		if [ $? != 0 ] ; then
			printf "\e[1;31m%-6s\e[0m\n" "Fail"
			let ErrorFlag++
			continue
		fi		
		
		DiskPath=$(echo "${FullDevPath}disk${b}" | tr -d '/')
		[ ! -d "/mnt/${DiskPath}" ] && mkdir -p /mnt/${DiskPath} 2>/dev/null
		umount /mnt/${DiskPath} >/dev/null 2>&1
		mount ${FullDevPath} /mnt/${DiskPath} >/dev/null 2>&1
		if [ $? != 0 ]; then
			printf "\e[1;31m%-6s\e[0m\n" "Fail"
			continue		
		else
			:
		fi
		
		# Copy Files
		CopyErrorFlag=0
		[ ! -d "${WorkPath}/FILES" ] && mkdir -p ${WorkPath}/FILES 2>/dev/null
		for ((p=1;p<=3;p++))
		do
			if [ ! -s "${WorkPath}/FILES/FILE$p.TST" ] ; then
				let Size=${p}*100+68
				dd if=/dev/zero of=${WorkPath}/FILES/FILE$p.TST bs=1K count=${Size} >/dev/null 2>&1
				sync;sync;sync
			fi
			
			cp -f ${WorkPath}/FILES/FILE$p.TST /mnt/${DiskPath}/FILE$p.TST 2>/dev/null
			sync;sync;sync

			# Compare File
			CheckResult=$(diff ${WorkPath}/FILES/FILE$p.TST /mnt/${DiskPath}/FILE$p.TST 2>/dev/null)
			if [ "${#CheckResult}" != 0 ]; then
				let CopyErrorFlag++
				continue
			fi
		done
		if [ ${CopyErrorFlag} == 0 ] ; then
			printf "\e[32m%-6s\e[0m\n"  "Pass"
		else
			printf "\e[1;31m%-6s\e[0m\n" "Fail"
		fi
	done
	echo "------------------------------------------------------------------------"
	[ $ErrorFlag != 0 ] && return 1
	rm -rf *.log 2>/dev/null

}

ShowDeviceModelName ()
{
	DeviceModelNameString=$(echo ${AllDeviceModelName[@]} | sed 's/ /\\|/g')
	CurDeviceAmount=$(cat /proc/scsi/scsi | grep -iw "Model" | grep -ic "${DeviceModelNameString}")
	cat /proc/scsi/scsi | grep -iw "Model" | grep -i "${DeviceModelNameString}" | sort -u 2>/dev/null
}

main()
{
	DetectDrDyBusError
	#CheckEnvironment
	GetBootDisk

	case ${TestMethod} in
		BYSIZE)
			GetPathByCapacity
		;;
		
		BYMODEL)
			GetAmountByModelName
			GetPathByCapacity
		;;

		BYADDR)
			ShowDetectDeviceResult
		;;

		*)
			echo "Invalid option: $TestMethodID"
			exit 3
		esac

	ReadWriteTest

	if [ ${ErrorFlag} != 0 ] ; then
		echoFail "${BaseName} functional test"
		GenerateErrorCode
		exit 1
	else
		# If pass ,show the model name
		ShowDeviceModelName
		echo
		echoPass "${BaseName} functional test"
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare CurRelationship=".temp/${BaseName}Relationship.log"
declare -i ErrorFlag=0
declare -a DeviceModelName=()
declare CheckDrdy=enable
declare LowBoundSpeed=60  #Define the default value
declare XmlConfigFile Capacity 
declare BootDiskVolume BootDiskSd DeviceAmount ApVersion
declare DevPath Location DeviceGeneration FullDevPath StdReadSpeed DevType Module ReadWrite PathStrings ParallelNumber
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :f:P:VDx: argv
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
		
		f)
			FormatDevice ${OPTARG}
			exit 5
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,StoragePortTest"
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
