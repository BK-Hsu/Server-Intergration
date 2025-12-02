#!/bin/bash
GetAllEthID()
{
	# release 6 is Linux 6.x,release 7 is Linux 7.x
	if [ $(grep -c 'release 6' /etc/redhat-release) -eq 1 ] || [ "$(uname -r | cut -c 1)"x == "2x" ]; then
		OsVersion=Linux6
	else
		OsVersion=Linux7
	fi

	if [ "$OsVersion" == "Linux6" ] ; then
		EthId=($(ifconfig -a 2>/dev/null | grep -iw "HWaddr"|  awk '{print $1}'))
	else
		EthId=($(ifconfig -a 2>/dev/null | grep -v "inet" | grep -B 1 -E "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}" | awk -F':' '/flag/{print $1}'| grep -vE "^v" ))
	fi

}

GetEthIDByMac()
{
	# Usage: GetEthIDByMac MacFile
	# Usage: GetEthIDByMac MacAddr
	local TargetMac="$1"
	if [ $(echo "${TargetMac}" | grep -ic 'TXT' ) -ge 1 ] ; then
		if [ ! -s "${TargetMac}" ] ; then
			echo_fail "No such file: ${TargetMac}"
			return 1
		fi
		TargetMac=$(cat -v "${TargetMac}" | head -n1 )
	fi

	# release 6 is Linux 6.x,release 7 is Linux 7.x
	if [ $(grep -c 'release 6' /etc/redhat-release) -eq 1 ] || [ "$(uname -r | cut -c 1)"x == "2x" ]; then
		OsVersion=Linux6
	else
		OsVersion=Linux7
	fi

	if [ "$OsVersion" == "Linux6" ] ; then
		EthId=($(ifconfig -a 2>/dev/null | tr -d ':' | grep -iw "${TargetMac}" |  awk '{print $1}'))
	else
		EthId=($(ifconfig -a 2>/dev/null | grep -iB4 "${TargetMac}" | awk '/flags/{print $1}' | grep -vE "^v" ))
	fi
}
