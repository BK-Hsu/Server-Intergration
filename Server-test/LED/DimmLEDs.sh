#!/bin/bash
#============================================================================================
#        File: BmcCtrlLED.sh
#    Function: Turn on/off LEDs by command 'ipmitool' and check the on/off LEDs' amount
#     Version: 1.0.0
#      Author: 
#     Created: 2020-08-24
#     Updated: 
#  Department: Application engineering course
#        Note: 
# Environment: Linux/CentOS
#============================================================================================
#----Define sub function---------------------------------------------------------------------
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
	local ErrorCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(xmlstarlet ipmitool)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		Process 1 "No such tool or command: ${ExtCmmds[$c]}"
		
		case ${ExtCmmds[$c]} in
			uuid)printf "%10s%s\n" "" "Please install: uuid-1.6.2-42.el8.x86_64.rpm";;
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
`basename $0` [-x lConfig.xml] [-D]
	eg.: `basename $0` -x lConfig.xml
	eg.: `basename $0` -D

	-D : Dump the sample xml config file	
	-x : config file,format as: *.xml

		
	return code:
	   0 : LEDs test pass
	   1 : LEDs test fail
	   2 : File is not exist
	   3 : Parameters error
	other: Check fail	
HELP
exit 3
}

DumpXML()
{
	cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml		
	<LED>
		<TestCase>
				<ProgramName>BmcCtrlLED</ProgramName>
				<ErrorCode>NXRD4|LED fail</ErrorCode>
				<!--請自行編寫功能函數,本程式只提供隨機數據-->
				<!--CountingOff/CountingOn函數返回格式如 點亮數量;2位數16進制;2位數16進制;...-->
				
				<Features>
					<!--1/0：讓LED點亮的高/低電平-->
					<On>1</On>
					<Off>0</Off>
					
					<!--LED的數量數量不是2^n的按off補位高位-->
					<Amount>32</Amount>
					<Location>S258-DIMM-LEDs</Location>
				</Features>
				
				<TestMethod>
					<CountRange>
						<!--隨機亮/滅的個數-->
						<Min>3</Min>
						<Max>7</Max>
					</CountRange>
					
					<!--on: 數LED點亮的個數，所有LED最少被點亮過一次即完成測試,測試組（次）數不固定-->
					<!--off: 數LED熄滅的個數，只需測試2組，先隨機滅1組，數個數；將熄滅的LED點亮，將原來點亮的隨機滅掉若干個，再數一次-->
					<CountingStatus>off</CountingStatus>					
				</TestMethod>
		</TestCase>	
	</LED>
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

	# Get the information from the config file(*.xml)
	TurnOnCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Features/On" -n "${XmlConfigFile}" 2>/dev/null)
	TurnOffCode=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Features/Off" -n "${XmlConfigFile}" 2>/dev/null)
	TotalAmount=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Features/Amount" -n "${XmlConfigFile}" 2>/dev/null)
	Location=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/Features/Location" -n "${XmlConfigFile}" 2>/dev/null)
	Location=${Location:-'XML未定義,請按SOP描述確認'}
	
	if [ $(echo "${TurnOnCode}" | grep -Ewc "[0-1]" ) != 1 ] || [ $(echo "${TurnOffCode}" | grep -Ewc "[0-1]" ) != 1 ]; then
		Process 1 "Invalid On/Off code in xml config file."
		let ErrorFlag++
	fi
	
	if [ ${#TotalAmount} == 0 ] ; then
		Process 1 "Invalid Amount setting in xml config file."
		let ErrorFlag++
	fi

	MinTurnOnoff=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/TestMethod/CountRange/Min" -n "${XmlConfigFile}" 2>/dev/null)
	MaxTurnOnoff=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/TestMethod/CountRange/Max" -n "${XmlConfigFile}" 2>/dev/null)
	CountingStatus=$(xmlstarlet sel -t -v "//LED/TestCase[ProgramName=\"${BaseName}\"]/TestMethod/CountingStatus" -n "${XmlConfigFile}" 2>/dev/null | tr '[A-Z]' '[a-z]')

	if [ $(echo ${MinTurnOnoff} | grep -wEc "[1-9]" ) != 1 ] ; then
		Process 1 "Invalid CountRange/Min setting in xml config file."
		let ErrorFlag++
	fi	

	if [ $(echo ${MaxTurnOnoff} | grep -wEc "[1-9]" ) != 1 ] ; then
		Process 1 "Invalid CountRange/Max setting in xml config file."
		let ErrorFlag++
	fi	
	
	Min2Max=($(echo ${MinTurnOnoff} ${MaxTurnOnoff} | tr ' ' '\n' | sort -ns))
	
	if [ $(echo ${CountingStatus} | grep -wc "off\|on" ) != 1 ] ; then
		Process 1 "Invalid TestMethod/CountingStatus setting in xml config file."
		let ErrorFlag++
	fi	
	
	[ ${ErrorFlag} != 0 ] && exit 1
	return 0			
}

Random()
{
    local min=$1
	local max=$(($2-$1))
    local num=$(date +%s+%N | bc)
    echo $((num%max+min))     
}

RandomNoRepetition()
{
	local num="$1"
	#獲取1~num個隨機不重複的數
	while :
	do
		for((i=0;i<${num};i++))
		do 
			local arrary[i]=$(Random 1 ${TotalAmount})
		done
		
		echo "${arrary[@]}" | tr ' ' '\n' | sort -u | wc -l | grep -iwq "${num}" 
		if [ $? == 0 ]; then
			echo "${arrary[@]}" | tr ' ' '\n' | sort -ns
			break
		fi
	done
}

CountingOff()
{
	if [ ${TotalAmount} -lt 19 ] ; then
		echo -e "\e[1;33mLED數量小於19的請使用不建議使用次方式測試...\e[0m"
		#exit 1
	fi
	
	#本函數只用於數OFF的LED，即CountingStatus=off使用本函數
	# 1st
	SwitchOff1=$(echo ${LedSwitchStr} | tr 'x' "${TurnOnCode}" | cut -c 1-${TotalAmount} )
	ActualOnOff[0]=$(Random ${Min2Max[@]})
	OffLocation=($(RandomNoRepetition ${ActualOnOff[0]}))
	for((j=0;j<${#OffLocation[@]};j++))
	do
		SwitchOff1=$(echo ${SwitchOff1} | grep -o "[0-1]" | sed "${OffLocation[j]}c ${TurnOffCode}" )
	done
	SwitchOff1=$(echo ${SwitchOff1} | tr -d ' ')
	#printf "%-20s%-s\n" "SwitchOff1:" "${ActualOnOff[0]},${SwitchOff1}"
	printf "%s" "${ActualOnOff[0]};"
	for((q=8;q<64;q=q+8))
	do
		[ "${SwitchOff1: -q:8}" == "" ] && break
		bit=$(printf "%s\n" "obase=16;ibase=2;${SwitchOff1: -q:8}" | bc)
		#高位使用0補充是否有效？還是用1補充？下同
		printf "%02x%s" "0x${bit}" ","
	done
	echo
	
	# 2nd
	SwitchOff2=$(echo ${LedSwitchStr} | tr 'x' "${TurnOnCode}" | cut -c 1-${TotalAmount} )
	AllOne=$(echo ${LedSwitchStr} | tr 'x' "1" | cut -c 1-$((TotalAmount+1)) )
	printf "%s\n" "${MaxTurnOnoff}*2-${TotalAmount}>0" | bc | grep -iwq "1"
	if [ $? == 0 ]; then
		SwitchOff2=$(printf "%s\n" "obase=2;ibase=2;${AllOne}-${SwitchOff1}" | bc | cut -c 1-${TotalAmount} )
		if [ ${#SwitchOff2} -lt ${TotalAmount} ] ; then
			SwitchOff_Temp=$(echo `echo ${LedSwitchStr} | tr 'x' "${TurnOnCode}"`${SwitchOff2})	
			SwitchOff2=${SwitchOff_Temp: -TotalAmount}
		fi
		ActualOnOff[1]=$(echo ${SwitchOff2} | grep -oE "[0-1]" | grep -wc "${TurnOffCode}" )
		
		if [ $((${ActualOnOff[1]}+${ActualOnOff[0]})) == ${TotalAmount} ] || [ ${ActualOnOff[1]} -gt ${MaxTurnOnoff} ] ; then
			while :
			do
				if [ $((${ActualOnOff[1]}+${ActualOnOff[0]})) == ${TotalAmount} ] || [ ${ActualOnOff[1]} -gt ${MaxTurnOnoff} ] || [ ${ActualOnOff[1]} -lt ${MinTurnOnoff}  ] ;then
					SwitchOff_Temp=''
					for((k=0;k<${TotalAmount};k++))
					do
						#原來亮的，不一定滅，原來滅的一定亮起來
						if [ ${SwitchOff1:k:1} == "${TurnOnCode}" ] ; then
							if [ $((RANDOM%2)) == 0 ] ; then
								SwitchOff_Temp="${SwitchOff_Temp}${TurnOnCode}"
							else
								SwitchOff_Temp="${SwitchOff_Temp}${SwitchOff2:k:1}"
							fi
						else
							SwitchOff_Temp="${SwitchOff_Temp}${SwitchOff2:k:1}"
						fi	
					done
					ActualOnOff[1]=$(echo ${SwitchOff_Temp: -TotalAmount} | grep -oE "[0-1]" | grep -wc "${TurnOffCode}" )
				else
					SwitchOff2=${SwitchOff_Temp: -TotalAmount}
					break
				fi
			done
		fi
	else
		lockOffLocation=($(echo ${OffLocation[@]}))
		SoleOffLocation=($(echo ${lockOffLocation[@]} | tr ' ' '\n' | sort -u ))
		SoleOffLocation=$(echo ${SoleOffLocation[@]} | sed 's/ /\\|/g')

		ActualOnOff[1]=$(Random ${Min2Max[@]})
		while :
		do
			OffLocation=($(RandomNoRepetition ${ActualOnOff[1]}))
			for((j=0;j<${#OffLocation[@]};j++))
			do
				echo ${OffLocation[j]} | grep -iwq "${SoleOffLocation}" && continue 2
			done
			break
		done

		for((j=0;j<${#OffLocation[@]};j++))
		do
			SwitchOff2=$(echo ${SwitchOff2} | grep -o "[0-1]" | sed "${OffLocation[j]}c ${TurnOffCode}" )
		done
		SwitchOff2=$(echo ${SwitchOff2} | tr -d ' ')
	fi
	
	ActualOnOff[1]=$(echo ${SwitchOff2} | grep -oE "[0-1]" | grep -wc "${TurnOffCode}" )
	#printf "%-20s%-s\n" "SwitchOff2:" "${ActualOnOff[1]},${SwitchOff2}"
	printf "%s" "${ActualOnOff[1]};"
	for((q=8;q<64;q=q+8))
	do
		[ "${SwitchOff2: -q:8}" == "" ] && break
		bit=$(printf "%s\n" "obase=16;ibase=2;${SwitchOff2: -q:8}" | bc)
		printf "%02x%s" "0x${bit}" ","
	done
	echo

}

RandomSort()
{
	local LedsAcount="$1"
	local TempFile=${BaseName}_sort.txt
	
	rm -rf ${TempFile} 2>/dev/null
	touch ${TempFile} 2>/dev/null
	
	while :
	do
		sort -u  ${TempFile} | wc -l | grep -wq "${LedsAcount}" && break
		echo $(($RANDOM%${LedsAcount}+1)) >>${TempFile}
	done
	
	local AllNumber=($(cat ${TempFile}))
	LEDsIndex=()
	LEDsIndex[0]=$(head -n1 ${TempFile}) 	
	for((j=1;j<${LedsAcount};j++))
	do
		SoleLEDsIndex=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | sort -u ))
		SoleLEDsIndex=$(echo ${SoleLEDsIndex[@]} | sed 's/ /\\|/g')
		
		for ((n=0;n<${#AllNumber[@]};n++))
		do
			echo ${AllNumber[n]} | grep -iwq "${SoleLEDsIndex}" 
			if [ $? != 0 ] ; then
				LEDsIndex[j]=${AllNumber[n]}
				continue 2
			fi
		done
	done
	#echo ${LEDsIndex[@]}	
}

CountingOn()
{
	
	#本函數可用於數ON的LED，即CountingStatus=on
	SwitchOffAll=$(echo ${LedSwitchStr} | tr 'x' "${TurnOffCode}" | cut -c 1-${TotalAmount} )
	
	#獲得LEDs隨機序號
	RandomSort ${TotalAmount}
	#ActualOnOff隨機長度(範圍是 MinTurnOnoff ~ MaxTurnOnoff)
	Sum=0
	GroupNumber=0
	for((t=0;t<20;t++))
	do
		ActualOnOff[$t]=$(Random ${Min2Max[@]})
		Sum=$((Sum+${ActualOnOff[$t]}))
		if [ ${Sum} -ge ${TotalAmount} ] ; then
			#各組數量總和相加不小於LED總數即退出
			GroupNumber="${t}"
			break
		fi
	done
	
	Sum=0
	for((g=0;g<=${GroupNumber};g++))
	do
		#LedGroup[$g]=(21 12 10 3 4)
		LedGroup=()
		if [ ${g} == 0 ] ; then
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | head -n ${ActualOnOff[g]}))
		elif [ ${g} == ${GroupNumber} ]; then
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | tail -n ${ActualOnOff[g]}))
		else
			LedGroup=($(echo ${LEDsIndex[@]} | tr ' ' '\n' | sed -n "$((Sum+1)),$((${ActualOnOff[g]}+Sum))p"))
		fi

		Sum=$((Sum+${ActualOnOff[g]}))
		
		SwitchOn[$g]=${SwitchOffAll}
		for((j=0;j<${#LedGroup[@]};j++))
		do
			#把LedGroup指定序號的LED點亮
			SwitchOn[$g]=$(echo ${SwitchOn[g]} | grep -o "[0-1]" | sed "${LedGroup[j]}c ${TurnOnCode}" )
		done
		SwitchOn[$g]=$(echo ${SwitchOn[$g]} | tr -d ' ')

		ActualOn[$g]=$(echo ${SwitchOn[$g]} | grep -oE "[0-1]" | grep -wc "${TurnOnCode}" )
		printf "%s" "${ActualOn[$g]};"
		for((q=8;q<64;q=q+8))
		do
			[ "${SwitchOn[$g]: -q:8}" == "" ] && break
			bit=$(printf "%s\n" "obase=16;ibase=2;${SwitchOn[$g]: -q:8}" | bc)
			printf "%02x%s" "0x${bit}" ","
		done
		printf "\n"
	done
	echo		
}

####################################################################################################################
main()
{
	printf "\e[43m%s\e[0m\n" "**********************************************************************"
	printf "\e[43m%s\e[0m\n" "***         LEDs 功能測試, 請按提示輸入LED點亮或熄滅的數量         ***"
	printf "\e[43m%s\e[0m\n" "**********************************************************************"
	printf "\e[1;32m%s\e[0m\n" "請觀察${Location}位置總共${TotalAmount} PCs LEDs ..."
	if [ "${CountingStatus}" == "off" ] ; then
		## all on
		ipmitool i2c bus=4 0x40 0x00 0x06 0x00 0x00 >/dev/null 2>&1
		ipmitool i2c bus=4 0x46 0x00 0x06 0x00 0x00 >/dev/null 2>&1

		for ((i=0;i<3;i++))
		do
			Error=0
			CheckList=($(CountingOff))
			for((c=0;c<${#CheckList[@]};c++))
			do
				TurnOffCount=$(echo "${CheckList[c]}" | awk -F';' '{print $1}')
				bit=($(echo "${CheckList[c]}" | awk -F';' '{print $NF}' | tr ',' ' '))
				#把點亮的LED Show 到Log內
				bit2Bin=$(echo ${bit[@]} | tr -d ' ' | tr '[a-z]' '[A-Z]')
				bit2Bin=$(printf "%s\n" "obase=2;ibase=16;${bit2Bin}" | bc )
				bit2Bin=$(echo ${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${bit2Bin})
				
				ipmitool i2c bus=4 0x40 0x00 0x06 0x${bit[0]} 0x${bit[1]} >/dev/null 2>&1
				ipmitool i2c bus=4 0x46 0x00 0x06 0x${bit[2]} 0x${bit[3]} >/dev/null 2>&1

				numlockx on 2>/dev/null
				echo -en "請在30秒鐘內觀察${Location}位置的所有LED, 其中\e[1;31m沒有點亮\e[0m的LED數量是:"
				read -t30 -n${#TurnOffCount} OpInput
				echo
				echo ${OpInput} | grep -iwq "${TurnOffCount}"
				if [ $? == 0 ] ; then
					Process 0 "第$((c+1))組測試, 熄滅LED的數量正確(${bit2Bin: -TotalAmount})..."
				else
					Process 1 "第$((c+1))組測試, 熄滅LED的數量錯誤(${bit2Bin: -TotalAmount})..."
					printf "%10s%s\n" "" "熄滅LED正確數量應該是: ${TurnOffCount} PCs"
					let Error++
					echo -e "\n現在重新測試..."
					continue 2
				fi
			done
			if [ ${Error} == 0 ]; then
				break
			fi
		done
		
		if [ ${i} -ge 3 ] || [ ${Error} != 0 ] ; then
			let ErrorFlag++
		fi
		## all off
		ipmitool i2c bus=4 0x40 0x00 0x06 0xff 0xff >/dev/null 2>&1
		ipmitool i2c bus=4 0x46 0x00 0x06 0xff 0xff >/dev/null 2>&1

		numlockx on 2>/dev/null
		echo -en "請在30秒鐘內觀察${Location}位置的所有LED, 其中\e[1;32m正常點亮\e[0m的LED數量是:"
		read -t30 -n1 OpInput
		echo
		echo ${OpInput} | grep -iwq "0"
		if [ $? == 0 ] ; then
			Process 0 "點亮的LED數量正確是:0 ..."
		else
			Process 1 "點亮的LED數量錯誤..."
			printf "%10s\e[1;31m%s\e[0m\n" "" "LED無法全部熄滅的務必按不良處理!!"
			let ErrorFlag++
		fi

		if [ ${i} -ge 3 ] || [ ${Error} != 0 ] ; then
			let ErrorFlag++
		fi
	
	else
		## all off
		ipmitool i2c bus=4 0x40 0x00 0x06 0xff 0xff >/dev/null 2>&1
		ipmitool i2c bus=4 0x46 0x00 0x06 0xff 0xff >/dev/null 2>&1

		for ((i=0;i<3;i++))
		do
			Error=0
			CheckList=($(CountingOn))
			for((c=0;c<${#CheckList[@]};c++))
			do
				TurnOnCount=$(echo "${CheckList[c]}" | awk -F';' '{print $1}')
				bit=($(echo "${CheckList[c]}" | awk -F';' '{print $NF}' | tr ',' ' '))
				#把點亮的LED Show 到Log內
				bit2Bin=$(echo ${bit[@]} | tr -d ' ' | tr '[a-z]' '[A-Z]')
				bit2Bin=$(printf "%s\n" "obase=2;ibase=16;${bit2Bin}" | bc )
				bit2Bin=$(echo ${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${TurnOnCode}${bit2Bin})
				
				ipmitool i2c bus=4 0x40 0x00 0x06 0x${bit[0]} 0x${bit[1]} >/dev/null 2>&1
				ipmitool i2c bus=4 0x46 0x00 0x06 0x${bit[2]} 0x${bit[3]} >/dev/null 2>&1

				numlockx on 2>/dev/null				
				echo -en "請在30秒鐘內觀察${Location}位置的所有LED, 其中\e[1;32m正常點亮\e[0m的LED數量是:"
				read -t30 -n${#TurnOnCount} OpInput
				echo
				echo ${OpInput} | grep -iwq "${TurnOnCount}"
				if [ $? == 0 ] ; then
					Process 0 "第$((c+1))組測試, 點亮LED的數量正確(${bit2Bin: -TotalAmount})..."
				else
					Process 1 "第$((c+1))組測試, 點亮LED的數量錯誤(${bit2Bin: -TotalAmount})..."
					printf "%10s%s\n" "" "點亮LED正確數量應該是: ${TurnOnCount} PCs"
					let Error++
					echo -e "\n重新測試..."
					continue 2
				fi
			done
			if [ ${Error} == 0 ]; then
				break
			fi
		done
		
		## all off
		ipmitool i2c bus=4 0x40 0x00 0x06 0xff 0xff >/dev/null 2>&1
		ipmitool i2c bus=4 0x46 0x00 0x06 0xff 0xff >/dev/null 2>&1

		numlockx on 2>/dev/null
		echo -en "請在30秒鐘內觀察${Location}位置的所有LED, 其中\e[1;32m正常點亮\e[0m的LED數量是:"
		read -t30 -n1 OpInput
		echo
		echo ${OpInput} | grep -iwq "0"
		if [ $? == 0 ] ; then
			Process 0 "點亮的LED數量正確是:0 ..."
		else
			Process 1 "點亮的LED數量錯誤..."
			printf "%10s\e[1;31m%s\e[0m\n" "" "LED無法全部熄滅的務必按不良處理!!"
			let ErrorFlag++
		fi

		if [ ${i} -ge 3 ] || [ ${Error} != 0 ] ; then
			let ErrorFlag++
		fi
	fi
	
	if [ ${ErrorFlag} == 0 ]; then
		echoPass "All LEDs test"
	else
		echoFail "Some LEDs test"
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
declare XmlConfigFile
declare TurnOnCode TurnOffCode TotalAmount Location MinTurnOnoff MaxTurnOnoff CountingStatus Min2Max 
declare ActualOnOff LEDsIndex SwitchOffAll
LedSwitchStr="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

if [ $# -lt 1 ] ; then
	Usage 
fi
ChkExternalCommands

#--->Get and process the parameters
while getopts Dx: argv
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

#CountingOff
#CountingOn
main
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
