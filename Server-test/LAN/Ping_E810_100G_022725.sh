#!/bin/bash
#============================================================================================
#        File: Ping_E810_100G.sh
#    Function: ping E810 LAN Card
#     Version: 1.0
#      Author: rickyhong@msi.com
#     Created: 2025/02/21
#     Updated: 2025/02/21
#  Department: TPE EPS SIT
#        Note: The shell script auto set test lan IP to 192.168.58.58 , ping the soecified IP
# Environment: Ubuntu22.04
#============================================================================================

#Please define the system test lan interface , ex: enp5s0 
Interface="ens2"

#Please define the system ping IP , ex: 192.168.55.100
PingIP="192.168.1.100"

#Please define ping time (second) , ex: 60
PingTime_Second="30"

# Log name
LogFile="ping_E810_100G.log"


#For SUT default setting IP
SetIP="192.168.1.1"


# Wait setting after run ping
Wait_Ping = "10"


if command -v ifconfig > /dev/null 2>&1;then
	if ip link show "$Interface" > /dev/null 2>&1;then
		date | tee "$LogFile"
		echo "Set Interface($Interface) IP => $SetIP" | tee -a "$LogFile"		
		ifconfig -a | tee -a "$LogFile"
		ifconfig "$Interface" "$SetIP" up

		if [ $? == 0 ];then
			sleep $Wait_Ping
			echo "Start ping $PingIP(wait "$PingTime_Second" second)..." | tee -a "$LogFile"
			ping_result=$(ping -I "$Interface" -c "$PingTime_Second" "$PingIP")

			echo "$ping_result" | tee -a "$LogFile"

			LOSS_Get=$(echo "$ping_result" | grep "packet loss" | grep -oP '\d+\.\d+|\d+(?=% packet loss)')

			if [[ "$LOSS_Get" -eq 0 ]];then
				echo -e "ping loss "$LOSS_Get"% [\e[1;32m  PASS  \e[0;39m]"
				exit 0
			else				
				echo -e "ping loss "$LOSS_Get"% [\e[1;31m  FAIL  \e[0;39m]"
				exit 1
			fi
			ifconfig "$Interface" "0" 

		else
			echo -e "Set($Interface) IP($SetIP) [\e[1;31m  FAIL  \e[0;39m]"
			exit 1
		fi

	else
		echo -e "Interface($Interface) not exist [\e[1;31m  FAIL  \e[0;39m]"
		exit 1
	fi
else
	echo -e "Need Install net-tools [\e[1;31m  FAIL  \e[0;39m]"
	exit 1
fi
