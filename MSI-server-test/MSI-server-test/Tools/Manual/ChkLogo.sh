#!/bin/bash
#FileName : ChkLogo.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-11-13"
	local UpdatedDate="2019-07-04"
	local Description="Check the Logo while power on"
	
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
	#printf "%16s%-s\n" "" "xx,xxxxx"
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

ShowProcess()
{ 	
 local Status=$1
 local String="$2"
 case $Status in
	0)
		#[  OK  ]  Download the S1151030.tar.gz 
		printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "${String}"
	;;
	
	*)
		#[  NG  ]  Download the S1151030.tar.gz 
		printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "${String}"
		BeepRemind 1 2>/dev/null
		return 1
	;;
	esac
}

BeepRemind()
{
#Usage: BeepRemind Arg1
local Status=$1
Status=${Status:-"0"}

# load pc speaker driver
lsmod | grep -iq "pcspkr" || modprobe pcspkr

which beep > /dev/null 2>&1
if [ $? != 0 ] ; then
	return 0
fi

case ${Status} in
	0)
		#Pass/Remind
		beep -f 1800 > /dev/null 2>&1
	;;
	
	*)
		#Fail
		beep -f 800 -l 800 > /dev/null 2>&1
	;;
	esac
}


ShowMsg ()
{
local LineId=$1
local TextMsg=$@
let LineIdLen=${#LineId}+1
TextMsg=$(echo $TextMsg | cut -c $LineIdLen-62 )
TextMsgLen=${#TextMsg}
let BlanksLen=61-$TextMsgLen
Blanks=$(echo "                                                              " | cut -c 1-$BlanksLen)

echo $LineId | grep -iEq  "[1-9BbEe]"
if [ $? -ne 0 ] ; then
	echo " Usage: ShowMsg --[n|[B|b][E|e]] TextMessage"
	echo "        n=1,2,3,...,9"
	exit 3
fi

#---> Show Message
case $LineId in
	--1)	
		echo -e "\e[0;30;43m ********************************************************************* \e[0m"
		echo -e "\e[0;30;43m **  ${TextMsg}${Blanks}  ** \e[0m"
		echo -e "\e[0;30;43m ********************************************************************* \e[0m"
	;;

	--[Bb])
		echo -e "\e[0;30;43m ********************************************************************* \e[0m"
		echo -e "\e[0;30;43m **  ${TextMsg}${Blanks}  ** \e[0m"
	;;
	
	--[2-9])
		echo -e "\e[0;30;43m **  ${TextMsg}${Blanks}  ** \e[0m"
	;;
	
	--[Ee])
		echo -e "\e[0;30;43m **  ${TextMsg}${Blanks}  ** \e[0m"
		echo -e "\e[0;30;43m ********************************************************************* \e[0m"
	;;
	esac
} 
 
Wait4nSeconds()
 {
local second=$1
# Wait for OP n secondes,and auto to run
for ((p=${second};p>=0;p--))
do
	echo -ne "\e[1;33m`printf "\rAfter %02d seconds will auto continue ...\n" "${p}"`\e[0m"
	read -t1 -n1 OpAnswer 
	if [ -n "${OpAnswer}" ]  ; then
		break
	else
		continue
	fi
done
echo '' 
}
 
Main()
{
for((i=1;i<=4;i++))
do
	if [ ! -s ${i}.jpg ] ; then
		ShowProcess 1 "No such picture: ${i}.jpg"
		let ErrorFlag++
	fi
done
[ ${ErrorFlag} != 0 ] && exit 1

ShowMsg --1 "What can you saw on the sreem while the M/B power on?"
while :
do
	RandomPic=$(($RANDOM%4+1))
	`eog -f ${CurDir}/${RandomPic}.jpg 2>/dev/null` &
	Wait4nSeconds 5

	#Close the picture
	ps ax | awk '/eog /{print $1}' | while read PID
	do
		kill -9 "${PID}" > /dev/null 2>&1
	done
	
	echo -e "Press \e[1;44m[Enter]\e[0m to see again!"
	read -p "Press the code1,2,3 or 4: " -n1 OpAnswer 
	echo
	if [ ${#OpAnswer} == 0 ] ; then
		echo "See again ..."
		continue
	fi
	[ $# -ne 0 ] && echo "The logo on the pictrue ${RandomPic}.jpg is number: ${RandomPic}"
	echo "$OpAnswer" | grep -wq "${RandomPic}" 
	if [ $? == 0 ]; then
		echoPass "Check logo"
		echo  "Picture: ${CurDir}/${RandomPic}.jpg, Op input: $OpAnswer"
	else
		ShowMsg --1 "Shutdown OS and try again, or goto repair"
		echoFail "Check logo"
		let ErrorFlag++
	fi
	break
done
} 
#----Main function-----------------------------------------------------------------------------
declare CurDir='/TestAP/Logo'
declare -i ErrorFlag=0
declare OpAnswer
declare BaseName=$(echo `basename $0` | awk -F'.sh' '{print $1}' | tr -d './')
#Change the directory
cd ${CurDir} >/dev/null 2>&1 

Main $@
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
