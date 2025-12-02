#!/bin/bash
#FileName : ChkLogic.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.1"
	local CreatedDate="2018-08-13"
	local UpdatedDate="2020-11-30"
	local Description="Check the logic of test program"
	
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
	printf "%16s%-s\n" "" "2020-11-30,新增P/C參數"
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

 DefineLogicByCode ()
 {
	echo >/dev/null
	 # Check logic, Define the SetLogicString
	SetLogicString[0]="/nic=*.*/d\|/nic=*.*/invmupdate"            	#eeprom_w.sh,eeprom flash
	SetLogicString[1]="socflash.*"                        			#Clrbmcmac.sh,Clear bmc mac
	SetLogicString[2]="/nic=*.*/eepromver\|/nic=*.*/invmversion"    #eeprom_c.sh,eeprom version check
	SetLogicString[3]="/nic=.*/mac="         						#lan_w.sh,lan mac flash
	SetLogicString[4]="/nic=.*/mac_dump"    						#lan_c.sh,lan mac compare
	SetLogicString[5]="/card=.* /diags"           					#lan_int_t.sh,lan port internal loopback test
	SetLogicString[6]="/sendresp"                 					#lan_ext_t.sh,lan port external loopback test
	SetLogicString[7]="mc info*.*Firmware Revision"      			#ChkBmcVer.sh or chkfw.sh,BMC FW version
	SetLogicString[8]="raw 0x06 0x52"            					#ipmb_bus.sh,ipmb bus function test
	SetLogicString[9]="NCSI"                         				#NCSItest.sh,NCSI test
	SetLogicString[10]="raw 0x0c 0x01 0x0.* 0x05"             		#BMCMAC_w.sh,bmc mac flash
	SetLogicString[11]="lan print*.*MAC Address'"      				#BMCMAC_c.sh,bmc mac compare
	SetLogicString[12]="lan print.*IP Address"       				#chkbmc_ip.sh,Get BMC IP address
	SetLogicString[13]="hwclock -w"               					#CmosTime.sh,Ping server and set time,Compare Date and Time
	SetLogicString[14]="Flash MPS power IC" 						#mpsrw_w.sh,check MP2955 FW
	SetLogicString[15]="Compare MPS power IC"      					#mpsrw_c.sh,flash MP2955 FW
	SetLogicString[16]="Flash serial number"   						#Srlnum_w.sh,External S/N compare
	SetLogicString[17]="Compare serial number" 						#Srlnum_c.sh,External S/N flash
	SetLogicString[18]="init 0"   									#Shutdown
 }

 DefineLogicByProperty ()
 {
	echo >/dev/null
	 # Check logic, Define the SetLogicString
	SetLogicString[0]="WirteEEPROM"            	#eeprom_w.sh,eeprom flash
	SetLogicString[1]="ClearBmcMAC"            	#Clrbmcmac.sh,Clear bmc mac
	SetLogicString[2]="CheckEEPROM"            	#eeprom_c.sh,eeprom version check
	SetLogicString[3]="WirteLanMAC"            	#lan_w.sh,lan mac flash
	SetLogicString[4]="CheckLanMAC"            	#lan_c.sh,lan mac compare
	SetLogicString[5]="LanInternalTest"         #lan_int_t.sh,lan port internal loopback test
	SetLogicString[6]="LanExternalTest"         #lan_ext_t.sh,lan port external loopback test
	SetLogicString[7]="CheckBmcVersion"         #ChkBmcVer.sh or chkfw.sh,BMC FW version
	SetLogicString[8]="IpmbTest"            	#ipmb_bus.sh,ipmb bus function test
	SetLogicString[9]="NcsiTest"            	#NCSItest.sh,NCSI test
	SetLogicString[10]="WriteBmcMAC"            #BMCMAC_w.sh,bmc mac flash
	SetLogicString[11]="CheckBmcMAC"            #BMCMAC_c.sh,bmc mac compare
	SetLogicString[12]="CheckBmcIP"            	#chkbmc_ip.sh,Get BMC IP address
	SetLogicString[13]="SetCmosTime"            #CmosTime.sh,Ping server and set time,Compare Date and Time
	SetLogicString[14]="WriteMpsFW"            	#mpsrw_w.sh,check MP2955 FW
	SetLogicString[15]="CheckMpsFW"            	#mpsrw_c.sh,flash MP2955 FW
	SetLogicString[16]="WriteDMIinfo"           #Srlnum_w.sh,External S/N compare
	SetLogicString[17]="CheckDMIinfo"           #Srlnum_c.sh,External S/N flash
	SetLogicString[18]="ShutdownOS"            	#Shutdown
 }

