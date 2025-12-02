#!/bin/bash
#FileName : cNetworkStress.sh/sNetworkStress.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.2"
	local CreatedDate="2020-10-26"
	local UpdatedDate="2020-11-06"
	local Description="Network Stress test by iPerf3"
	
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
	printf "%16s%-s\n" "" "2020-11-06,新增多個Link speed的設置;動態獲取IP的功能;修改兩台PC對聯調速掉網問題"
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
	local ErrorCode=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet iperf3 ethtool)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			iperf3)printf "%10s%s\n" "" "Please install: iperf3-3.1.6-1.el7.x86_64.rpm";;
		esac
		
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
	eg.: `basename $0` -x lConfig.xml (begin with 's' letter for Server-side)
	eg.: `basename $0` -x lConfig.xml (begin with 'c' letter for Client-side)
	eg.: `basename $0` -D
	eg.: `basename $0` -V

	-D : Dump the sample xml config file	
	-x : config file,format as: *.xml
	-V : Display version number and exit(1)
		
	return code:
	   0 : Network stress iperf test pass
	   1 : Network stress iperf test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	

HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
	<NetCard>
		<TestCase>
			<!--帶c開頭的為Clint端(放在客戶端上),s開頭的為Server端(放在服務端上)-->
			<ProgramName>${BaseName}</ProgramName>
			<ErrorCode>NXI23|CANT CONNECT TO INTERNET WITH INTERNAL LAN JACK</ErrorCode>
			
			<!--以下參數置空則不啟用,部分參數是必須參數,置空則程式報錯-->
			<Common>
				<!--#,设置端口,与服务器端的监听端口一致。默认是5201端口,与ttcp的一样-->
				<Port>5201</Port>
				
				<!--根據需要填bkmgaBKMGA,含義如下小寫字母則單位為bits/sec,大寫則為Bytes/sec,如'b' = bits/sec 'B' = Bytes/sec-->
				<Format>m</Format>
				<!--#,设置每次报告之间的时间间隔，单位为秒。如果设置为非零值，就会按照此时间间隔输出测试报告。默认值为零。-->
				<Interval>1</Interval>
				<!--使用特定的数据流测量带宽，例如指定的文件。-->
				<!--client-side: read from the file and write to the network, instead of using random data;-->
				<!--server-side: read from the network and write to the file, instead of throwing the data away.-->
				<!--使用特定的数据流测量带宽，例如指定的文件(如果使用#K/M命名,文件不存在的則自動生成)。-->
				<FileToRW>/20M.log</FileToRW>
				<!--绑定到主机的多个地址中的一个。对于客户端来说，这个参数设置了出栈接口。对于服务器端来说，这个参数设置入栈接口。-->
				<!--这个参数只用于具有多网络接口的主机。在Iperf的UDP模式下，此参数用于绑定和加入一个多播组。-->
				<!--使用范围在224.0.0.0至239.255.255.255的多播地址。参考-T(Title)参数。-->
				<BindHost>1</BindHost>	
				<!--将输出存到如下指定文件,程式自動加日期時間前綴-->
				<LogFile>/iperf_t.log</LogFile>
			</Common>
			
			<Server>
				<!--通過MAC地址定位網孔,缺省的時候則由測試選擇-->
				<MacAddrFile>/TestAP/Scan/MAC1.TXT</MacAddrFile>
				<!--設置服務端地址, 缺省或DHCP則程式自動獲取,在Client端的Server IP地址必須是明確的-->
				<IPaddress>192.168.1.10</IPaddress>
				<SubnetMask>255.255.255.0</SubnetMask>
			</Server>
			
			<Client>
				<!--通過MAC地址定位網孔,缺省的時候則由測試選擇-->
				<MacAddrFile>/TestAP/Scan/MAC1.TXT</MacAddrFile>
				<!--設置客戶端地址, 缺省或DHCP則程式自動獲取-->
				<IPaddress>192.168.1.11</IPaddress>
				<SubnetMask>255.255.255.0</SubnetMask>
				<!--確認網卡的速率,速率不一致的程式自動設置到一致,無法設置到一致的按FAIL處理,請填寫10/100/1000/10000等數值-->
				<LinkSpeed>10 100 1000</LinkSpeed>
				<!--on/off: 設置網卡是否自動協商-->
				<Autoneg>on</Autoneg>
				<!--half/full: 設置網卡半雙工/全雙工-->
				<Duplex>full</Duplex>
			
				<!--disable/enable: 禁用(就是TCP)或啟用；使用UDP方式而不是TCP方式。参看-b选项-->
				<UDP>disable</UDP>
				<!--#[KM],UDP模式使用的带宽，单位bits/sec。此选项与-u选项相关。默认值是1 Mbit/sec-->
				<Bandwidth>1000M</Bandwidth>
				<!--#[KMG],传送的缓冲器数量。通常情况，Iperf按照10秒钟发送数据。-n参数跨越此限制,-->
				<!--按照指定次数发送指定长度的数据，而不论该操作耗费多少时间。参考-l(BuffersLength)与-t(Time)选项。-->
				<!--Number和Time同時設置，Time有效-->
				<Number>60K</Number>
				<!--#,设置传输的总时间。Iperf在指定的时间内，重复的发送指定长度的数据包。默认是10秒钟。参考-l与-n选项。-->
				<Time>60</Time>
				<!--#[KM],设置读写缓冲区的长度。TCP方式默认为8KB，UDP方式默认为1470字节-->
				<BuffersLength>8K</BuffersLength>
				<!--#,线程数。指定客户端与服务端之间使用的线程数。默认是1线程。需要客户端与服务器端同时使用此参数。-->
				<Parallel>10</Parallel>
				<!--#[KM],设置套接字缓冲区为指定大小，需要指定單位。对于TCP方式，此设置为TCP窗口大小。-->
				<!--对于UDP方式，此设置为接受UDP数据包的缓冲区大小，限制可以接受数据包的最大值。-->
				<Window>128K</Window>
				<!--#[KM]输出TCP MSS值（通过TCP_MAXSEG支持）。MSS值一般比MTU值小40字节。通常情况-->
				<MssSet>40K</MssSet>
				<!--運行在反向模式,服務器發，客戶端收：enable則正向測試一次,反向測試一次-->
				<Reverse>disable</Reverse>
				<!--设置TCP无延迟选项，禁用Nagle's运算法则。通常情况此选项对于交互程序，例如telnet，是禁用的。-->
				<Nodelay>disable</Nodelay>
				<!--IP地址的版本version4(4)/version6(6)-->
				<IPv46>version4</IPv46>
				<!--獲取Server端的輸出-->
				<GetServerOutput>enable</GetServerOutput>
				<!--省略前面N秒鐘，測試數據更準確-->
				<OmitNseconds>2</OmitNseconds>
				<!--prefix every output line with this string-->
				<Title>S283_JLAN1</Title>
			</Client>
			
			<ParseLog>
				<!--僅在Client side解析-->
				<PassCondition>
					<!--帶寬單位: K/M/G + Bytes/sec or bits/sec -->
					<MinBandwidth>900Mbits/sec</MinBandwidth>
					<!--以下在UDP模式測試有效, TCP模式測試以下參數不被識別-->
					<!--允許最小丟包率-->
					<MinPacketLossRate>1%</MinPacketLossRate>
					<!--允許最大抖動時間,可選測試項目-->
					<MaxJitter>0.8ms</MaxJitter>
				</PassCondition>
				
				<Except>
					<!--如下測試記錄細節不能在log內有記錄, 否則測試Fail-->
					<Item>error - the server has terminated</Item>
				</Except>
			</ParseLog>
		</TestCase>
	</NetCard>
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
	
	# Confirm the first letter is c(client) or s(server)
	ExecuteSite=$(echo ${BaseName:0:1} | tr '[A-Z]' '[a-z]')
	if [ "${ExecuteSite}" != "c" ] ; then
		if [ "${ExecuteSite}" != "s" ] ; then
			Process 1 "Invalid shell name: ${ShellFile}"
			printf "%10s%s\n" "" "The shell file name should begin with letter 'c' or 's'."
			exit 3
		fi
	fi
	
	# Get the information from the config file(*.xml)
	# COMMON OPTIONS
	ListenPort=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Common/Port" -n "${XmlConfigFile}" 2>/dev/null)
	Format=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Common/Format" -n "${XmlConfigFile}" 2>/dev/null)
	Interval=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Common/Interval" -n "${XmlConfigFile}" 2>/dev/null)
	FileToRW=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Common/FileToRW" -n "${XmlConfigFile}" 2>/dev/null)
	BindHost=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Common/BindHost" -n "${XmlConfigFile}" 2>/dev/null)
	LogFile=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Common/LogFile" -n "${XmlConfigFile}" 2>/dev/null)
	
	#僅Client端可以設置link speed
	LinkSpeed=($(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/LinkSpeed" -n "${XmlConfigFile}" 2>/dev/null))
	MaxLinlkSpeed=$(echo ${LinkSpeed[@]} | tr ' ' '\n' | sort -ns | tail -n1 )
	MinLinlkSpeed=$(echo ${LinkSpeed[@]} | tr ' ' '\n' | sort -ns | head -n1 )
	
	Autoneg=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Autoneg" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
	Duplex=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Duplex" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')
	
	echo "${ListenPort}" | grep -iwEq "[0-9]{4,6}"
	if [ $? != 0 ]; then
		Process 1 "Invalid listen port: ${ListenPort} "
		printf "%10s%s\n" "" "The listen port range should be: 1000~99999"
		let ErrorFlag++
	else
		COMMON_OPTIONS[0]=$(echo "--port ${ListenPort}")
	fi
	
	echo "${Format}" | grep -wEq "[BbKkMmGg]"
	if [ $? != 0 ]; then
		Process 1 "Invalid format to print bandwidth numbers: ${Format} "
		printf "%10s%s\n" "" "The bandwidth numbers should be: B/b/K/k/M/m/G/g"
		let ErrorFlag++
	else
		COMMON_OPTIONS[1]=$(echo "--format ${Format}")
	fi
	
	if [ ${#Interval} != 0 ] ; then
		echo "${Interval}" | grep -wEq "[0-9]{1,4}"
		if [ $? != 0 ]; then
			Process 1 "Invalid interval time: ${Interval} "
			printf "%10s%s\n" "" "The interval time should be: 0-9999"
			let ErrorFlag++
		else
			COMMON_OPTIONS[2]=$(echo "--interval ${Interval}")
		fi		
	fi
	
	if [ ${#FileToRW} != 0 ] ; then
		if [ ! -f "${FileToRW}" ] ;then
			local FileToRWBasename=$(basename ${FileToRW} | awk -F'.' '{print $1}' | tr '[a-z]' '[A-Z]')
			echo ${FileToRWBasename} | grep -wEq "[0-9]{1,9}[KMG]"
			if [ $? == 0 ] ; then
				local FileToRWSize=$(echo ${FileToRWBasename} | tr -d '[A-Za-z]')
				local FileToRWUnit=$(echo ${FileToRWBasename} | tr -d '[0-9]')
				echo "Create the file: ${FileToRW}, please wait a mount ..."
				dd if=/dev/zero of=${FileToRW} bs=1${FileToRWUnit} count=${FileToRWSize} >&/dev/null
				sync;sync;sync
				if [ -f "${FileToRW}" ] ; then
					Process 0 "Created the file: ${FileToRW}"
					COMMON_OPTIONS[3]=$(echo "--file  ${FileToRW}")
				else
					Process 1 "Fail to create the file: ${FileToRW}"
					let ErrorFlag++
				fi
			else
				Process 1 "No such file: ${FileToRW}"
				let ErrorFlag++
			fi
		else
			COMMON_OPTIONS[3]=$(echo "--file  ${FileToRW}")
		fi
	fi	

	if [ ${#BindHost} != 0 ] ; then
		echo "${BindHost}" | grep -wEq "[0-9]{1,2}"
		if [ $? != 0 ]; then
			Process 1 "Invalid bind to host: ${BindHost} "
			printf "%10s%s\n" "" "The bind to host should be: 0-99"
			let ErrorFlag++
		else
			COMMON_OPTIONS[4]=$(echo "--bind ${BindHost}")	
		fi			
	fi
	
	if [ ${#LogFile} == 0 ] ; then
		COMMON_OPTIONS[5]=""
		LogFileName=""
	else
		local LogFileBasename=$(basename ${LogFile})
		local LogFilePath=$(echo ${LogFile} | sed "s/${LogFileBasename}//g" )
		if [ ! -d "${WorkPath}/${LogDir}" ] ; then
			mkdir -p "${WorkPath}/${LogDir}"
		fi
		LogFileName=${WorkPath}/${LogDir}/`date +%Y%m%d%H%M%S`_${BaseName}_${LogFileBasename}
		if [ ${ExecuteSite} == "c" ] ; then
			COMMON_OPTIONS[5]=$(echo "--logfile ${LogFileName}")
		else
			COMMON_OPTIONS[5]=""
		fi
	fi
	
	if [ ${#LinkSpeed[@]} == 0 ] ; then
		Process 1 "Link speed is: NUL "
	else
		for((L=0;L<${#LinkSpeed[@]};L++))
		do
			echo "${LinkSpeed[S]}" | grep -iwEq "[0-9]{2,9}"
			if [ $? != 0 ] ; then
				Process 1 "Invalid link speed: ${LinkSpeed[S]} "
				let ErrorFlag++
			fi
		done
	fi
	
	echo "${Autoneg}" | grep -wq "on\|off"
	if [ $? != 0 ] ; then
		Process 1 "Invalid Autoneg: ${Autoneg} "
		let ErrorFlag++
	fi
	
	echo "${Duplex}" | grep -wq "half\|full"
	if [ $? != 0 ] ; then
		Process 1 "Invalid Duplex: ${Duplex} "
		let ErrorFlag++
	fi
	
	if [ ${ExecuteSite} == "s" ] ; then		
		# SERVER SPECIFIC OPTIONS
		sMacAddrFile=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Server/MacAddrFile" -n "${XmlConfigFile}" 2>/dev/null)
		sIPaddress=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Server/IPaddress" -n "${XmlConfigFile}" 2>/dev/null)
		sSubnetMask=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Server/SubnetMask" -n "${XmlConfigFile}" 2>/dev/null)
		
		SERVER_SPECIFIC_OPTIONS[0]=$(echo "--server")
		
		if [ ! -f "${sMacAddrFile}" ] ; then
			#手動選擇網孔
			sMacAddress='ManualChoose'
		else
			sMacAddress=$(cat ${sMacAddrFile} | grep -wE "[0-9A-Fa-f]{12}" | tr '[a-z]' '[A-Z]')
			sMacAddress=${sMacAddress:-ManualChoose}
		fi
		if [ ${#sIPaddress} != 0 ] ; then
			CheckIPaddr ${sIPaddress} || let ErrorFlag++
			CheckIPaddr ${sSubnetMask} || let ErrorFlag++
		fi
		MacAddress=${sMacAddress}
		IpAddress=${sIPaddress}
		SubnetMask=${sSubnetMask}		
	fi
	
	if [ ${ExecuteSite} == "c" ] ; then	
		# CLIENT SPECIFIC OPTIONS
		cMacAddrFile=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/MacAddrFile" -n "${XmlConfigFile}" 2>/dev/null)
		cIPaddress=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/IPaddress" -n "${XmlConfigFile}" 2>/dev/null)
		cSubnetMask=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/SubnetMask" -n "${XmlConfigFile}" 2>/dev/null)
		sIPaddress=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Server/IPaddress" -n "${XmlConfigFile}" 2>/dev/null)
		UDP=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/UDP" -n "${XmlConfigFile}" 2>/dev/null)
		Bandwidth=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Bandwidth" -n "${XmlConfigFile}" 2>/dev/null)
		Number=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Number" -n "${XmlConfigFile}" 2>/dev/null)
		Time=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Time" -n "${XmlConfigFile}" 2>/dev/null)
		BuffersLength=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/BuffersLength" -n "${XmlConfigFile}" 2>/dev/null)
		Parallel=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Parallel" -n "${XmlConfigFile}" 2>/dev/null)
		Window=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Window" -n "${XmlConfigFile}" 2>/dev/null)
		MssSet=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/MssSet" -n "${XmlConfigFile}" 2>/dev/null)
		Reverse=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Reverse" -n "${XmlConfigFile}" 2>/dev/null)
		Nodelay=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Nodelay" -n "${XmlConfigFile}" 2>/dev/null)
		IPv46=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/IPv46" -n "${XmlConfigFile}" 2>/dev/null)
		GetServerOutput=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/GetServerOutput" -n "${XmlConfigFile}" 2>/dev/null)
		OmitNseconds=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/OmitNseconds" -n "${XmlConfigFile}" 2>/dev/null)
		Title=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/Client/Title" -n "${XmlConfigFile}" 2>/dev/null)

		CLIENT_SPECIFIC_OPTION[0]=$(echo "--client ${sIPaddress}")
		
		if [ ! -f "${cMacAddrFile}" ] ; then
			#手動選擇網孔
			cMacAddress='ManualChoose'
		else
			cMacAddress=$(cat ${cMacAddrFile} | grep -wE "[0-9A-Fa-f]{12}" | tr '[a-z]' '[A-Z]')
			cMacAddress=${cMacAddress:-ManualChoose}
		fi
		
		if [ ${#cIPaddress} != 0 ] ; then
			CheckIPaddr ${cIPaddress} || let ErrorFlag++
			CheckIPaddr ${cSubnetMask} || let ErrorFlag++
		fi
		MacAddress=${cMacAddress}
		IpAddress=${cIPaddress}
		SubnetMask=${cSubnetMask}

		echo ${UDP} | grep -iwq "enable" 
		if [ $? == 0 ] ; then
			CLIENT_SPECIFIC_OPTION[1]=$(echo "--udp")
		else
			CLIENT_SPECIFIC_OPTION[1]=""
		fi

		if [ ${#Bandwidth} != 0 ] ; then
			echo ${Bandwidth} | grep -wEq "[0-9]{1,20}[kmgKMG]"
			if [ $? == 0 ] ; then
				CLIENT_SPECIFIC_OPTION[2]=$(echo "--bandwidth ${Bandwidth}")
			else
				Process 1 "Invalid Bandwidth format: ${Bandwidth}"
				CLIENT_SPECIFIC_OPTION[2]=""
				let ErrorFlag++
			fi
		fi
		
		if [ ${#Number} != 0 ] ; then
			echo ${Number} | grep -wEq "[0-9]{1,99}[kmgKMG]"
			if [ $? == 0 ] ; then
				CLIENT_SPECIFIC_OPTION[3]=$(echo "--num ${Number}")
			else
				Process 1 "Invalid number of buffers to transmit: ${Number}"
				CLIENT_SPECIFIC_OPTION[3]=""
				let ErrorFlag++
			fi			
		else
			CLIENT_SPECIFIC_OPTION[3]=""
		fi

		if [ ${#Time} != 0 ] ; then
			#Number和Time同時設置，Time有效，Number參數置空
			CLIENT_SPECIFIC_OPTION[3]=""
			
			echo ${Time} | grep -wEq "[0-9]{1,99}"
			if [ $? == 0 ] ; then
				CLIENT_SPECIFIC_OPTION[4]=$(echo "--time ${Time}")
			else
				Process 1 "Invalid time in seconds to transmit for: ${Time}"
				CLIENT_SPECIFIC_OPTION[4]=""
				let ErrorFlag++
			fi			
		else
			if [ "${CLIENT_SPECIFIC_OPTION[3]}"x == "x" ] ; then
				Process 1 "Both Number and Time are NUL"
				let ErrorFlag++
			else
				CLIENT_SPECIFIC_OPTION[4]=""
			fi
		fi
		
		#block size maximum = 1048576 bytes
		if [ ${#BuffersLength} != 0 ] ; then
			echo ${BuffersLength} | grep -wEq "[0-9]{1,20}[kmgKMG]"
			if [ $? == 0 ] ; then
				CLIENT_SPECIFIC_OPTION[5]=$(echo "--length ${BuffersLength}")
			else
				Process 1 "Invalid length of buffers to read or write: ${BuffersLength}(maximum = 1048576 bytes)"
				CLIENT_SPECIFIC_OPTION[5]=""
				let ErrorFlag++
			fi
		fi
		
		if [ ${#Parallel} != 0 ] ; then
			echo ${Parallel} | grep -wEq "[0-9]{1,3}"
			if [ $? == 0 ] ; then
				if [ ${Parallel} -gt 128 ] ; then
					Process 1 "Invalid number of simultaneous connections to make to the server: ${Parallel}(maximum = 128)"
					CLIENT_SPECIFIC_OPTION[6]=""
					let ErrorFlag++
				else
					CLIENT_SPECIFIC_OPTION[6]=$(echo "--parallel ${Parallel}")
				fi
			else
				Process 1 "Invalid number of simultaneous connections to make to the server: ${Parallel}"
				CLIENT_SPECIFIC_OPTION[6]=""
				let ErrorFlag++
			fi
		fi

		if [ ${#Window} != 0 ] ; then
			echo ${Window} | grep -wEq "[0-9]{1,20}[kmKM]"
			if [ $? == 0 ] ; then
				CLIENT_SPECIFIC_OPTION[7]=$(echo "--window ${Window}")
			else
				Process 1 "Invalid socket buffer sizes to the specified value: ${Window}"
				CLIENT_SPECIFIC_OPTION[7]=""
				let ErrorFlag++
			fi
		fi

		if [ ${#MssSet} != 0 ] ; then
			echo ${MssSet} | grep -wEq "[0-9]{1,20}[kmKM]"
			if [ $? == 0 ] ; then
				CLIENT_SPECIFIC_OPTION[8]=$(echo "--set-mss ${MssSet}")
			else
				Process 1 "Invalid attempt to set the TCP maximum segment size: ${MssSet}"
				CLIENT_SPECIFIC_OPTION[8]=""
				let ErrorFlag++
			fi
		fi

		echo ${Reverse} | grep -iwq "enable" 
		if [ $? == 0 ] ; then
			#正向測試一次,反向測試一次
			ReverseTest=$(echo "--reverse")
		else
			ReverseTest=""
		fi
		
		echo ${Nodelay} | grep -iwq "enable" 
		if [ $? == 0 ] ; then
			CLIENT_SPECIFIC_OPTION[9]=$(echo "--no-delay")
		else
			CLIENT_SPECIFIC_OPTION[9]=""
		fi

		if [ ${#IPv46} != 0 ] ; then
			if [ $(echo ${IPv46} | grep -wc "version4\|version6") == 1 ] ; then
				CLIENT_SPECIFIC_OPTION[10]=$(echo "--${IPv46}")
			elif [ $(echo ${IPv46} | grep -wc "4\|6") == 1 ] ; then
				CLIENT_SPECIFIC_OPTION[10]=$(echo "-${IPv46}")
			else
				Process 1 "Invalid format of IPv#: ${IPv46}"
				CLIENT_SPECIFIC_OPTION[10]=""
				let ErrorFlag++
			fi
		fi
		
		echo ${GetServerOutput} | grep -iwq "enable" 
		if [ $? == 0 ] ; then
			CLIENT_SPECIFIC_OPTION[11]=$(echo "--get-server-output")
		else
			CLIENT_SPECIFIC_OPTION[11]=""
		fi
		
		if [ ${#OmitNseconds} != 0 ] ; then
			echo ${OmitNseconds} | grep -wEq "[0-9]{1,2}"
			if [ $? == 0 ] ; then
				if [ ${#Time} != 0 ] ; then
					if [ ${OmitNseconds} -ge ${Time} ] ; then
						Process 1 "Invalid the first n seconds of the test: ${OmitNseconds}(>${Time})"
						let ErrorFlag++
					fi
				fi
				CLIENT_SPECIFIC_OPTION[12]=$(echo "--omit ${OmitNseconds}")
			else
				Process 1 "Invalid the first n seconds of the test: ${OmitNseconds}"
				CLIENT_SPECIFIC_OPTION[12]=""
				let ErrorFlag++
			fi
		fi
		
		if [ ${#Title} != 0 ] ; then
			if [ ! -f "${Title}" ] ; then
				TitleString=$(echo ${Title} | tr " " "_")
			else
				TitleString=$(cat ${Title} | tr " " "_")
			fi
			CLIENT_SPECIFIC_OPTION[13]=$(echo "--title  Client-${TitleString}")
		else
			CLIENT_SPECIFIC_OPTION[13]=$(echo "--title  Client")
		fi

	fi
	
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0			
}

CheckIPaddr ()
{
	local IPaddr=$1
	echo ${IPaddr} | grep -iq "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$"
	if [ "$?" != "0" ] ; then 
		Process 1 "Invalid IP address: ${IPaddr}"
		return 1
	fi 

	for ((i=1;i<=4;i++))
	do
		IPaddrSegment=$(echo ${IPaddr} | awk -F'.'  -v S=$i '{print $S}')
		IPaddrSegment=${IPaddrSegment:-"999"}
		if [ $IPaddrSegment -gt 255 ] || [ $IPaddrSegment -lt 0 ] ; then 
			Process 1 "Invalid IP address: ${IPaddr}"
			return 1
		fi 
	done 
	return 0
}

UintConversion()
{
	case ${1} in
	b)printf "%s\n" "bits/sec";;
	B)printf "%s\n" "Bytes/sec";;
	k)printf "%s\n" "Kbits/sec";;
	K)printf "%s\n" "KBytes/sec";;
	m)printf "%s\n" "Mbits/sec";;
	M)printf "%s\n" "MBytes/sec";;
	g)printf "%s\n" "Gbits/sec";;
	G)printf "%s\n" "GBytes/sec";;
	a)printf "%s\n" "adaptive bits/sec";;
	A)printf "%s\n" "adaptive Bytes/sec";;
	*)printf "%s\n" "Invalid unit";;
	esac
}

ParseOptions()
{
	printf "\e[1m%s\e[0m\n" "                    Command line option description"
	printf "\e[1m%s\e[0m\n" "GENERAL OPTIONS"
	printf "\e[1m%s\e[0m\n" "----------------------------------------------------------------------"
	printf "%-52s%2s%s\n" "  Server to listen on and the client to connect to" ": " "${ListenPort}"
	[ ${#Format} != 0 ] && printf "%-52s%2s%s\n" "  The format to print bandwidth number" ": " "`UintConversion ${Format}`"
	[ ${#Interval} != 0 ] && printf "%-52s%2s%s\n" "  The interval time in seconds" ": " "${Interval} second(s)"
	[ ${ExecuteSite} == "c" -a ${#FileToRW} != 0 ] && printf "%-52s%2s%s\n" "  Read from the file and write to the network" ": " "${FileToRW}" 
	[ ${ExecuteSite} == "s" -a ${#FileToRW} != 0 ] && printf "%-52s%2s%s\n" "  Read from the network and write to the file" ": " "${FileToRW}" 
	[ ${ExecuteSite} == "c" -a ${#BindHost} != 0 ] && printf "%-52s%2s%s\n" "  The outbound interface(Client)" ": " "${BindHost}"
	[ ${ExecuteSite} == "s" -a ${#BindHost} != 0 ] && printf "%-52s%2s%s\n" "  The incoming interface(Server)" ": " "${BindHost}"
	echo
	
	if [ ${ExecuteSite} == "s" ] ; then
		printf "\e[1m%s\e[0m\n" "SERVER SPECIFIC OPTIONS" 
		printf "\e[1m%s\e[0m\n" "----------------------------------------------------------------------"
		printf "%-52s%2s%s\n" "  Net Interface" ": " "${SelectCard}, `GetNetInfoByInterface ${SelectCard} | awk '{print $2}'`"
		printf "%-52s%2s%s\n" "  IP address" ": " "`GetNetInfoByInterface ${SelectCard} | awk '{print $3}'`"
		printf "%-52s%2s%s\n" "  Subnet Mask" ": " "`GetNetInfoByInterface ${SelectCard} | awk '{print $4}'`"
	fi

	if [ ${ExecuteSite} == "c" ] ; then	
		printf "\e[1m%s\e[0m\n" "CLIENT SPECIFIC OPTIONS"
		printf "\e[1m%s\e[0m\n" "----------------------------------------------------------------------"
		printf "%-52s%2s%s\n" "  Net Interface" ": " "${SelectCard}, `GetNetInfoByInterface ${SelectCard} | awk '{print $2}'`"
		printf "%-52s%2s%s\n" "  Client side IP address" ": " "`GetNetInfoByInterface ${SelectCard} | awk '{print $3}'`"
		printf "%-52s%2s%s\n" "  Client Subnet Mask" ": " "`GetNetInfoByInterface ${SelectCard} | awk '{print $4}'`"
		printf "%-52s%2s%s\n" "  Server side IP address" ": " "${sIPaddress}"
		printf "%-52s%2s%s\n" "  Link speed" ": " "`echo "${LinkSpeed[@]}" | tr ' ' '/' ` Mb/s"
		printf "%-52s%2s%s\n" "  Automatic negotiation" ": " "${Autoneg}"
		printf "%-52s%2s%s\n" "  Full/half duplex" ": " "${Duplex}"
		printf "%-52s%2s%s\n" "  UDP/TCP mode" ": " "`if [ "${CLIENT_SPECIFIC_OPTION[1]}"x == 'x' ] ; then echo "TCP mode" ; else echo "UDP mode" ;fi`"
		printf "%-52s%2s%s\n" "  Set the TCP no delay option" ": " "`if [ "${CLIENT_SPECIFIC_OPTION[9]}"x == 'x' ] ; then echo "Delay mode" ; else echo "No-delay mode" ;fi`"
		printf "%-52s%2s%s\n" "  Get server output" ": " "`if [ "${CLIENT_SPECIFIC_OPTION[11]}"x == 'x' ] ; then echo "Disable" ; else echo "Enable" ;fi`"
		[ ${#Bandwidth} != 0 ] && printf "%-52s%2s%s\n" "  Target bandwidth" ": " "${Bandwidth}"
		[ ${#Number} != 0 ] && printf "%-52s%2s%s\n" "  The number of buffers to transmit" ": " "${Number}"
		[ ${#Time} != 0 ] && printf "%-52s%2s%s\n" "  The time in seconds to transmit for(Sconds)" ": " "${Time}"
		[ ${#BuffersLength} != 0 ] && printf "%-52s%2s%s\n" "  The length of buffers to read or write" ": " "${BuffersLength}"
		[ ${#Parallel} != 0 ] && printf "%-52s%2s%s\n" "  The number of simultaneous connections " ": " "${Parallel}"
		[ ${#Window} != 0 ] && printf "%-52s%2s%s\n" "  The socket buffer sizes to the specified value" ": " "${Window}"
		[ ${#MssSet} != 0 ] && printf "%-52s%2s%s\n" "  Attempt to set the TCP maximum segment size (MSS)" ": " "${MssSet}"
		[ ${#Reverse} != 0 ] && printf "%-52s%2s%s\n" "  Run in reverse mode(server sends,client receives)" ": " "${Reverse}"
		[ ${#IPv46} != 0 ] && printf "%-52s%2s%s\n" "  IP Version" ": " "${IPv46}"
		[ ${#OmitNseconds} != 0 ] && printf "%-52s%2s%s\n" "  Omit the first n seconds of the test" ": " "${OmitNseconds}"
		[ ${#TitleString} != 0 ] && printf "%-52s%2s%s\n" "  Prefix every output line with this title" ": " "${TitleString}"
	fi
	echo
	echo "Command: iperf3 ${COMMON_OPTIONS[@]} ${SERVER_SPECIFIC_OPTIONS[@]} ${CLIENT_SPECIFIC_OPTION[@]}"	
	return 0
}

StopFirewalld()
{
	systemctl stop firewalld
	Process $? "Stop firewalld ..."
	systemctl disable firewalld
	Process $? "Disable firewalld ..."
	systemctl stop firewalld.service
	Process $? "Stop firewalld service ..."
	systemctl disable firewalld.service
	Process $? "Disable firewalld service ..."
	return 0
}

SelectNetworkCard()
{
	NetCards=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "([\dA-F]{2}:){5}[\dA-F]{2}" | grep -iE "^e[nt]" | awk '{print $1}' | tr -d ':'))
	if [ ${#NetCards[@]} == 0 ] ;then
		Process 1 "No found any netcard onboard ..."
		exit 1
	fi
	
	rm -rf chooseNetCard 2>/dev/null
	printf "%-s\n" "#!/bin/bash" > chooseNetCard
	printf "%-s\n" "OPTION=\$(whiptail --title \"Network card selection\" --menu \"Please select a network card.\" 15 60 4 \\" >>chooseNetCard
	for((n=0;n<${#NetCards[@]};n++))
	do
		local MacAddress=$(ifconfig ${NetCards[n]} | tr -d ":"|tr ' ' '\n' | tr '[a-z]' '[A-Z]' | grep -iwE "[0-9A-F]{12}")
		printf "%-s%-s%-s\n" "\"$((n+1))\" " " \"${NetCards[n]}  MAC: ${MacAddress}\" " " \\" >>chooseNetCard
	done
	printf "%-s\n" "3>&1 1>&2 2>&3)" >>chooseNetCard
	
	cat<<-Msg >>chooseNetCard
	exitstatus=\$?
	if [ \${exitstatus} = 0 ]; then
		echo "\$OPTION"
	else
		echo "You chose Cancel."
	fi
	Msg
	sync;sync;sync
	chmod 777 chooseNetCard
	SelectCardIndex=$(./chooseNetCard)
	rm -rf chooseNetCard 2>/dev/null
	echo ${SelectCardIndex} | grep -iwq "Cancel"  && exit 1
	SelectCard=$(echo ${NetCards[SelectCardIndex-1]} 2>/dev/null)
}

GetNetcardInfo()
{
	command -v nmcli >&/dev/null 
	if [ $? != 0 ] ; then
		printf "%s\n" "No such command 'nmcli', exit ..."
		return 0
	fi
	
	rm -rf ${BaseName}_netcard.log 2>/dev/null
	nmcli > .${BaseName}_netcard.log 2>/dev/null
	sync;sync;sync
	local BlankLineID=($(cat .${BaseName}_netcard.log | grep -n "^$" | awk '{print $1}' | tr -d ":" ))
	BlankLineID=($(echo "1 ${BlankLineID[@]} 9999"))
	local Devices=$(ifconfig -a 2>/dev/null | grep -v "inet" | grep -iPB3 "([\dA-F]{2}:){5}[\dA-F]{2}" | grep -iE "^[ew][ntwp]" | awk '{print $1}' | tr -d '\n' | sed 's/:/\\|/g')
	for((b=0;b<${#BlankLineID[@]}-1;b++))
	do
		cat .${BaseName}_netcard.log 2>/dev/null | sed -n ${BlankLineID[b]},${BlankLineID[b+1]}p | grep -iwq "${Devices}QiutiQin"
		if [ $? == 0 ] ; then
			printf "%s\n" "----------------------------------------------------------------------"
			cat .${BaseName}_netcard.log 2>/dev/null | sed -n ${BlankLineID[b]},${BlankLineID[b+1]}p
		fi
	done
	printf "%s\n" "----------------------------------------------------------------------"
	return 0
}

KillSetIPaddress()
{
	if [ ${ExecuteSite} == "c" ] ; then	
		ethtool -s "${SelectCard}" autoneg ${Autoneg} duplex ${Duplex} speed ${MaxLinlkSpeed} >/dev/null 2>&1
	fi
	# Stop PID
	rm -rf setIPaddress >& /dev/null
	ps ax | awk '/setIPaddress/{print $1}' | while read PID
	do
		kill -9 "${PID}" >& /dev/null
	done
}

SetIP()
{	
	if [ "${MacAddress}" == "ManualChoose" ] ; then
		SelectNetworkCard 
	else
		SelectCard=$(ifconfig -a 2>/dev/null | grep -v "inet" | tr -d ':' | grep -iPB3 "${MacAddress}" | grep -iE "^e[nt]" | awk '{print $1}' )
	fi
	
	if [ ${#IpAddress} == 0 ] || [ $(echo "${IpAddress}" | grep -ic "DHCP") == 1 ] ; then
		GetNetInfoByInterface ${SelectCard} | grep -iwq "[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}"
		if [ $? == 0 ] ; then
			return 0
		else
			for ((L=1;L<=3;L++))
			do
				ifconfig ${SelectCard} down >/dev/null 2>&1
				sleep 3
				ifconfig ${SelectCard} up >/dev/null 2>&1
				sleep 3
				dhclient -r ${SelectCard} >/dev/null 2>&1
				
				if [ $(dhclient --help 2>&1 | grep -wFc "[--timeout" ) == 1 ] ; then
					dhclient --timeout 5 ${SelectCard} >/dev/null 2>&1
				elif [ $(dhclient --help 2>&1 | grep -wFc "[-timeout" ) == 1 ] ; then
					dhclient -timeout 5 ${SelectCard} >/dev/null 2>&1
				else
					Process 1 "No argument 'timeout' for dhclient ..."
					return 1
				fi
				
				sleep 2
				GetNetInfoByInterface ${SelectCard} | grep -iwq "[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}" && return 0
			done
			if [ ${L} -ge 4 ] ; then
				Process 1 "Can not link server ..."
				return 1
			fi
		fi
	else	
		KillSetIPaddress
		cat <<-setIPaddr > setIPaddress
		#!/bin/bash
		while :
		do 
			ifconfig "${SelectCard}" "${IpAddress}" netmask "${SubnetMask}"
		done
		setIPaddr
		sync;sync;sync
		
		chmod 777 setIPaddress
		`./setIPaddress` &
		for((r=1;r<=3;r++))
		do
			ifconfig "${SelectCard}" | grep -wq "${IpAddress}"
			Process $? "Set ${SelectCard}'s IP: ${IpAddress}, netmask: ${SubnetMask}" && return 0
			sleep 1
		done
		[ ${r} -ge 4 ] && return 1
	fi
	return 0
}

GetNetInfoByInterface()
{
	local Interface=${1}
	local MacAddress=$(ifconfig ${SelectCard} 2>/dev/null | tr -d ':' | grep -iwE "[0-9A-F]{12}" | awk '{print $2}' | tr '[a-f]' '[A-F]') 
	local IpAddress=$(ifconfig ${SelectCard} 2>/dev/null | grep -iw "netmask" | grep -iw "[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}" | awk '{print $2}') 
	local SubnetMask=$(ifconfig ${SelectCard} 2>/dev/null | grep -iw "netmask" | grep -iw "[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}" | awk '{print $4}') 
	printf "%s\n" "${Interface} ${MacAddress} ${IpAddress} ${SubnetMask}"
	return 0
}

SetAndVerifyLinkSpeed()
{
	local SetSpeed=$(echo "${1}" | tr -d '[[:punct:]][[:alpha:]] ')
	local trySet=($(echo "1st 1st 2nd 3rd 4th 5th 6th 7th 8th 9th 10th 11th"))
	printf "%-s\n" "Try to set the ${SelectCard}'s link speed as: ${SetSpeed}Mb/s ..."
	CurLinkSpeed=$(ethtool ${SelectCard} 2>/dev/null | grep -w "Speed"  | awk -F': ' '{print $NF}')
	CurLinkSpeedVal=$(echo "${CurLinkSpeed}" | tr -d '[[:punct:]][[:alpha:]] ')
	if [ ${CurLinkSpeedVal:-0} != ${SetSpeed} ] ; then
		for((try=1;try>0;try++))
		do
			printf "%-40s\r" "The ${trySet[try]} trying ...     "
			dhclient -r ${SelectCard} 2>/dev/null
			sleep 1
			ifconfig "${SelectCard}" down 2>/dev/null || continue
			sleep 1
			ifconfig "${SelectCard}" up 2>/dev/null || continue
			sleep 1
			
			ethtool -s "${SelectCard}" autoneg ${Autoneg} duplex ${Duplex} speed ${SetSpeed} >/dev/null 2>&1
			sleep 2
			for ((T=1;T<=3;T++))
			do
				ethtool "${SelectCard}" 2>/dev/null | grep -i "Link detected" | grep -iwq 'yes'
				if [ $? == 0 ] ; then
					CurLinkSpeed=$(ethtool ${SelectCard} 2>/dev/null | grep -w "Speed"  | awk -F': ' '{print $NF}')
					CurLinkSpeedVal=$(echo "${CurLinkSpeed}" | tr -d '[[:punct:]][[:alpha:]] ')
					Process 0 "Set the ${SelectCard}'s link speed as: ${SetSpeed}Mb/s ..."
					break 2 
				fi
				sleep 1
			done
			# 嘗試超過10次未成功就退出嘗試
			if [ ${try} -gt 10 ] ; then
				ethtool -s "${SelectCard}" autoneg ${Autoneg} duplex ${Duplex} speed ${MaxLinlkSpeed} >/dev/null 2>&1
				Process 1 "Set the ${SelectCard}'s link speed as: ${CurLinkSpeed} ..."
				printf "%-10s%-s\n" "" "Try more than 10 times and fail, exit ..."
				return 1
			fi
		done	
	fi	
	return 0
}

PrintTestResult()
{
	local TestLog="${1}"
	printf "%s\n" "----------------------------------------------------------------------"
	# UDP mode
	echo -e "\e[1miPerf test result summary:\e[0m"
	cat "${TestLog}" 2>/dev/null | grep -w "Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams" | head -n1
	cat "${TestLog}" 2>/dev/null | grep -iwq "Client.*SUM.*%" || local Udp=none  
	cat "${TestLog}" 2>/dev/null | grep -iw "Client.*SUM.*%" | tail -n1 | grep -iw "Client.*SUM.*%" 
	if [ $? == 0 ] && [ ${#CLIENT_SPECIFIC_OPTION[11]} != 0 ] ; then
		printf "%-$((${#TitleString}+7))s%3s" "Server-side" ":  "
		cat "${TestLog}" 2>/dev/null | grep -iw "SUM.*%" | tail -n1
	fi
	
	# TCP mode
	cat "${TestLog}" 2>/dev/null | grep -w "Interval           Transfer     Bandwidth       Retr" | head -n1
	cat "${TestLog}" 2>/dev/null | grep -iwq "Client.*SUM.*sender\|Client.*SUM.*receiver" || local Tcp=none
	cat "${TestLog}" 2>/dev/null | grep -iw "Client.*SUM.*sender\|Client.*SUM.*receiver"
	if [ $? == 0 ] && [ ${#CLIENT_SPECIFIC_OPTION[11]} != 0 ] ; then
		cat "${TestLog}" 2>/dev/null | grep -iw "SUM.*sender\|SUM.*receiver" | grep -v "Client" | while read line 
		do
			printf "%-$((${#TitleString}+7))s%3s%s\n" "Server-side" ":  " "${line}"
		done
	fi
	
	if [ "${Tcp}"x == "nonex" ] && [ "${Udp}"x == "nonex" ] ; then
			cat "${TestLog}" 2>/dev/null
			let ErrorFlag++
	fi
	printf "%s\n" "----------------------------------------------------------------------"	
}

SeparateVauleUnit()
{
	local Value=$(echo ${1} | tr -d "[[:alpha:]]/% ")
	local Unit=$(echo ${1} | tr -d "[0-9]. ")
	printf "%s\n" "${Value} ${Unit}"
}

ParseTestLog()
{
	local TestLog="${1}"
	local CurLinkSpeed="${2}"
	
	rm -rf ${LogDir}/${BaseName}_Result_summary.log 2>/dev/null
	PrintTestResult ${TestLog} | tee ${LogDir}/${BaseName}_Result_summary.log
	sync;sync;sync
	
	cat "${TestLog}" 2>/dev/null | grep -iwq "iperf Done"
	if [ $? != 0 ] ; then
		Process 1 "No found \"iperf Done\", iPerf test not finished yet ..."
		let ErrorFlag++
	fi 

	#檢查log內沒有error等報錯
	local SubErrorFlag=0
	ExceptItemsCnt=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ParseLog/Except/Item" -n "${XmlConfigFile}" 2>/dev/null | wc -l )
	for((e=1;e<=${ExceptItemsCnt};e++))
	do
		local ExceptItem=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ParseLog/Except/Item[$e]" -n "${XmlConfigFile}" 2>/dev/null)
		cat "${TestLog}" 2>/dev/null | grep -iwq "${ExceptItem}"
		if [ $? == 0 ] ; then
			Process 1 "Found error msg: ${ExceptItem}"
			let SubErrorFlag++
		fi
	done
	
	if [ ${SubErrorFlag} == 0 ] ; then
		Process 0 "No found any error message in log ..."
	else
		let ErrorFlag++
	fi
		
	#檢查網絡測試性能
	MinBandwidth=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ParseLog/PassCondition/MinBandwidth" -n "${XmlConfigFile}" 2>/dev/null)
	MinPacketLossRate=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ParseLog/PassCondition/MinPacketLossRate" -n "${XmlConfigFile}" 2>/dev/null)
	MaxJitter=$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ParseLog/PassCondition/MaxJitter" -n "${XmlConfigFile}" 2>/dev/null)
	
	MinBandwidthVauleUnit=($(SeparateVauleUnit "${MinBandwidth}"))
	UintConversion ${Format} | grep -wq "${MinBandwidthVauleUnit[1]}"
	if [ $? != 0 ] ; then
		Process 1 "The units in xml of bandwidth's messurement are inconsistent: `UintConversion ${Format}` and ${MinBandwidthVauleUnit[1]}"
		let ErrorFlag++
	fi
	
	echo ${UDP} | grep -iwq "enable"
	if [ $? == 0 ] ; then
		CurBandwidthVaule=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*%" | awk '{print $7}' | tail -n1 )
		CurBandwidthUnit=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*%" | awk '{print $8}' | tail -n1  )
		echo "${MinBandwidthVauleUnit[1]}" | grep -wq "${CurBandwidthUnit}"
		if [ $? != 0 ] ; then
			Process 1 "The units of Bandwidth's messurement are inconsistent: ${MinBandwidthVauleUnit[1]} and ${CurBandwidthUnit}"
			let ErrorFlag++
		fi
		
		#+++++++++++++++++++++
		echo "scale=3;${CurBandwidthVaule}-${MinBandwidthVauleUnit[0]}*${CurLinkSpeed}/${MaxLinlkSpeed}>0" | bc | grep -iwq "1"
		if [ $? == 0 ] ; then
			Process 0 "Check the current UDP bandwidth: ${CurBandwidthVaule} ${CurBandwidthUnit}"
		else
			Process 1 "Check the current UDP bandwidth: ${CurBandwidthVaule} ${CurBandwidthUnit} < `echo "scale=2;${MinBandwidthVauleUnit[0]}*${CurLinkSpeed}/${MaxLinlkSpeed}+0.00" | bc` ${CurBandwidthUnit}"
			let ErrorFlag++
		fi
		#+++++++++++++++++++++
		MinPacketLossRateVauleUnit=($(SeparateVauleUnit "${MinPacketLossRate}"))
		CurPacketLossRateVaule=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*%" | awk '{print $NF}' | tr -d "()%" | tail -n1 )
		
		echo "scale=3;${CurPacketLossRateVaule}-${MinPacketLossRateVauleUnit[0]}<0" | bc | grep -iwq "1"
		if [ $? == 0 ] ; then
			Process 0 "Check the current packet loss rate: ${CurPacketLossRateVaule}%"
		else
			Process 1 "Check the current packet loss rate: ${CurPacketLossRateVaule}% > ${MinPacketLossRateVauleUnit[0]}%"
			let ErrorFlag++
		fi
		
		#+++++++++++++++++++++
		if [ ${#MaxJitter} != 0 ] ; then
			MaxJitterVauleUnit=($(SeparateVauleUnit "${MaxJitter}"))
			CurJitterVaule=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*%" | awk '{print $9}' | tail -n1 )
			CurJitterUnit=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*%" | awk '{print $10}' | tail -n1 )	
			
			# 1s --> 1000ms
			echo ${CurJitterUnit} | grep -iwq "s" && CurJitterVaule=$((CurJitterVaule*1000))		
			echo ${MaxJitterVauleUnit[1]} | grep -iwq "s" && let MaxJitterVauleUnit[0]=${MaxJitterVauleUnit[0]}*1000
			
			echo "scale=3;${CurJitterVaule}-${MaxJitterVauleUnit[0]}<0" | bc | grep -iwq "1"
			if [ $? == 0 ] ; then
				Process 0 "Check the current jitter time: ${CurJitterVaule} ${CurJitterUnit}"
			else
				Process 1 "Check the current jitter time: ${CurJitterVaule} ${CurJitterUnit} > ${MaxJitterVauleUnit[0]} ${CurJitterUnit}"
				let ErrorFlag++
			fi
		fi
	else
		CurSenderBandwidthVaule=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*sender" | awk '{print $7}' | tail -n1 )
		CurSenderBandwidthUnit=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*sender" | awk '{print $8}' | tail -n1 )
		
		CurReceiverBandwidthVaule=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*receiver" | awk '{print $7}' | tail -n1 )
		CurReceiverBandwidthUnit=$(cat  ${LogDir}/${BaseName}_Result_summary.log | grep -w "Client.*SUM.*receiver" | awk '{print $8}' | tail -n1 )
		
		echo "${MinBandwidthVauleUnit[1]}" | grep -wq "${CurSenderBandwidthUnit}"
		if [ $? != 0 ] ; then
			Process 1 "The units of bandwidth's messurement are inconsistent: ${MinBandwidthVauleUnit[1]} and ${CurSenderBandwidthUnit}"
			let ErrorFlag++
		fi
		
		echo "${MinBandwidthVauleUnit[1]}" | grep -wq "${CurReceiverBandwidthUnit}"
		if [ $? != 0 ] ; then
			Process 1 "The units of bandwidth's messurement are inconsistent: ${MinBandwidthVauleUnit[1]} and ${CurReceiverBandwidthUnit}"
			let ErrorFlag++
		fi
		#+++++++++++++++++++++
		echo "scale=3;${CurSenderBandwidthVaule}-${MinBandwidthVauleUnit[0]}*${CurLinkSpeed}/${MaxLinlkSpeed}>0" | bc | grep -iwq "1"
		if [ $? == 0 ] ; then
			Process 0 "Check the current TCP sender bandwidth: ${CurSenderBandwidthVaule} ${CurSenderBandwidthUnit}"
		else
			Process 1 "Check the current TCP sender bandwidth: ${CurSenderBandwidthVaule} ${CurSenderBandwidthUnit} < `echo "scale=2;${MinBandwidthVauleUnit[0]}*${CurLinkSpeed}/${MaxLinlkSpeed}+0.00" | bc` ${CurSenderBandwidthUnit}" 
			let ErrorFlag++
		fi
		#+++++++++++++++++++++
		
		echo "scale=3;${CurReceiverBandwidthVaule}-${MinBandwidthVauleUnit[0]}*${CurLinkSpeed}/${MaxLinlkSpeed}>0" | bc | grep -iwq "1"
		if [ $? == 0 ] ; then
			Process 0 "Check the current TCP receiver bandwidth: ${CurReceiverBandwidthVaule} ${CurReceiverBandwidthUnit}"
		else
			Process 1 "Check the current TCP receiver bandwidth: ${CurReceiverBandwidthVaule} ${CurReceiverBandwidthUnit} < `echo "scale=2;${MinBandwidthVauleUnit[0]}*${CurLinkSpeed}/${MaxLinlkSpeed}+0.00" | bc` ${CurReceiverBandwidthUnit}"
			let ErrorFlag++
		fi
	fi
}

main()
{
	trap "tput cnorm" TERM
	printf "%s\n" "**********************************************************************"
	printf "%s\n" "*****               Net Card stress test for linux               *****"
	printf "%s\n" "**********************************************************************"
	StopFirewalld
	SetIP || exit 1
	ParseOptions
	iPerfTool=$(which iperf3 | head -n1)
	chmod 777 ${iPerfTool}
	StartTestTime=$(date "+%Y/%m/%d %H:%M:%S")
	PPIDKILL=$$
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" INT
	trap "pkill -9 -P ${PPIDKILL};kill -9 $$" KILL
	printf "%-23s%-2s%-s\n" "PID" ":" "$$"
	printf "%-23s%-2s%-s\n" "Working directory" ":" "${WorkPath}"
	printf "%-23s%-2s%-s\n" "iPerf Tool" ":" "${iPerfTool}"
	printf "%-23s%-2s%-s\n" "Jobs started at date" ":" "${StartTestTime}"
	if [ ${#Time} != 0 ] ; then 
		local OriginalDate=$(date -d @"0" +"%Y-%m-%d")
		local OriginalDateVal=$(date -d "${OriginalDate} 00:00:00" +%s)
		local TimeVal=$(echo ${Time} | tr -d '[a-zA-Z]')
		local DurationTime=$(date -d @"$((TimeVal*${#LinkSpeed[@]}+OriginalDateVal+20))" +"%H:%M:%S")
		printf "%-23s%-2s%-s\n" "All test duration time" ":" "${DurationTime}"
	fi
	
	if [ ${ExecuteSite} == "s" ] ; then
		LinkSpeed=()
		LinkSpeed=($(echo ${MaxLinlkSpeed}))
	fi
	for((S=0;S<${#LinkSpeed[@]};S++))
	do
		local LogFileNameIncludeSpd=$(echo "${LogFileName}" | sed "s/_${BaseName}_/_${BaseName}_${LinkSpeed[S]}_/g" )
		local NEW_COMMON_OPTIONS=$(printf "%s\n" "${COMMON_OPTIONS[@]}" | sed "s/_${BaseName}_/_${BaseName}_${LinkSpeed[S]}_/g")
		[ ${#LogFileName} != 0 ] && printf "%s%s%s\n" "LOGs file" ": " "${LogFileNameIncludeSpd}"
		
		if [ ${ExecuteSite} == "c" ] ; then	
			SetAndVerifyLinkSpeed "${LinkSpeed[S]}" || exit 1
		else
			CurLinkSpeed=$(ethtool ${SelectCard} 2>/dev/null | grep -w "Speed"  | awk -F': ' '{print $NF}')
		fi
		
		
		echo "Waiting (PID: $$) for iperf test, link speed is ${CurLinkSpeed} ..."
		for pid in `pgrep -P ${PPIDKILL} iperf3` ; do
			kill -9 ${pid} >/dev/null
		done
		sleep 1
		if [ ${ExecuteSite} == "c" ] && [ ${#LogFile} != 0 ] ; then
			if [ ${#pcb} != 0 ] ; then
				GetNetcardInfo | tee ${LogFileNameIncludeSpd}
			else
				GetNetcardInfo > ${LogFileNameIncludeSpd}
			fi
			sync;sync;sync
		fi
				
		if [ ${ExecuteSite} == "c" ] ; then
			iperf3 ${NEW_COMMON_OPTIONS[@]} ${SERVER_SPECIFIC_OPTIONS[@]} ${CLIENT_SPECIFIC_OPTION[@]} &
		else
			iperf3 ${COMMON_OPTIONS[@]} ${SERVER_SPECIFIC_OPTIONS[@]} ${CLIENT_SPECIFIC_OPTION[@]}
		fi
		
		#Server 端看不到這一行之後的內容了
		printf "\n%s\n" "Please wait a moment, or press a key to view the detail ..."
		for((s=1;s>0;s++))
		do
			tput civis
			ChildenProcesses=($(pgrep -P ${PPIDKILL} iperf3))
			if [ ${#ChildenProcesses[@]} == 0 ]; then
				echo
				break
			else
				read -t1 -n1 Reply
				if [ ${#Reply} == 0 ] ; then
					printf "%s" ">"
					if [ $((s%70)) == 0 ] ; then
						printf "\r%s\r" "                                                                       "
					fi
				else
					[ ${#LogFileName} == 0 ] && continue 
					for((p=1;p<=10;p++))
					do
						clear
						echo "Test detail: "
						tail -n 12 ${LogFileNameIncludeSpd}
						read -t1 -n1 -p "Press a key to return ..."  Reply2
						[ ${#Reply2} != 0 ] && break
					done
					clear
					echo
					printf "%s\n" "**********************************************************************"
					printf "%s\n" "*****               Net Card stress test for linux               *****"
					printf "%s\n" "**********************************************************************"
					printf "%-23s%-2s%-s\n" "PID" ":" "$$"
					printf "%-23s%-2s%-s\n" "Working directory" ":" "${WorkPath}"
					[ ${#LogFileName} != 0 ] && printf "%-23s%-2s%-s\n" "LOGs file" ":" "${LogFileNameIncludeSpd}"
					printf "%-23s%-2s%-s\n" "iPerf Tool" ":" "${iPerfTool}"
					printf "%-23s%-2s%-s\n" "Jobs started at date" ":" "${StartTestTime}"
					[ ${#Time} != 0 ] && printf "%-23s%-2s%-s\n" "All test duration time" ":" "${DurationTime}"
					echo "Waiting (PID: $$) for iperf test, link speed is ${CurLinkSpeed} ..."
					printf "\n%s\n" "Please wait a moment ..."
				fi
			fi
		done
		
		if [ ${#ReverseTest} != 0 ] && [ ${ExecuteSite} == "c" ] ; then
			local ReverseModeStartTestTime=$(date "+%Y/%m/%d %H:%M:%S")
			local ReverseModeLogFileName=$(echo "${LogFileNameIncludeSpd}" | sed "s/_${BaseName}_/_${BaseName}_ReverseMode_/g" )
			local NEW_COMMON_OPTIONS=$(printf "%s\n" "${COMMON_OPTIONS[@]}" | sed "s/_${BaseName}_/_${BaseName}_ReverseMode_/g")
			echo
			[ ${#LogFileName} != 0 ] && printf "%-23s%-2s%-s\n" "LOGs file" ":" "${ReverseModeLogFileName}"
			printf "%-23s%-2s%-s\n" "iPerf Tool" ":" "${iPerfTool}"
			printf "%-23s%-2s%-s\n" "Jobs started at date" ":" "${ReverseModeStartTestTime}"
			printf "%-23s%-2s\e[1;33m%-s\e[0m\n" "Test mode" ":" "Reverse Mode, Server send data and Client receive data"
			[ ${#Time} != 0 ] && printf "%-23s%-2s%-s\n" "All test duration time" ":" "${DurationTime}"
			echo "Waiting (PID: $$) for iperf test, link speed is ${CurLinkSpeed} ..."
			if [ ${ExecuteSite} == "c" ] && [ ${#LogFile} != 0 ] ; then
				GetNetcardInfo > ${ReverseModeLogFileName}
				sync;sync;sync
			fi
			
			iperf3 ${NEW_COMMON_OPTIONS} ${SERVER_SPECIFIC_OPTIONS[@]} ${CLIENT_SPECIFIC_OPTION[@]} ${ReverseTest} &
			sleep 1
			printf "\n%s\n" "Please wait a moment, or press a key to view the detail ..."
			for((s=1;s>0;s++))
			do
				ChildenProcesses=($(pgrep -P ${PPIDKILL} iperf3))
				if [ ${#ChildenProcesses[@]} == 0 ]; then
					echo
					break
				else
					read -t1 -n1 Reply
					if [ ${#Reply} == 0 ] ; then
						printf "%s" ">"
						if [ $((s%70)) == 0 ] ; then
							printf "\r%s\r" "                                                                       "
						fi
					else
						[ ${#LogFileName} == 0 ] && continue 
						for((p=1;p<=10;p++))
						do
							clear
							echo "Test detail: "
							tail -n 12 ${ReverseModeLogFileName}
							read -t1 -n1 -p "Press a key to return ..."  Reply2
							[ ${#Reply2} != 0 ] && break
						done
						clear
						echo
						printf "%s\n" "**********************************************************************"
						printf "%s\n" "*****               Net Card stress test for linux               *****"
						printf "%s\n" "**********************************************************************"
						printf "%-23s%-2s%-s\n" "PID" ":" "$$"
						printf "%-23s%-2s%-s\n" "Working directory" ":" "${WorkPath}"
						[ ${#LogFileName} != 0 ] && printf "%-23s%-2s%-s\n" "LOGs file" ":" "${ReverseModeLogFileName}"
						printf "%-23s%-2s%-s\n" "iPerf Tool" ":" "${iPerfTool}"
						printf "%-23s%-2s%-s\n" "Jobs started at date" ":" "${ReverseModeStartTestTime}"
						printf "%-23s%-2s\e[1;33m%-s\e[0m\n" "Test mode" ":" "Reverse Mode, Server send data and Client receive data"
						[ ${#Time} != 0 ] && printf "%-23s%-2s%-s\n" "All test duration time" ":" "${DurationTime}"
						echo "Waiting (PID: $$) for iperf test, link speed is ${CurLinkSpeed} ..."
						printf "\n%s\n" "Please wait a moment ..."
					fi
				fi
			done
		fi
	
		########################
		if [ ${ExecuteSite} == "c" ] ; then
			if [ ${#LogFile} != 0 ] ; then
				ParseTestLog "${LogFileNameIncludeSpd}" "${LinkSpeed[S]}"
				if [ ${#ReverseTest} != 0 ] ; then
					ParseTestLog "${ReverseModeLogFileName}" "${LinkSpeed[S]}"
					local TestMode=$(echo "(forward and reverse mode)")
				fi
			fi
			local Side="Client-side${TestMode}"
		else
			local Side="Server-side"
		fi
		echo
	done
	tput cnorm
	KillSetIPaddress
	wait

	echo "End of testing(excution ended). Finished the iperf test ..."
	printf "%-23s%-2s%-s\n" "Jobs finished at date" ":" "`date "+%Y/%m/%d %H:%M:%S"`"
	echo
		
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "${Side} iPerf test"
	else
		echoFail "${Side} iPerf test"
		GenerateErrorCode
		exit 1
	fi
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -a COMMON_OPTIONS=()
declare -a SERVER_SPECIFIC_OPTIONS=()
declare -a CLIENT_SPECIFIC_OPTION=()
declare -a LinkSpeed=()
declare XmlConfigFile
declare LogDir="iPerf-Log"
declare ExecuteSite LogFileName ReverseTest TitleString CurLinkSpeed Autoneg Duplex
declare sMacAddress cMacAddress sIPaddress cIPaddress sSubnetMask cSubnetMask 
declare IpAddress SubnetMask SelectCard
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
			printf "%-s\n" "SerialTest,LanIperfTest"
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
