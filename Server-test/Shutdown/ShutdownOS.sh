#!/bin/bash
#FileName : ShutdownOS.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.0.0"
	local CreatedDate="2018-07-30"
	local UpdatedDate="2018-07-30"
	local Description="Shutdown OS"
	
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

#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` [-hV]
	eg.: `basename $0`
	eg.: `basename $0` -h
	eg.: `basename $0` -V

	-h : Show the usage
	-V : Display version number and exit(1)
	
	return code:
		0 : Shutdown pass
		1 : Shutdown fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP

exit 3

}


InitializingNetCard ()
{
	rm -rf /etc/udev/rules.d/70-persistent-net.rules 2>/dev/null
	rm -rf /etc/sysconfig/network-scripts/ifcfg-eth[0-99] 2>/dev/null
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

main ()
{
	InitializingNetCard
	ProgramVer=$(cat `basename $0` | grep -i "Version" | head -n1 |awk '{print $3}')
	ShowMsg --b "Shutdown application version: $ProgramVer "
	ShowMsg --2 "After system shutdown: "
	ShowMsg --3 "-----------------------------------------------------"
	ShowMsg --4 "[1] Turn Off AC-Power more than 10 Sec "
	ShowMsg --e "[2] Follow WI to work and test"

	while :
	do

		for ((p=5;p>=0;p--))
		do   
			echo -ne "\e[1;33m`printf "\rOS will shutdown after %02d sec,press [Y] execute at once ...\n" "${p}"`\e[0m"
			read -t1 -n1 -s Ans
			if [ $(echo "$Ans" | grep -ic 'q\|y') == 1 ] ;  then
				echo
				break
			fi
		done

		Ans=${Ans:-'y'}
		
		case $Ans in
		Y|y)
			if [ ${#pcb} != 0 ] ; then
				cd ../PPID
				echo "$ProcID" > ${pcb}.proc
				md5sum ${pcb}.proc > .procMD5
				cd ${WorkPath}
				ProcID=$(($ProcID+1))
				echo 
				echo "----------------------------------------------------------------------"
				last reboot | head -3
				echo "----------------------------------------------------------------------"
				uptime 
				echo "----------------------------------------------------------------------"
				sync;sync;sync
			fi
			
			rm -rf  .proc 2>/dev/null
			rm -rf  .log 2>/dev/null
		
			echo "`basename $0` test pass in:`date "+%Y-%m-%d %a %H:%M:%S"` `date +%Z`,UTC/GMT`date +%z`" | tee -a ../PPID/${pcb}.log
			sync;sync;sync
			sleep 2
			init 0
			sleep 99999
			;;

		Q|q)
			#Enter debug mode,because of "trap" command
			echo -e "\033[1;37;44m ******************************************************************** \033[0m"
			echo -e "\033[1;37;44m *             Welcome to debug mode, for PTE/PE only !             * \033[0m"
			echo -e "\033[1;37;44m ******************************************************************** \033[0m"
			exit 1
			;;


		*)
			ShowMsg --1 "Press the wrong key,Please press Y key "
			sleep 2
			;;
			esac
	done
	sync;sync;sync
	[ ${ErrorFlag} != 0 ] && exit 1
}

#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

#--->Get and process the parameters
while getopts :P:Vhx argv
do
	 case ${argv} in
		h)
			Usage
			break
		;;
		
		x)
			:
		;;

		V)
			VersionInfo
			exit 1
		;;	

		P)
			printf "%-s\n" "SerialTest,ShutdownOS"
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
