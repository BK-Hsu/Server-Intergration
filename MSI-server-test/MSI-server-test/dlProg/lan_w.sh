#!/bin/bash
#====================================================================================================
Eeprom='I3540101.eep'
NicIndex=1
#====================================================================================================
cd /dlProg 

PrintfTip()
{
	local String="$@"
	LCutCnt=$(echo "ibase=10;obase=10; (70-${#String})/2" | bc)
	RCutCnt=$(echo "ibase=10;obase=10; 50-${LCutCnt}" | bc)
	Left=$(echo "<<------------------------------------------------" | cut -c 1-${LCutCnt})
	Right=$(echo "------------------------------------------------>>" | cut -c ${RCutCnt}-)
	local PrintfStr="${Left}${String}${Right}"
	printf "\e[0;30;46m%70s\e[0m\n" "${PrintfStr}"
}

ChkExternalCommands ()
{
	ExtCmmds=(eeupdate64e)
	for((c=0;c<${#ExtCmmds[@]};c++))
	do
	_ExtCmmd=$(command -v ${ExtCmmds[$c]})
	if [ $? != 0 ]; then
		printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  "  "No such tool or command: ${ExtCmmds[$c]}"
		let ErrorFlag++
	else
		chmod 777 ${_ExtCmmd}
	fi
	done
	[ ${ErrorFlag} != 0 ] && exit 127
}
#====================================================================================================
ChkExternalCommands
while :
do
	PrintfTip "Please scan 12-bit LAN MAC address, eg.: 000000000123" 2>/dev/null
	read -p "Scan 12-bit `echo -e "\e[1;33mLAN MAC\e[0m address: ____________\b\b\b\b\b\b\b\b\b\b\b\b"`" MacAddress
	MacAddress=${MacAddress:-"000000000123"}
	echo ${MacAddress} | grep -qE "^[0-9A-Fa-f]{12}+$" 
	if [ "$?" != "0" ] ; then
		echo "Try again ... "
		echo
		continue
	fi
	echo 
	
	MacAddress=$(echo ${MacAddress} | cut -c 1-12 | tr [a-f] [A-F])
	printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "Scan in serial number is: ${MacAddress}"
	break 
done

if [ ${#Eeprom} != 0 ] ; then
	if [ ! -s "${Eeprom}" ] ; then
		printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "No found any eeprom file: ${Eeprom}"
		exit 1
	fi

	eeupdate64e /nic=${NicIndex} /d ${Eeprom}
	if [ "$?" != "0" ]; then
		exit 1
	fi
fi

eeupdate64e /nic=${NicIndex} /mac=$MacAddress
if [ "$?" != "0" ]; then
	exit 1
fi
exit 0