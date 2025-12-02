#!/bin/bash
#FileName : RGB.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="1.1.0"
	local CreatedDate="2018-07-30"
	local UpdatedDate="2019-07-04"
	local Description="RGB color Test"
	
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
	local ErrorCode=$(xmlstarlet sel -t -v "//RGB/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
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
	ExtCmmds=(stty)
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
	`basename $0` 
	eg.: `basename $0`
	eg.: `basename $0` -V

	-V : Display version number and exit(1)
	
	return code:
		0 : RGB test pass
		1 : RGB test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure

HELP
exit 3
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

# Begin of ChkRGB
chkRGB ()
{
#!/bin/bash
# This program is for the: Multi user mode with GUI 
rand_RGB=(123 132 213 231 312 321)
val=$(echo $((RANDOM%6)))
a1=$(echo ${rand_RGB[$val]} | cut -c 1-1)
a2=$(echo ${rand_RGB[$val]} | cut -c 2-2)
a3=$(echo ${rand_RGB[$val]} | cut -c 3-3)

for rand_RGB in ${a1} ${a2} ${a3}
do
	columns=`stty size | awk '{print $2}'`
	rows=`stty size | awk '{print $1}'`
	avg=$columns
	avg_3rd=$columns

	str=-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	tmp=`echo ${str:0:avg}`
	tmp_3rd=`echo ${str:0:avg_3rd}`
	for ((i=1;i<$rows+1;i++))
	do
		case ${rand_RGB} in
			1)
				# RGB
				echo -e -n "\033[41;31m$tmp\033[0m"
			;;

			2)
				# GBR
				echo -e -n "\033[42;32m$tmp\033[0m"
			;;

			3)
				# BRG
				echo -e -n "\033[44;34m$tmp_3rd\033[0m"	
			;;
			esac

		if [ $i = $rows ];then
			read -t 5
		fi
	done
done
echo

echo -e "\e[1;33mCheck RGB is normal ?\e[0m"
maxCT=15

modprobe pcspkr
echo -e '\a' > /dev/console 2>/dev/null

for ((p=$maxCT;p>=0;p--))
do   
	printf "\r\e[1;33mTimeremainning:%02d sec,Press Y or N ...\e[0m" "${p}"
	read -t1 -n1 -s Ans
	if [ "$Ans"x == "Y"x ] || [ "$Ans"x == "y"x ]; then
		echo "Y" > ./ANS.log
		break
	fi

	if [ "$Ans"x == "N"x ] || [ "$Ans"x == "n"x ]; then
		echo "N" > ./ANS.log
		echo
		echoFail "Check RGB"
		exit 1
	fi
done
echo

if [ "$p" -le "0" ] ; then
	Process 1 "Time Out,Check RGB fail."
	exit 1
fi

} 
# End of chkRGB

#Creat the shell of chkRGB.sh,which shell is necessary
Creat_chkRGB ()
{
	b_line=$(cat -n `basename $0` | grep -i "Begin of ChkRGB" | head -n1 | awk '{print $1}')
	e_line=$(cat -n `basename $0` | grep -i "End of chkRGB"   | head -n1 | awk '{print $1}')
	let b_line=$b_line+2
	let e_line=$e_line-2
	let g_line=$e_line-$b_line
	head -n $e_line `basename $0` | tail -n $g_line > chkRGB.sh
	sync;sync;sync
	chmod 777 chkRGB.sh
}