ShowTitle()
{
	local BlankCnt=0
	echo 
	VersionInfo "getVersion"
	local Title="$@, version: ${ApVersion}"
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                           ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [ -x lConfig.xml ] [-DhVCN]
	eg.: `basename $0` -D
	eg.: `basename $0` -V
	eg.: `basename $0` -h
	eg.: `basename $0` -x lConfig.xml
	
	-D : Dump the sample xml config file
	-x : XmlConfigFile.xml
	-V : Display version number and exit(1)	
	-C : 按程式的代碼識別程式類別	
	-P : 按程式的屬性識別程式類別

	return code:
		0 : Check the logic pass
		1 : Check the logic fail
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
		<Item index="3">/TestAP/ChkBios/ChkBios.sh</Item>
		<Item index="4">/TestAP/BMC/ChkFW.sh</Item>
		<Item index="5">/TestAP/Shutdown/ShutdownOS.sh</Item>
		<Item index="7">/TestAP/HWM/hwmon.sh</Item>	
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

#--->Get the parameters from the XML config file
GetParametersFrXML ()
{
	xmlstarlet val "${XmlConfigFile}" >/dev/null 2>&1
	if [ $? != 0 ] ; then
		xmlstarlet fo ${XmlConfigFile}
		Process 1 "Invalid XML file: ${XmlConfigFile}"
		exit 3
	fi 

	# Get the parameters information from the config file(*.xml)
	TotalItemConfig=($(xmlstarlet sel -t -v "//ProgramName" -n ${XmlConfigFile} | sort -u ))
	declare TotalItemIndex=($(xmlstarlet sel -t -v "//Programs/Item/@index" -n ${XmlConfigFile} | sort -nu ))
	if [ $(echo "${TotalItemIndex[@]}" | grep -iEc "[A-Z]") -ge 1 ] ; then
		Process 1 "Invalid index: `echo "${TotalItemIndex[@]}" | tr ' ' '\n' | grep -iE '[A-Z]' | tr '\n' ' ' | sed 's/ /,/g'`"
		exit 3
	fi 

	LogicConfigFile=${BaseName}.ini
	rm -rf ${LogicConfigFile} 2>/dev/null
	for ((z=0;z<${#TotalItemIndex[@]};z++))
	do
		AllItems=()
		# 1|/TestAP/Scan/ScanOPID.sh
		# 2|/TestAP/Scan/ScanFixID.sh
		# 3|/TestAP/ChkBios/ChkBios.sh|S1651
		# 4|/TestAP/BMC/ChkFW.sh|S1651
		# 5|/TestAP/Shutdown/ShutdownOS.sh
		# 6|/TestAP/HWM/hwmon.sh
		AllItems=($(xmlstarlet sel -t -v  //Programs/Item[@index=${TotalItemIndex[$z]}] ${XmlConfigFile} 2>/dev/null | grep -iE '[0-9A-Z]' | grep -v "^$"))
		if [ ${#AllItems[@]} == 0 ] ; then
			Process 1 "No such index=${TotalItemIndex[$z]}"
			let ErrorFlag++
			continue
		fi
		
		for ((y=0;y<${#AllItems[@]};y++))
		do	
			echo "${TotalItemIndex[$z]}|${AllItems[$y]}" >> ${LogicConfigFile}
		done
		sync;sync;sync

	done

	[ ${ErrorFlag} != 0 ] && exit 1

	if [ ! -s "${LogicConfigFile}" ] ; then
		Process 1 "No such file or 0 KB size of file: ${LogicConfigFile}"
		exit 2
	fi
}


GetLogicMap()
{
	rm -rf LogicMap.ini 2>/dev/null
	# Save the list in file: LogicMap.ini
	# ID Program          Exist?  Bin?  Config?  ErrCode       The key String
	# --------------------------------------------------------------------------------
	# 1  ScanOPID.sh       Yes     No    Yes      ERX18    eeupdate64e /nic=.* /d
	# 2  ScanFixID.sh	   Yes	   No    Yes      ERX18    eeupdate64e /nic=.* /mac_dump 
	# 3  ChkBios.sh		   Yes     No    Yes      ERX18    mc info | Firmware Revision
	# --------------------------------------------------------------------------------

	# ID Program          Exist?  Bin?  Config?  ErrCode    Properties of bash shell
	# --------------------------------------------------------------------------------
	# 1  ScanOPID.sh       Yes    Yes    Yes      ERX18          WriteEEPROM
	# 2  ScanFixID.sh	   Yes	  Yes    Yes      ERX18          CheckLanMAC
	# 3  ChkBios.sh		   Yes    Yes    Yes      ERX18          CheckBmcIP
	# --------------------------------------------------------------------------------
	
	ShowTitle "Create the Logic Message"
	if [ ${IdentificationMode} == 'ByCode' ] ;then
		printf "%-3s%-17s%-8s%-6s%-9s%-14s%-23s\n" "ID" "Program" "Exist?" "Bin?" "Config?" "ErrCode" "The key String"
	else
		printf "%-3s%-17s%-8s%-6s%-9s%-11s%-26s\n" "ID" "Program" "Exist?" "Bin?" "Config?" "ErrCode" "Properties of bash shell"	
	fi
	echo "--------------------------------------------------------------------------------"

	AllItems=()
	AllItems=($(cat -v ${LogicConfigFile} | grep -v "#" | grep -v "^$"))
	local Len=$(($(echo ${#AllItems[@]} | wc -c)-1))
	for((x=0;x<${#AllItems[@]};x++))
	do
		AllItemsID=$(echo ${AllItems[$x]} | awk -F'|' '{print $1}')
		AllItemsName=$(echo ${AllItems[$x]} | awk -F'|' '{print $2}')
		AllItemsFileName=$(echo ${AllItems[$x]} | awk -F'|' '{print $2}' | awk -F'/' '{print $NF}')
		FileName=$(echo "${AllItemsFileName}" | awk -F'\\.sh' '{print $1}' | sed 's/.\///g')
		
		printf "%0${Len}d%-1s%-18s" "${AllItemsID}" "" "${AllItemsFileName}"		
		if [ ! -s "${AllItemsName}" ] ; then
			printf "\e[31m%-8s\e[0m%-6s%-9s%-9s%-27s\n"  "No" "---" "---" "-----" "----------------------"
			echo "${AllItemsID}|${AllItemsFileName}|NO|--|--|--|--" >> LogicMap.ini
			let ErrorFlag++
			continue
		else
			printf "%-7s" "Yes" 
		fi
		
		if [ ${IdentificationMode} == 'ByCode' ] ;then
			if [ $(grep -iwc "#!/bin/bash" "${AllItemsName}" ) == 0 ] ; then
				file -b "${AllItemsName}" | grep -iwq "executable"
				if [ $? == 0 ] ; then
					printf "\e[31m%-6s\e[0m%-9s%-9s%-27s\n" "Yes" "---" "-----" "----------------------"
					echo "${AllItemsID}|${AllItemsFileName}|Yes|Yes|---|---|-----" >> LogicMap.ini
				else
					printf "\e[31m%-6s\e[0m%-9s%-9s%-27s\n" "Yes" "---" "-----" "----------------------"
					echo "${AllItemsID}|${AllItemsFileName}|Yes|No|---|---|-----" >> LogicMap.ini
				fi
				let ErrorFlag++
				continue
			else
				printf "%-6s" " No" 
			fi
		else
			file -b "${AllItemsName}" | grep -iwq "executable"
			if [ $? == 0 ] ; then
				printf "%-7s" "Yes"
			else
				printf "%-7s" "N/A"
			fi
		fi
		
		#檢查xml是否有這個程式的配置信息
		echo "${TotalItemConfig[@]}" | grep -wq "${FileName}"
		if [ $? != 0 ] ; then
			printf "\e[31m%-9s\e[0m" "No"
		else
			printf "%-9s" "Yes"		
		fi

		ErrCode=($(xmlstarlet sel -t -v "//TestCase[ProgramName=\"${FileName}\"]/ErrorCode" -n ${XmlConfigFile} | awk -F'|' '{print $1}'| grep -iwE '[0-9A-Z]{5}'))
		[ ${#ErrCode[@]} == 0 ] && ErrCode=($(xmlstarlet sel -t -v "//TestCase[ProgramName=\"${FileName}\"]/ErrorCode" -n ${XmlConfigFile} | awk -F'|' '{print $1}'| grep -iwE '[0-9A-Z]{5}'))
		if [ ${#ErrCode[@]} == 0 ] ; then
			printf "\e[31m%-9s\e[0m" "-----"
		else
			printf "%-9s" "${ErrCode[0]}"		
		fi
		
		for ((y=0;y<${#SetLogicString[@]};y++))
		do
			local TurnBack=""
			file -b "${AllItemsName}" | grep -iwq "executable"
			if [ $? == 0 ] ; then
				chmod 777 ${AllItemsName} 2>/dev/null
				${AllItemsName} -Px ${XmlConfigFile} 2>/dev/null | grep -iwq "${SetLogicString[$y]}"
			else
				if [ ${IdentificationMode} == 'ByCode' ] ;then
					cat -v ${AllItemsName} | grep -v "#" | grep -iwq "${SetLogicString[$y]}"
				else
					chmod 777 ${AllItemsName} 2>/dev/null
					${AllItemsName} -Px ${XmlConfigFile} 2>/dev/null | grep -iwq "${SetLogicString[$y]}"
				fi
			fi
			
			if [ $? == 0 ] ; then
				[ ${y} != 0 ] && TurnBack=$(echo "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" | cut -c 1-$((y*2)))
				printf "${TurnBack}%-27s\n" "${SetLogicString[$y]}"
				printf "%-s\n" "${AllItemsID}|${AllItemsFileName}|Yes|No|Yes|${ErrCode[0]}|${SetLogicString[$y]}" >>LogicMap.ini
				break
			else
				printf "%s" "."
			fi
		done
		[ ${y} != 0 ] && TurnBack=$(echo "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" | cut -c 1-$((y*2)))
		[ ${y} -ge ${#SetLogicString[@]} ] && printf "${TurnBack}%-27s\n" "----------------------"
	done
	echo "--------------------------------------------------------------------------------"

	printf "%-s\n" "Exist   : Yes--文件存在, No--文件遺失"
	printf "%-s\n" "Bin     : Yes--可能是二進制文件, No--不是二進制文件"
	printf "%-s\n" "Config  : Yes--在${XmlConfigFile}有配置信息, No--此程式不需要配置文件"
	printf "%-s\n" "ErrCode : Error代碼,並非全部的程式都有此代碼"
	sleep 2
	[ ${ErrorFlag} != 0 ] && exit 1

	if [ ! -s "LogicMap.ini" ] ; then
		Process 1 "No such file or 0 KB size of file: LogicMap.ini"
		printf "Is it OK? Y-OK, other-NG."
		read -n1 -t5 Reply
		echo
		if [ ${Reply:-"N"} == "Y" ] || [ ${Reply:-"N"} == "y" ] ; then
			return 0
		else
			exit 2
		fi
	fi
}


CheckLogic ()
{
	local Index_1st=$1
	local Index_2nd=$2
	RunFirst=$(echo ${SetLogicString[$Index_1st]})
	RunNext=$(echo ${SetLogicString[$Index_2nd]})

	Index_1st_CurID=$(grep -i "${RunFirst}" LogicMap.ini 2>/dev/null | awk -F'|' '{print $1}' | head -n1)
	Index_2nd_CurID=$(grep -i "${RunNext}"  LogicMap.ini 2>/dev/null | awk -F'|' '{print $1}' | tail -n1)

	Index_1st_CurFileName=($(grep -i "${RunFirst}" LogicMap.ini 2>/dev/null | awk -F'|' '{print $2}'))
	Index_2nd_CurFileName=($(grep -i "${RunNext}"  LogicMap.ini 2>/dev/null | awk -F'|' '{print $2}'))

	if [ ${#Index_1st_CurID} == 0 ] || [ ${#Index_2nd_CurID} == 0 ] ; then
		return 0
	fi

	if [ "${Index_1st_CurID}" -ge "${Index_2nd_CurID}" ] ; then 
		if [ "${ErrorFlag}x" == "0x" ] ; then
			# Show once only
			Process 1 "Check the order of program"
		fi
		#     lan_w.sh      -->    lan_c.sh
		printf "\e[1;33m%15s%-5s%-35s\e[0m\n" " `echo ${Index_1st_CurFileName[@]} | tr ' ' '\n' | tr '\n' ' ' ` " " --> " " `echo ${Index_2nd_CurFileName[@]} | tr ' ' '\n' | tr '\n' ' ' `"
		return 1
	fi
}

CheckLogicInList ()
{
	list=(`echo $@`)
	for ((chkid=0;chkid<${#list[@]}-1;chkid++))
	do 
		for ((chkID=$chkid+1;chkID<${#list[@]};chkID++))
		do
			CheckLogic ${list[$chkid]} ${list[$chkID]}
			[ $? != 0 ] && let ErrorFlag++
		done
	done
}

CheckLogicOfShutdown ()
{
	local Index_1st=$1
	local Index_2nd=$2
	RunFirst=$(echo ${SetLogicString[$Index_1st]})
	RunNext=$(echo ${SetLogicString[$Index_2nd]})

	Index_1st_CurID=$(grep -i "${RunFirst}" LogicMap.ini 2>/dev/null | awk -F'|' '{print $1}' | head -n1)
	Index_2nd_CurID=$(grep -i "${RunNext}"  LogicMap.ini 2>/dev/null | awk -F'|' '{print $1}'| tail -n1)

	Index_1st_CurFileName=($(grep -i "${RunFirst}" LogicMap.ini 2>/dev/null | awk -F'|' '{print $2}'))
	Index_2nd_CurFileName=($(grep -i "${RunNext}"  LogicMap.ini 2>/dev/null | awk -F'|' '{print $2}'))
	
	if [ ${#Index_1st_CurID} == 0 ] || [ ${#Index_2nd_CurID} == 0 ] ; then
		return 0
	fi

	# Get Shutdown ID
	ShutdownIndex=($(grep -i "${SetLogicString[18]}" LogicMap.ini 2>/dev/null | awk -F'|' '{print $1}'))
	for ((n=0;n<${#ShutdownIndex[@]};n++))
	do
		if [ "${Index_1st_CurID}" -lt ${ShutdownIndex[$n]} ] && [ "${Index_2nd_CurID}" -gt ${ShutdownIndex[$n]} ] ; then 
			return 0
		fi
	done
	
	if [ $n == ${#ShutdownIndex[@]} ] ; then
		if [ "${ShowOnce}x" == "x" ] ; then
			# Show once only
			ShowOnce='disable'
			echo
			Process 1 "It should be turned off once between the two program"
		fi
		printf "\e[1;33m%-15s%-20s%-25s\e[0m\n" "  `echo ${Index_1st_CurFileName[@]} | tr ' ' '\n' | tr '\n' ' ' `" "--> Shutdown OS -->" "  `echo ${Index_2nd_CurFileName[@]} | tr ' ' '\n' | tr '\n' ' ' `"
		return 1
	fi
}

CalculateMd5sum()
{
	TempArg=$(cat ${LogicConfigFile} | grep -v "#" | grep -v "^$" | awk -F'|' '{print $NF}' | tr '\n' ' ')
	md5sum ${TempArg} 2>/dev/null | tee md5value
	# if check pass,calculate md5sum of shells in /TestAP

	# if check pass,calculate md5sum of TestAP.sh
	md5sum ${XmlConfigFile} | tee -a md5value 2>/dev/null
	sync;sync;sync
}

CheckErrorCodeFunc()
{
	# no check the errcodelist
	[ $(echo ${CheckErrorCode} | grep -ic "enable") == 0 ] && return 0

	FailItemsList=($(cat -v ${LogicConfigFile} | grep -v "#" | grep -v "^$" | awk -F'|' '{print $2}' | tr ' ' '\n' | awk -F'/' '{print $NF}'))
	if [ ${#FailItemsList[@]} == 0 ] ; then
		Process 1 "No items to be search"
		exit 5
	fi
	ShowTitle "Check the errcode list of each program"
	printf "\e[1m%-2s%-4s%-18s%-4s%-10s%-4s%-28s\n\e[0m" "ID" "" "Test items " "" "Error Code" "" "     Description"
	echo -e "---------------------------------------------------------------------- "	
	for((i=0;i<${#FailItemsList[@]};i++))
	do
		let I=$i+1
		if [ $I -le 9 ] ; then
			I="0$I"
		fi
		
		echo "${FailItemsList[$i]}" | grep -iq $NoErrorCode && continue
		
		ErrorCode=$(cat $ErrorCodeList | grep -w ${FailItemsList[$i]} | awk -F',' '{print $1}')
		Description=$(cat $ErrorCodeList | grep -w ${FailItemsList[$i]} | awk -F',' '{print $2}')
		
		if [ ${#ErrorCode} != 5 ] ; then
			ErrorCode=${ErrorCode:-"#NULL"}
			Description=${Description:-"No description"}
			printf "%-2s%-4s%-18s%-4s\e[31m%-10s%-4s%-28s\n\e[0m" "$I" "" "${FailItemsList[$i]}" "" "  ${ErrorCode}" "" "${Description}"
			let ErrorFlag++
		else
			printf "%-2s%-4s%-18s%-4s%-10s%-4s%-28s\n" "$I" "" "${FailItemsList[$i]}" "" "  ${ErrorCode}" "" "${Description}"
		fi
	done
	echo -e "---------------------------------------------------------------------- "
	echo

	if [ $(echo ${CheckErrorCode} | grep -ic "enable") == 1 ] && [ ${ErrorFlag} -gt 0 ] ; then
		exit 1
	else
		ErrorFlag=0
	fi
}

main()
{	
	md5sum -c "md5value" --status 2>/dev/null
	if [ "$?" -ne "0" ] ; then
		ShowTitle "Functional test program logic verify tools"
		#CheckErrorCodeFunc
		if [ ${IdentificationMode} == 'ByCode' ] ; then
			DefineLogicByCode
		else
			DefineLogicByProperty
		fi
		GetLogicMap

		#eeprom_w.sh-->eeprom_c.sh-->lan_w.sh-->lan_c.sh-->lan_int_t.sh-->lan_ext_t.sh-->bmcmac_w.sh-->bmcmac_c.sh
		CheckLogicInList 0 2 3 4 5 6 10 11 12

		#eeprom_w.sh-->eeprom_c.sh-->lan_w.sh-->lan_c.sh-->CmosTime.sh
		CheckLogicInList 0 2 3 4 13
		
		#ClrBmcMac.sh-->ChkBmcVer.sh-->ipmb_bus.sh-->NCSItest.sh-->lan_ext_t.sh-->bmcmac_w.sh-->bmcmac_c.sh
		CheckLogicInList 1 7 8 9 10 11 12
		
		#lan_int_t.sh-->lan_ext_t.sh-->NCSItest.sh
		CheckLogicInList 5 6 9
		
		#MPSFW_w.sh-->MPSFW_c.sh.sh
		CheckLogicInList 14 15
		
		#SrlNum_w.sh-->SrlNum_c.sh
		CheckLogicInList 16 17
			
		
		#Clrbmcmac.sh-->ShutdownOS.sh-->ChkBmcVer.sh
		CheckLogicOfShutdown 1 7 || let ErrorFlag++
		
		#lan_w.sh-->ShutdownOS.sh-->lan_c.sh
		CheckLogicOfShutdown 3 4 || let ErrorFlag++
		
		#BMCMAC_w.sh-->ShutdownOS.sh-->BMCMAC_c.sh
		CheckLogicOfShutdown 10 11 || let ErrorFlag++
		
		#MPSFW_w.sh-->ShutdownOS.sh-->MPSFW_c.sh
		CheckLogicOfShutdown 14 15 || let ErrorFlag++
		
		#SrlNum_w.sh-->ShutdownOS.sh-->SrlNum_c.sh
		CheckLogicOfShutdown 16 17 || let ErrorFlag++
		
		[ ${ErrorFlag} == 0 ] && CalculateMd5sum
	fi 

	rm -rf *.txt *.tmp *.log 2>/dev/null
	echo
	if [ ${ErrorFlag} == 0 ] ; then
		echoPass "Check the logic of program"
	else
		echoFail "Check the logic of program"
		exit 1
	fi 
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare -a SetLogicString=()
declare IdentificationMode="ByCode"
declare XmlConfigFile LogicConfigFile ApVersion 
declare TotalItemConfig
declare NoErrorCode="Shutdown\|Reboot\|cls\|pass\|copy\|scan\|TestAPdef\|load\|Clrbmcmac\|Multithreading\|ncsi\|go2DOS\|check_dst\|MT"
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# == 0 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts :PCVDx: argv
do
	 case ${argv} in
	 	x)
			XmlConfigFile=${OPTARG}
			GetParametersFrXML
		;;
		
		D)
			DumpXML
			break
		;;
	
		C)
			IdentificationMode="ByCode"
		;;	
			
		P)
			IdentificationMode="ByProperty"
		;;	
			
		V)
			VersionInfo
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
