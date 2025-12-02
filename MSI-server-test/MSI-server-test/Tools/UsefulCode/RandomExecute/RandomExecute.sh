#!/bin/bash
#============================================================================================
#        File: UncontrollableLED.sh
#    Function: Random test uncontrollable LEDs one by one by manual
#     Version: 1.0.0
#      Author: Cody,qiutiqin@msi.com
#     Created: 2018-07-06
#     Updated: 
#  Department: Application engineering course
# 		 Note: BMC LED/Power LED and so on
# Environment: Linux/CentOS
#============================================================================================
#----Define sub function---------------------------------------------------------------------
#--->Show the Pass / Fail message as below:
#   Check the version of BIOS                               [  PASS  ]
#  ---------------------------------------------------------------------
echo_pass()
 { 	local String=$@ 
	echo -en "\e[1;32m $String\e[0m"
	str_len=$(echo ${#String}) 
	[[ ${pnt}x != "70"x && ${str_len} -lt 60 ]] && pnt=60 || pnt=70
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;32m  PASS  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;32m${str// /-}\e[0m"
 }
echo_fail()
 { 	local String=$@ 
	echo -en "\e[1;31m $String\e[0m"
	str_len=$(echo ${#String})
	[[ ${pnt}x != "70"x && ${Str_len} -lt 60 ]] && pnt=60 || pnt=70
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;31m  FAIL  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;31m${str// /-}\e[0m"
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

Permutation_Combination ()
{
for Argument in ${1} ${2}
do
	echo $Argument | grep -iq [1-9]
	if [ $? != 0  ]; then
		echo_fail "Invalid parameter: ${Argument}"
		let ErrorFlag++
	else
		if [ ${Argument} -ge 6 ] ; then
			echo "Attention: ${Argument} is great than 5, it will cost too much time!"
		fi
	fi
done

if [ ${1} -lt ${2} ] ; then
	echo_fail "Invalid parameter: ${1} < ${2}"
	exit 1
fi

arg0=-1
number=${2}
eval ary=({1..${1}})
length=${#ary[@]}
output(){ echo -n ${ary[${!i}]}; }
prtcom(){ nsloop i 0 number+1 output ${@}; echo; }
percom(){ nsloop i ${1} number${2} ${3} ${4} ${5}; }
detect(){ (( ${!p} == ${!q} )) && argc=1 && break 2; }
invoke(){ echo $(percom ${argu} nsloop -1) ${para} $(percom ${argu}); }
permut(){ echo -n "${1} arg${i} ${2} "; (( ${#} != 0 )) && echo -n " length "; }
nsloop(){ for((${1}=${2}+1; ${1}<${3}; ++${1})); do eval eval \\\$\{{4..${#}}\}; done; }
combin(){ (( ${#} != 0 )) && echo -n "${1} arg$((i+1)) arg${i} length " || echo -n "arg$((i+1)) "; }
prtper(){ argc=0; nsloop p 0 number+1 nsloop q p number+1 detect ${@}; (( argc == 1 )) && return; prtcom ${@}; }

case ${3} in
    p|P)para=prtper
      argu="-0 +1 permut" ;;
    c|C)para=prtcom
      argu="-1 +0 combin" ;; 
	*)
		echo_fail "Invalid parameter: ${3}"
		exit 3
	;;
esac

$(invoke)

}

 
#--->Show the usage
Usage ()
{
cat <<HELP | more
Usage: 
`basename $0` -m PcbMarking -C ColorDefine [ -d ]  [ -c ConfigFile ] [ -x ConfigFile.xml ]
	eg.: `basename $0` -m RandomLED -C 4 [ -d ]
	eg.: `basename $0` -c S165102S.ini
	eg.: `basename $0` -x S165102S.xml

	-m : PCB marking of led
	-C : The standard color of led
	-c : Config file,format as:
		#First Line: PCB marking 
		#Second Line: Standard color code of Fault or error led, Color: 1=red,2=green,3=orange,4=blue
		RandomLED
		4
		
	-x : config file,format as: *.xml
		<LedTest>
			<UncontrollableLed>
				<PowerLed>
					<PcbMarking>LED5</PcbMarking>
					<Color>1</Color>		
				</PowerLed>
				
				<BmcLed>
					<PcbMarking>LED1</PcbMarking>
					<Color>2</Color>
				</BmcLed>
				
				<LedA>
					<PcbMarking>LED-A</PcbMarking>
					<Color>3</Color>
				</LedA>
				
				<LedB>
					<PcbMarking>LED-N</PcbMarking>
					<Color>4</Color>
				</LedB>
			</UncontrollableLed>
		</LedTest>
		
	-d : For debug only,show the answer code
	
	return code:
		0 : Test pass
		1 : Test fail
		2 : File is not exist
		3 : Parameters error
	    Other : Failure
HELP

exit 3
}

#--->Get the parameters from the XML config file
GetParametersInConfig ()
{
local TestItem=LedTest

# Check the config file is exist
if [ ! -s "${ConfigFile}" ] ; then
	echo_fail "No such file or 0 KB size of file: ${ConfigFile}"
	exit 2	
fi
# Get the parameters information from the config file(*.xml)
xmllint --format ${ConfigFile} >/dev/null 2>&1
if [ $? != 0 ] ; then
	echo_fail "Invalid XML file: ${ConfigFile}"
	xmllint --format ${ConfigFile}
	exit 3
fi
 
# Get the parameters information from the config file(*.xml)
xmlstarlet sel -t -v "//${TestItem}/UncontrollableLed" ${ConfigFile} | tr -d '\t' >${BaseName}.ini 2>/dev/null
UncontrollableLedConfigFile=${BaseName}.ini
if [ ! -s "${UncontrollableLedConfigFile}" ] ; then
	echo_fail "No such file or 0 KB size of file: ${UncontrollableLedConfigFile}"
	exit 2
fi
}

echo_star ()
{
echo "****************************************************************"
}

echo_line ()
{
echo "----------------------------------------------------------------"
}

echo_red ()
{
	printf "%-3s\e[1;41m%-27s\e[0m%-23s%-10s\n" "" "[           Red           ]" " --------------------- " "`echo "press [$1]"`"
}

echo_green ()
{
 printf "%-3s\e[1;42m%-27s\e[0m%-23s%-10s\n" "" "[          Green          ]" " --------------------- " "`echo "press [$1]"`"
}

echo_orange ()
{
 printf "%-3s\e[1;43m%-27s\e[0m%-23s%-10s\n" "" "[      Orange/Amber       ]" " --------------------- " "`echo "press [$1]"`"
}

echo_blue ()
{
 printf "%-3s\e[1;44m%-27s\e[0m%-23s%-10s\n" "" "[          Blue           ]" " --------------------- " "`echo "press [$1]"`"
}

Wait4OPInput ()
{
loacl WaitTime=$1
loacl CurStdAns=$2
for ((p=$WaitTime;p>=0;p--))
do   
	echo -ne "\e[1;33m`printf "\rTime remainning: %02d seconds, input[3~6]: " "${p}"`\e[0m"
	read -t1 -n1 Ans
	[ ${#Ans} == "0" ] && continue
	
	echo "$Ans" | grep -iq "${CurStdAns}"
	if [ $? == 0 ]; then
		echo
		echo_pass "Check $PcbMarking "
		return 0
		break
	else
		echo
		echo_fail "Check $PcbMarking "
		echo "Lighting on times should be: $CurStdAns"
		return 1
	fi
done
echo

if [ $p -le 0 ] ; then
	echo -e "\e[1;31m Time out, try again ... \e[0m"
	exit 5
fi
}


UncontrollableLEDColorTest ()
{
local TargetPcbMarking="$1"
local TargetColor="$2"
# Check Uncontrollable LED
ShowMsg --b "$PcbMarking test program is runing ..."
ShowMsg --e "Comfirm the color of LED and input the color code to test ..."

RandomColorCode=(1234 4321 2143 3412 4213 2431)
Chance=3
while :
do
	# Initalizing the arrayr of StadAns	 
	StdAns=()

	#Color test
	echo_star  
	echo -e "  Check the \e[4mcolor\e[0m of \e[1;31m[\e[0m $TargetPcbMarking \e[1;31m]\e[0m ..."
	echo_line  

	RandomVal=$(($RANDOM%6))
	for((j=1;j<=4;j++))
	do
		iColor=$(echo ${RandomColorCode[$RandomVal]} | cut -c $j)
		case $iColor in
		 1)
			echo_red $j
			echo "$TargetColor" | grep -wq "1"  && StdAns[0]=$j
		 ;;

		 2)
			echo_green $j
			echo "$TargetColor" | grep -wq "2" && StdAns[1]=$j
		 ;;

		 3)
			echo_orange $j
			echo "$TargetColor" | grep -wq "3" && StdAns[2]=$j
		 ;;

		 4)
			echo_blue $j
			echo "$TargetColor" | grep -wq "4" && StdAns[3]=$j
		 ;;   
		 esac
	done
	echo_star
	
	[ $Debug == 'enable' ] && echo  -n "For debug only, the answer is: "
	SoleStdAns="debug"
	for ((h=0;h<4;h++)) 
	do
		if [ ${#StdAns[$h]} != 0 ] ; then
			[ $Debug == 'enable' ] && echo -n "${StdAns[$h]}, "
			SoleStdAns="${SoleStdAns}\|${StdAns[$h]}"
		fi
	done
	echo 
	
	echo -e "\e[0;33m It's only 15 seconds to answer ... \e[0m"
	read -p "What the color do you see? press the right color code: 1,2,3 or 4: " -t 15 -n1 COLOR
	COLOR=${COLOR:-5}
	echo ${COLOR} |  grep -wq "${SoleStdAns}"
	if [ $? == 0 ] ; then
		echo
		echo_pass "$TargetPcbMarking color test"
		return 0
	else
		echo
		if [ $COLOR == 5 ]; then
			echo -e "\e[1;31m Time out ...\e[0m"
		fi
		
		echo_fail "$TargetPcbMarking color test"
	
		if [ $Chance == 0 ] ; then
			return 1
		else
			echo -e "\e[1;33m [ ${Chance}/3 ] Try again ...\e[0m"
		fi
		let Chance--
	fi
done
}

UncontrollableLEDRandomTest ()
{
if [ ${#UncontrollableLedConfigFile} != 0 ] ; then
	TotalLine=$(cat ${UncontrollableLedConfigFile}  2>/dev/null | grep -v "^$" | grep -v '#' | wc -l )
	TotalLineODD=$(($TotalLine%2))
	if [ $TotalLineODD != 0 ] ; then
		echo_fail "Total line is ODD, invalid config file: ${UncontrollableLedConfigFile}"
		exit 3
	fi
	
	R=0
	for((r=1,s=2;s<=${TotalLine};r=r+2,s=s+2))
	do
		PcbMarking[$R]=$(cat ${UncontrollableLedConfigFile}  2>/dev/null | grep -v "^$" | grep -v '#' | sed -n ${r}p)
		ColorCode[$R]=$(cat ${UncontrollableLedConfigFile}  2>/dev/null | grep -v "^$" | grep -v '#' | sed -n ${s}p)
		let R++
	done
fi

if [ ${#PcbMarking[@]} != ${#ColorCode[@]} ] ; then
	echo_fail "Parameter amount is not match"
	echo "PcbMarking, ${#PcbMarking[@]}; ${PcbMarking[@]}"
	echo "ColorCode, ${#ColorCode[@]}; ${ColorCode[@]}"
	exit 3
fi
rm -rf ${BaseName}.random
Permutation_Combination ${#PcbMarking[@]} ${#PcbMarking[@]} p > ${BaseName}.random
sync;sync;sync

if [ ! -s "${BaseName}.random" ] ; then
	echo_fail "No such file or 0 KB size of file: ${BaseName}.random"
	exit 2
else
	TTLline=$(cat ${BaseName}.random | wc -l )
	let GetRandomLine=$(($RANDOM%${TTLline}))+1
	GetRandomLineText=$(sed -n ${GetRandomLine}p ${BaseName}.random)
fi

for ((t=1;t<=${#GetRandomLineText};t++))
do
	nBit=$(echo $GetRandomLineText | cut -c $t )
	let nBit--

	clear
	UncontrollableLEDColorTest ${PcbMarking[$nBit]} ${ColorCode[$nBit]}
	if [ $? != 0 ] ; then
		let ErrorFlag++
		sleep 2
	fi
done
}
#----Main function-----------------------------------------------------------------------------
declare CurDir='/TestAP/led'
declare -i ErrorFlag=0
declare Debug='disable'
declare ConfigFile UncontrollableLedConfigFile ColorCode PcbMarking
declare BaseName=$(echo `basename $0` | awk -F'.sh' '{print $1}' | tr -d './')
#Change the directory
cd ${CurDir} >/dev/null 2>&1 

if [ $# -lt 1 ] ; then
	Usage 
fi

#--->Get and process the parameters
while getopts :m:C:dc:x: argv
	do
	 case ${argv} in
	 	d)
			Debug='enable'
		;;
		
		x)
			ConfigFile=${OPTARG}
			GetParametersInConfig
			break
		;;
		
		m)
			PcbMarking=(${OPTARG})
		;;		
		
		C)
			ColorCode=(${OPTARG})
		;;
		
		c)
			UncontrollableLedConfigFile=${OPTARG}
			if [ ! -s "${UncontrollableLedConfigFile}" ] ; then
				echo_fail "No such file or 0 KB size of file: ${UncontrollableLedConfigFile}"
				exit 2
			fi
			break
		;;

		:)
			echo "The option ${OPTARG} requires an argument."
			Usage
			exit 3
		;;
		
		?)
			echo "Invalid option: ${OPTARG}"
			Usage
			exit 3			
		;;
		esac
	
	done

UncontrollableLEDRandomTest	
[ ${ErrorFlag} != 0 ] && exit 1
exit 0