CreateDigit()
{
	cat <<-Nine >9
			   
	  9 9 9 9 9 9 9   
	  9 9 9 9 9 9 9   
	  9 9       9 9   
	  9 9       9 9   
	  9 9 9 9 9 9 9   
	  9 9 9 9 9 9 9   
				9 9   
				9 9   
	  9 9 9 9 9 9 9   
	  9 9 9 9 9 9 9   

	Nine

	cat <<-Eight >8
			   
	  8 8 8 8 8 8 8   
	  8 8 8 8 8 8 8   
	  8 8       8 8   
	  8 8       8 8   
	  8 8 8 8 8 8 8   
	  8 8 8 8 8 8 8   
	  8 8       8 8   
	  8 8       8 8   
	  8 8 8 8 8 8 8   
	  8 8 8 8 8 8 8   

	Eight

	cat <<-Seven >7
			   
	  7 7 7 7 7 7 7   
	  7 7 7 7 7 7 7   
				7 7   
				7 7   
				7 7   
				7 7   
				7 7   
				7 7   
				7 7   
				7 7   

	Seven

	cat <<-Six >6
			   
	  6 6 6 6 6 6 6   
	  6 6 6 6 6 6 6   
	  6 6        
	  6 6        
	  6 6 6 6 6 6 6   
	  6 6 6 6 6 6 6   
	  6 6       6 6   
	  6 6       6 6   
	  6 6 6 6 6 6 6   
	  6 6 6 6 6 6 6   

	Six

	cat <<-Five >5
			   
	  5 5 5 5 5 5 5   
	  5 5 5 5 5 5 5   
	  5 5        
	  5 5        
	  5 5 5 5 5 5 5   
	  5 5 5 5 5 5 5   
				5 5   
				5 5   
	  5 5 5 5 5 5 5   
	  5 5 5 5 5 5 5   

	Five

	cat <<-Four >4
			   
	  4 4       4 4   
	  4 4       4 4   
	  4 4       4 4   
	  4 4       4 4   
	  4 4 4 4 4 4 4   
	  4 4 4 4 4 4 4   
				4 4   
				4 4   
				4 4   
				4 4   

	Four

	cat <<-Three >3
			   
	  3 3 3 3 3 3 3   
	  3 3 3 3 3 3 3   
				3 3   
				3 3   
	  3 3 3 3 3 3 3   
	  3 3 3 3 3 3 3   
				3 3   
				3 3   
	  3 3 3 3 3 3 3   
	  3 3 3 3 3 3 3   

	Three

	cat <<-Two >2
			   
	  2 2 2 2 2 2 2   
	  2 2 2 2 2 2 2   
				2 2   
				2 2   
	  2 2 2 2 2 2 2   
	  2 2 2 2 2 2 2   
	  2 2        
	  2 2        
	  2 2 2 2 2 2 2   
	  2 2 2 2 2 2 2   

	Two

	cat <<-One >1
			   
		   1 1   
		   1 1   
		   1 1   
		   1 1   
		   1 1   
		   1 1   
		   1 1   
		   1 1   
		   1 1   
		   1 1   

	One

	cat <<-Zero >0
			   
	  0 0 0 0 0 0 0   
	  0 0 0 0 0 0 0   
	  0 0       0 0   
	  0 0       0 0   
	  0 0       0 0   
	  0 0       0 0   
	  0 0       0 0   
	  0 0       0 0   
	  0 0 0 0 0 0 0   
	  0 0 0 0 0 0 0   

	Zero

	for $i in {1...9}
	do
		if [ ! -f "${i}" ] ; then 
			Process 1 "No such file: $i"
			let ErrorFlag++
		fi
	done
	[ ${ErrorFlag} != 0 ] && exit 1
}

RGBTest()
{
	rm -rf ./ANS.log ./chkRGB.sh 2>/dev/null
	rm -rf 0 1 2 3 4 5 6 7 8 9 >/dev/null
	CreateDigit 2>/dev/null
	Creat_chkRGB 2>/dev/null

	# if runlevel is 5, set the terminal is full-screen
	if [ $(runlevel | awk '{print $2}') == "5" ] ; then
		gnome-terminal --full-screen --zoom=1.4 -x bash -c "${CurDir}/chkRGB.sh"
		if [ $? != 0 ] ; then
			echo 'y' >./ANS.log
			sync;sync;sync
		fi
	else
		sh ./chkRGB.sh
	fi

	# Get an Random number
	for d in 1 2 3
	do
		randval[$d]=$(echo $((RANDOM%10)))
	done
	Standard_Ans="${randval[1]}${randval[2]}${randval[3]}"

	#color Random
	color=(123 132 231 213 321 312)
	rand_col=$(echo $((RANDOM%6)))

	for((j=1;j<=3;j=j+1))
	do
		color_random=$(echo ${color[$rand_col]} | cut -c $j) 
		if [ $color_random == 3 ] ; then 
			clr=4
		else
			clr=$color_random
		fi


		echo -e "\e[1;30;4${clr}m`cat ./${randval[$j]}`\e[0m"
		BeepRemind 0
		[ $# -ne 0 ] && echo "For debug only, the answer is: `echo $Standard_Ans | cut -c $j`"
		read -p "Input the number which show above: " -n1 ANS[$j]
		answer="${answer}${ANS[$j]}"
		echo
	done  

	if [ "$answer"x != "$Standard_Ans"x ] ; then        
		echo
		Process 1 "Check RGB color(The answer should be: $Standard_Ans) fail" 
		rm -rf ./ANS.log ./chkRGB.sh 2>/dev/null	
		exit 1
	fi

	if [ $(cat ./ANS.log 2>/dev/null | grep -ic "y" ) == 0 ] ; then
		Process 1 "RGB screen is abnormal,check RGB fail."
		rm -rf ./ANS.log ./chkRGB.sh 2>/dev/null
		exit 1
	fi	 

	echoPass "Check RGB color(The answer is: $Standard_Ans)"	
	rm -rf ./ANS.log ./chkRGB.sh 2>/dev/null
	rm -rf 0 1 2 3 4 5 6 7 8 9 >/dev/null
}
#----Main function-----------------------------------------------------------------------------
declare WorkPath=$(cd `dirname $0`; pwd)
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare -i ErrorFlag=0
declare ConfigFile
declare OsVersion=$(uname -r | cut -c 1)
#Change the directory
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`

[ "$1"x == "-P"x ] && exit 1
[ "$1"x == "-V"x ] && VersionInfo
ChkExternalCommands
RGBTest
	
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
