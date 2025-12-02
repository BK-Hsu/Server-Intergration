#!/bin/bash
#============================================================================================
#        File: TestAP.sh
#    Function: Main program
#     Version: 1.2.0
#      Author: Cody,qiutiqin@msi.com
#     Created: 2018-07-02
#     Updated: 2020-11-18
#  Department: Application engineering course
# 		 Note: 1.1.0更新：項目的index不需連續也可以進行測試,方便PE debug
# Environment: Linux/CentOS
#============================================================================================
#----Define sub function---------------------------------------------------------------------


Process()
{ 	
	local Status="$1"
	local String="$2"
	case ${Status} in
		0)printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "${String}";;
		*)printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "${String}" && return 1;;
		esac
	return 0
}

Wait4nSeconds ()
{
	local CycleTime=$1
	for ((p=${CycleTime:-15};p>0;p--))
	do   
		if [ ${CycleTime} -le 30 ] ; then
			printf "\rPress \e[1;33m[y]\e[0m key to continue, \e[1;33m[q]\e[0m to quit, after %02d seconds auto continue ..." "${p}"
			read -s -t 1 -n1 Ans
		else
			if [ ${p} == ${CycleTime} ] ; then
				printf "Press \e[1;33m[Y/y]\e[0m key to continue, \e[1;33m[q/Q]\e[0m to quit ...\n"
				printf "$((${p}/60)) min remaining"
			fi
			
			printf "."
			if [ $((${p}%60)) == 0 ] ; then
				printf "\r                                                                                \r$((${p}/60-1)) min remaining"
			fi
			
			read -s -t 0.9 -n1 Ans
		fi
		
		case ${Ans:-h} in
		Y|y) echo && break;;
		Q|q) echo && return 1 ;;
		 *) : ;;
		esac
	done
	echo ''
	return 0
} 


CheckSizeOfLog ()
{
	local TargetLog=$1
	#大於5MB的文件不給上傳FTP
	# Usage: CheckSizeOfLog logName
	local FileSize=$(stat -c "%s" ${TargetLog} 2>/dev/null)
	if [ ${FileSize:-"1048"} -gt 5242880 ] ; then
		Process 1 "The size of ${TargetLog} is too big(size=${FileSize} B, bigger than 5MB)"
		ls -lh ${TargetLog} 2>/dev/null
		exit 1
	fi
	return 0
}

IgnoreSpecTestItem()
{
	local ShellName="${1}"   #e.g.: ShellName=/TestAP/Bios/ChkBios.sh
	local ShellIndex="${2}"  #e.g.: ShellIndex=2
	local SuitForModels=()
		
	local MainPath=$(echo "${ShellName}" | awk -F'/' '{print $2}')
	#local ShellModelTable=($(xmlstarlet sel -t -v "//Programs/Item[@index=\"${ShellIndex}\"]/@model|//Programs/Item[@index=\"${ShellIndex}\"]" -n "${XmlConfigFile}" | sed ":a;N;s/.sh\n/.sh|/g;ba" ))
	local ShellModelTable=($(xmlstarlet sel -t -v "//Programs/Item[@index=\"${ShellIndex}\"]/@model|//Programs/Item[@index=\"${ShellIndex}\"]" -n "${XmlConfigFile}" | sed ":a;N;s/\n/|/g;ba" | sed "s/|\/${MainPath}/\n\/${MainPath}/g"))
	SuitForModels=($(echo "${ShellModelTable[@]}" | tr ' ' '\n' | grep -w "${ShellName}" | awk -F'|' '{print $2}' | tr ',;' ' ' | grep -iwv "all" ))
	
	if [ "${#SuitForModels[@]}" == 0  ] ; then
		# if SuitForModels is null ,all model will run all items
		return 0
	fi

	# remove the ShellName
	local SoleSuitForModels=($(echo ${SuitForModels[@]} | tr ' ' '\n' | sort -u ))
	SoleSuitForModels=$(echo ${SoleSuitForModels[@]} | sed 's/ /\\|/g')
	local ModelSet=$(echo "${SoleSuitForModels}" | tr '|' ' ' | tr '\\ ' ' ' )
	cat -v "${MainDir}/PPID/SN_MODEL_TABLE.TXT" 2>/dev/null | grep -iq "${SoleSuitForModels}"
	if [ $? == 0 ] ; then
		printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
		printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "${ShellName} is suitable for the model: ${ModelSet}"  "** "
		printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
	else
		printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
		printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "No found the model: ${ModelSet}"  "** "
		printf "\e[0;30;43m%-6s%-60s%6s\e[0m\n" " **"  "${ShellName} isn't suitable for current model! "  "** "
		printf "\e[0;30;43m%-72s\e[0m\n" " ********************************************************************** "
		return 1
	fi
	return 0
}



ChkExternalCommands ()
{
	if [ $# == 0 ] ; then
		ExtCmmds=(xmlstarlet stat getCmosDST)
	else 
		ExtCmmds=(xmlstarlet $@ )
	fi
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
	return 0
}


GetParametersFrXML ()
{
	xmlstarlet val "${XmlConfigFile}" >/dev/null 2>&1
	if [ $? != 0 ] ; then
		xmlstarlet fo ${XmlConfigFile}
		Process 1 "Invalid XML file: ${XmlConfigFile}"
		exit 3
	fi
	

	# 從XML獲取參數
	ModelName=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/ModelInfo/ModelName" -n "${XmlConfigFile}" 2>/dev/null)
	Encrypt=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/Encrypt/InUse" -n "${XmlConfigFile}" 2>/dev/null)
	EncryptPassword=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/Encrypt/Password" -n "${XmlConfigFile}" 2>/dev/null)

	
	#FailCntLimit=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"${BaseName}\"]/Pretest/FailLockAndUpload/MaximumFailures" -n "${XmlConfigFile}" 2>/dev/null)
	FailLocking=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/FailLockAndUpload/FailLocking" -n "${XmlConfigFile}" 2>/dev/null)
	FailUpload=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/FailLockAndUpload/FailUpload" -n "${XmlConfigFile}" 2>/dev/null)
	IndexInUse=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/FailLockAndUpload/UrlAddress/IndexInUse" -n "${XmlConfigFile}" 2>/dev/null)
	NgLockWebSite=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/FailLockAndUpload/UrlAddress/NgLock[@index=${IndexInUse}]" -n "${XmlConfigFile}" 2>/dev/null)
	MesWebSite=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/FailLockAndUpload/UrlAddress/MesWeb[@index=${IndexInUse}]" -n "${XmlConfigFile}" 2>/dev/null)
	StartIndex=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/StartIndex" -n "${XmlConfigFile}" 2>/dev/null)
	EndIndex=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/EndIndex" -n "${XmlConfigFile}" 2>/dev/null)
	StartParalle=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/StartParalle" -n "${XmlConfigFile}" 2>/dev/null)
	TestStation=$(xmlstarlet sel -t -v "//UpLoad/StationCode" -n "${XmlConfigFile}" 2>/dev/null)
	ErrorsOccurredChk=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/ErrorsOccurredType/InUse" -n "${XmlConfigFile}" 2>/dev/null)

	if [ ${#ErrorsOccurredChk} != 0 ] ; then
		echo "${ErrorsOccurredChk}" | grep -iwq "enable\|disable" 
		if [ $? != 0 ] ; then
			Process 1 "Invalid ErrorsOccurredChk: ${ErrorsOccurredChk}"
			let ErrorFlag++
		fi
	else
		ErrorsOccurredChk='enable'
	fi
	
	[ ${ErrorFlag} != 0 ] && exit 3
	return 0
}


# Run the Test program
Run() 
{
	if [ "$#" == "0" ] ; then
	cat<<-HELP
	Usage: Run TestItem.ini"
		   eg.: Run SubShell.ini
				SubShell.ini, include sub shell path and file name
				/TestAP/lan/lan_t.sh
	HELP
		exit 4
	fi
	# Usage Run TestItem
	# 此函數將逐一執行SubShell.ini內的指定的shell腳本
	# 多行時則使用${MainDir}/MT/Multithreading.sh多線程執行

	local SubShellList=($(cat $1 2>/dev/null | grep -v "#" | grep -v "^$" | awk -F'|' '{print $1}' ))
	case ${#SubShellList[@]} in
		0)	Process 1 "$1 is an empty file ..." && exit 2 ;;
		1)	local FullProgramName=${SubShellList[0]};;
		*)	
			if [ -f "${MainDir}/MT/Multithreading" ] ; then
				local FullProgramName=${MainDir}/MT/Multithreading
			else
				local FullProgramName=${MainDir}/MT/Multithreading.sh
			fi
		;;
			
		esac

	# if FullProgramName=${MainDir}/MT/Multithreading.sh, then ProgramName=Multithreading.sh
	local ProgramName=${FullProgramName##*/}

	# Check the proc file exist firstly
	if [ -f "${WorkPath}/logs/${pcb}.proc" ] && [ $(cat -v "${WorkPath}/logs/${pcb}.proc" 2>/dev/null | grep -Ec "^[0-9]") == 0 ]; then
		Process 1 "${WorkPath}/logs/${pcb}.proc is an empty file or no such file ..."
		exit 2
	fi


	# Run this test item
	#CheckVbatAndCmostime ${ProcID} | tee -a "${MainLog}"
	if [ $((ProcID%3)) == 1 ] ; then
		# Check the Error Occurred
		CheckErrorOccurred || exit 1
	fi
	
	# Change the Directory and add test app execute permission 
	chmod 777 ${FullProgramName} >/dev/null 2>&1

	#Check proc file
	if [ -f "${WorkPath}/logs/${pcb}.proc" ] ; then
		cd "${WorkPath}/logs"
		md5sum -c "${WorkPath}/logs/.procMD5" --status >/dev/null 2>&1
		if [ "$?" -ne 0 ]; then
			Process 1 "Check ${WorkPath}/logs/${pcb}.proc" | tee -a "${MainLog}"
			printf "%-10s%-60s\n" "" "Don not modify: ${WorkPath}/logs/${pcb}.proc ..."
			exit 4
		fi
		cd ${WorkPath}
	fi

	CheckSizeOfLog "${MainLog}"

	echo "[${ProcID}/${#TotalItemIndex[@]}] ${FullProgramName} start to run in: `date "+%Y-%m-%d %H:%M:%S %z"`" | tee -a "${MainLog}"
	StartTime=$(date +%s.%N)

	while :
	do
		CurFailCnt=$(cat -v "${MainLog}" 2>/dev/null | grep -w "${ProgramName}" | tr -d ' ' | grep  -ic "TestFail")

		# Run the Test item
		[ ! -d "${WorkPath}/logs" ] && mkdir -p "${WorkPath}/logs" 2>/dev/null
		echo "0" > ${WorkPath}/logs/result.tmp
		sync;sync;sync
		
		# For Batch Test
		IgnoreSpecTestItem ${ProgramName} ${TotalItemIndex[$z]}
		if [ $? == 0 ] ; then
			if [ "$(${FullProgramName} -P ${XmlConfigFile} 2>&1 | grep -ic "ParallelTest")" == 0 ] ; then
				# Not MT Shell exclude "ShowTestResultOnScreem"
				{ 	echo "${FullProgramName##*.}" | grep -iwq "py"
					if [ $? == 0 ] ; then
						python3 ${FullProgramName}
					else
						${FullProgramName} -x ${XmlConfig}
					fi
					if [ $? == 0 ] ; then
						echo "0" >  ${WorkPath}/logs/result.tmp
					else
						echo "1" >  ${WorkPath}/logs/result.tmp					
					fi
					sync;sync;sync;
				} 2>&1 | tee -a "${MainLog}" 
			else
				#MT Shell include "ShowTestResultOnScreem"
				{ 
					${FullProgramName} -Mx ${XmlConfig}
					if [ $? == 0 ] ; then
						echo "0" >  ${WorkPath}/logs/result.tmp
					else
						echo "1" >  ${WorkPath}/logs/result.tmp
					fi
					sync;sync;sync;
				}  
			fi 
			sync;sync;sync
		else
			# Save the log in MainLog
			IgnoreSpecTestItem ${ProgramName}  ${TotalItemIndex[$z]} 2>&1 | tee -a "${MainLog}"
			echo "Auto to test the next item ..." | tee -a "${MainLog}"
		fi
		
		# test fail
		if [ "$(cat ${WorkPath}/logs/result.tmp 2>/dev/null)"x != "0"x ]; then	
			echo "${FullProgramName} test fail !" | tee -a "${MainLog}" 		
			sync;sync;sync
			
			if [ "${CurFailCnt}" -le "${FailCntLimit}" ]; then
				# 在fail限制的次數內，則show出fail的相關message
				# +-------------------+-----------+-------+----------------------------+
				# |   Test Item       |  ErrCode  | Retry |       Fail message         |
				# +-------------------+-----------+-------+----------------------------+
				# | Multithreading.sh |   TEXFW   |   2   |  Check BIOS version fail   |
				# | ChkBios.sh        |   TEXFW   |   2   |  Check BIOS version fail   |
				# +-------------------+-----------+-------+----------------------------+
				printf "%s\n" "+-------------------+-----------+-------+----------------------------+"
				printf "%-1s%-19s%-1s%-11s%-1s%-7s%-1s%-28s%-1s\n" "|" "   Test Item" "|" "  ErrCode" "|" " Retry" "|" "       Fail message" "|"
				printf "%s\n" "+-------------------+-----------+-------+----------------------------+"
				if [ $(cat ${MainDir}/PPID/ErrorCode.TXT 2>/dev/null | grep -ic "[0-9A-Z]") -ge 1 ] ; then
					for((r=1;r<=`cat ${MainDir}/PPID/ErrorCode.TXT 2>/dev/null | wc -l`;r++))
					do
						printf "%-1s%-19s%-1s"  "|"  " `sed -n ${r}p ${MainDir}/PPID/ErrorCode.TXT | awk -F'|' '{print $3}'`"  "|" 
						printf "%-11s%-1s" "   `sed -n ${r}p ${MainDir}/PPID/ErrorCode.TXT | awk -F'|' '{print $1}'`" "|" 
						printf "%-7s%-1s" "   $((${FailCntLimit}-${CurFailCnt}))" "|" 
						printf "%-28s%-1s\n" "  `sed -n ${r}p ${MainDir}/PPID/ErrorCode.TXT | awk -F'|' '{print $2}'`" "|" 
					done
				else
					printf "%-1s%-19s%-1s%-11s%-1s%-7s%-1s%-28s%-1s\n" "|" " ${FullProgramName##*/}" "|" "    N/A" "|" "   $((4-${CurFailCnt}))" "|" "  ${FullProgramName##*/} test fail" "|"
				fi
				printf "%s\n" "+-------------------+-----------+-------+----------------------------+"				
			else					
				# if fail more than 3 times or not import ng-locking,then delete test logs
				# Fail次數”再次”超過限制的次數后將條碼按Fail上傳，锁定和上传只需选其一即可：即锁定又上传无意义
				#if [[ "${CurFailCnt}" -gt "${FailCntLimit}" && $(echo ${APVersion} | grep -ic "u") -ge 1 ]] ; then
				#	Process 1 "Failure too many time, fail uploading ..."
				#	FailLockOrUpload "UPLOAD" | tee -a "${MainLog}"
				#fi
				
				#if [[ "${CurFailCnt}" -gt "${FailCntLimit}" && $(echo ${APVersion} | grep -iv "u" | grep -ic "L") -ge 1 ]] ; then
				#	Process 1 "Failure too many time, fail locking ..."
				#	FailLockOrUpload "LOCK" | tee -a "${MainLog}"
				#fi
				
				if [ "${CurFailCnt}" -gt "${FailCntLimit}" ] ; then
					#删除 log
					if [ -f "${MainDir}/DelLog/DelLog" ] ;then
						${MainDir}/DelLog/DelLog -x ${XmlConfigFile} 2>/dev/null
					else
						${MainDir}/DelLog/DelLog.sh -x ${XmlConfigFile} 2>/dev/null
                    			fi
				fi
				#不良次數太多,退出主程式
				rm -rf ${WorkPath}/${BaseName}.ini 2>/dev/null
				exit 1
			fi

			# If test fail, press "y" key to run again or "n" key to exit						
			while :
			do
				echo -ne "Run the test again? [ \e[32mY/Enter\e[0m ]=Retest. [ \e[31mN\e[0m ]=Exit."
				read -n 1 answer
				echo ''
				case ${answer:-y} in
				Y|y)
					echo "Operator try to retest: ${FullProgramName}, this the `echo "$CurFailCnt+1" | bc `${Calender[$CurFailCnt]} time..." | tee -a "${MainLog}"
					break;;
					
				N|n)
					rm -rf ${WorkPath}/${BaseName}.ini 2>/dev/null
					exit 1;;
				esac
			done	
		else
			# If test Pass. Save ProcID in .proc file
			echo "${FullProgramName} test pass in: `date "+%Y-%m-%d %H:%M:%S %Z"`" 2>&1 | tee -a "${MainLog}"
			echo "${FullProgramName} test pass " >> "${MainLog}"
			rm -rf ${MainDir}/PPID/ErrorCode.TXT 2>/dev/null
			if [ ${ProcID} -gt ${ProcLog} ] ; then
				echo "${ProcID}" > ${WorkPath}/logs/${pcb}.proc
				md5sum ${WorkPath}/logs/${pcb}.proc > ${WorkPath}/logs/.procMD5
				sync;sync;sync
			else
				echo "No found test pass record, and now is retest mode ..."
			fi
			
			ProcID=$((${ProcID}+1))    
			break
		fi
	done

	rm -rf ${WorkPath}/logs/result.tmp 2>/dev/null
	EndTime=$(date +%s.%N)

	# Calculate the Time
	echo "${FullProgramName}" | grep -viwq "nettime\|CmosTime\|SetTime"
	if [ "$?" == 0 ] && [ "${#EndTime}"x != "0"x ]; then
		CostTime=$(printf "%.2f" `echo "scale=2;${EndTime}-${StartTime}+0 " | bc` ) 
		[ "${#CostTime}"x != "0"x ] && echo "Running ${FullProgramName} takes time: ${CostTime} seconds " | tee -a "${MainLog}"
	fi
}
# Run End

# Check Error Occurred
POST ()
{
	ChkExternalCommands "dmesg"
	xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/PowerOnSelfTest/InUse" -n "${XmlConfigFile}" 2>/dev/null | grep -iwq "disable" && return 0
	local CheckListCnt=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/PowerOnSelfTest/Item" -n "${XmlConfigFile}" 2>/dev/null | grep -v "#" | grep -v "^$" |  wc -l)
	for ((e=1;e<=${CheckListCnt};e++))
	do
		local CheckList=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/Pretest/PowerOnSelfTest/Item[$e]" -n "${XmlConfigFile}" 2>/dev/null | grep -v "#" | grep -v "^$" | grep -E '[0-9A-Z]')
		local Amount=$(dmesg | grep -ic "${CheckList}")
		if [ ${Amount} != 0 ] ; then
			dmesg | grep -i "${CheckList}" >> "${MainLog}"
			sync;sync;sync
			Process 1 "Found \"${CheckList}\" orccur ${Amount} times ..."
			let ErrorFlag++
		fi
	done
	[ ${ErrorFlag} != 0 ] && return 1
	return 0
}

#----------------------------------------------------------------------------------------------
# Check Error Occurred
CheckErrorOccurred ()
{
	ChkExternalCommands "dmesg"
	local ErrorOccurredFlag='0'
	local ErrorOccurredList='ErrorOccurredList'
	local CheckListCnt=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/ErrorsOccurredType/Item" -n "${XmlConfigFile}" 2>/dev/null | grep -v "#" | grep -v "^$" |  wc -l)
	for ((e=1;e<=${CheckListCnt};e++))
	do
		local CheckList=$(xmlstarlet sel -t -v "//MainProg[ProgramName=\"TestAP\"]/ErrorsOccurredType/Item[$e]" -n "${XmlConfigFile}" 2>/dev/null | grep -v "#" | grep -v "^$" | grep -iE '[0-9A-Z]')
		local Amount=$(dmesg | grep -ic "${CheckList}")
		if [ ${Amount} != 0 ] ; then
			echo ${ErrorsOccurredChk} | grep -iwq "disable" 
			if [ $? == 0 ] ; then	
				printf "%-1s\e[1;33m%-7s\e[0m%-2s%-60s\n" "[" "Warning" "] " "Found \"${CheckList}\" occurred ${Amount} time(s) in total ..."
			else
				Process 1 "Found \"${CheckList}\" occurred ${Amount} time(s) in total ..."
			fi
			ErrorOccurredList=$(echo ${ErrorOccurredList}\|${CheckList})
			let ErrorOccurredFlag++
		fi
	done
	if [ ${ErrorOccurredFlag} != 0 ] ; then
		echo "======================================================================" | tee -a "${MainLog}"
		printf "\e[1;33m%s\e[0m\n" "Error occurred detail: "						  | tee -a "${MainLog}"
		dmesg -T | grep -iwE "${ErrorOccurredList}"					  				  | tee -a "${MainLog}"
		echo "======================================================================" | tee -a "${MainLog}"
		echo ${ChkErrorsOccurred} | grep -iwq "disable" 
		if [ $? != 0 ] ; then
			let ErrorFlag++
			return 1
		fi
	fi
	return 0
}
#----Main function-----------------------------------------------------------------------------
# Begin the program
#Change the directory
declare XmlConfigFile XmlConfig OSType
declare ProgramFileSet ProgramNameSet
declare WorkPath=$(cd `dirname $0`; pwd)
declare MainDir="/TestAP"
declare ShellFile=$(basename $0)
declare BaseName=$(basename $0 .sh)
declare UtilityPath=$(cd `dirname $0`; cd ../utility 2>/dev/null; pwd)
declare ErrorCodeFile="${MainDir}/PPID/ErrorCode.TXT"
#declare -i StartIndex=11
#declare -i EndIndex=15
declare ErrorsOccurredChk
declare StartIndex EndIndex StartParalle
declare -i FailCntLimit=4
#export ProcLog ProcID Path pcb TestStation
declare -i ErrorFlag=0
cd ${WorkPath} >/dev/null 2>&1 
declare PATH=${PATH}:${UtilityPath}:`pwd`
declare CurPPID=$(cat ${MainDir}/PPID/PPID.TXT 2>/dev/null)

while getopts :Dx: argv
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

#XmlConfigFile=${OPTARG}
XmlConfig="${XmlConfigFile}"
if [ ${#XmlConfig} == 0 ] ; then
		XmlConfig=($(ls ../Config/*.xml 2>/dev/null ))
		if [ ${#XmlConfig[@]} -gt 1 ] ; then
			Process 1 "Too much or no found XML config file. Check XML fail"
			ls ../Config/*.xml 2>/dev/null
			exit 2
		fi
fi
declare TotalItemIndex=($(xmlstarlet sel -t -v "//Programs/Item/@index" -n ${XmlConfig} | sort -nu ))
declare MTConfigFile=$(xmlstarlet sel -t -v "//MainProg/Multithreading/TestCase[ProgramName=\"Multithreading\"]/ConfigFile" -n ${XmlConfig} )
pcb=$(cat ${MainDir}/PPID/PPID.TXT 2>/dev/null)
MainLog="${WorkPath}/logs/${pcb}.log"
if [ "${#pcb}" -gt "0" ] && [ -f "${WorkPath}/logs/${pcb}.proc" ] ; then 
	ProcLog=$(cat ${WorkPath}/logs/${pcb}.proc 2>/dev/null)
else
	ProcLog=0
fi
ProcID=1

if [ -e "${MainLog}" ] && [ ${#pcb} != 0 ] ; then
	echo -e "\e[1;36m ${pcb},  test continue ...  \e[0m" | tee -a "${MainLog}"
else
	clear
	rm -rf "${MainLog}" 2>/dev/null
fi
for ((z=0;z<${#TotalItemIndex[@]};z++))
do
	if [ ${TotalItemIndex[$z]} -eq ${StartParalle} ];then
		StartParalle=$z
		continue
	elif  [ ${TotalItemIndex[$z]} -eq ${StartIndex} ];then
		StartIndex=$z
		continue
	else
		if [ ${TotalItemIndex[$z]} -eq ${EndIndex} ];then
			EndIndex=$z
		fi
	fi
done

for ((z=${StartIndex};z<${EndIndex};z++))
do
	rm -rf ${BaseName}.ini 2>/dev/null
	xmlstarlet sel -t -v  //Programs/Item[@index=${TotalItemIndex[z]}] ${XmlConfig} 2>/dev/null | grep -iE '[0-9A-Z]' | grep -v "^$" >${BaseName}.ini
	sync;sync;sync
	
	if [ ! -s "${BaseName}.ini" ] ; then
		Process 1 "No such file or 0 KB size of file: ${BaseName}.ini"
		exit 2	
	fi
	
	ProgramFileSet=($(cat ${BaseName}.ini 2>/dev/null | grep -v "#" | grep -v "^$" ))
	ProgramNameSet=($(cat ${BaseName}.ini 2>/dev/null | grep -v "#" | grep -v "^$" | awk -F'|' '{print $1}' | awk -F'/' '{print $NF}' ))
	case ${#ProgramNameSet[@]} in
		0)	
			Process 1 "${BaseName}.ini is NULL" 
			exit 2
			;;
		*)	
			
			# Get a unique name
			ProgramNameSet=($(echo ${ProgramNameSet[@]} | tr ' ' '\n' | sort -u ))
			ProgramNameSet=$(echo ${ProgramNameSet[@]} | sed 's/ /\\|/g')
			TestPassCnt=$(cat -v ${MainLog} 2>/dev/null | grep -w ${ProgramNameSet} | tr -d ' ' | grep -ic "TestPass")
			if [ ${TestPassCnt} -ge ${#ProgramNameSet[@]} ] && [ ${ProcID} -le ${ProcLog} ] ; then
				# Current item(s) have been test pass
				ProcID=$((${ProcID}+1))
				continue
			else
				clear
				if [ ${#ProgramNameSet[@]} -gt 1 ] ; then
					rm -rf .${BaseName}.TXT >/dev/null 2>&1
					for((T=0;T<${#ProgramFileSet[@]};T++))
					do	
						PathAndShellName=$(echo "${ProgramFileSet[$T]}" | awk -F'|' '{print $1}')
						# Save the log in MainLog
						IgnoreSpecTestItem ${PathAndShellName} ${TotalItemIndex[z]} >/dev/null 2>&1
						if [ $? == 0 ] ; then
							echo "${PathAndShellName}" >> .${BaseName}.TXT
						else
							echo "Create the config file for multithreading program ..." | tee -a "${MainLog}"
							IgnoreSpecTestItem ${PathAndShellName} ${TotalItemIndex[z]} 2>&1 | tee -a "${MainLog}"
							echo "${ProgramFileSet[$T]}" | sed 's/|/ test pass, because no found any model name of /g'  >> "${MainLog}"
							echo "Auto to check next item ..." | tee -a "${MainLog}"
							sync;sync;sync
						fi
					done
				
					if [ -s ".${BaseName}.TXT" ] ; then
						mv -f .${BaseName}.TXT ${BaseName}.ini  >/dev/null 2>&1
					else
						ProcID=$((${ProcID}+1))
						echo "${ProcID}" > ${WorkPath}/logs/${pcb}.proc
						md5sum ${WorkPath}/logs/${pcb}.proc > ${WorkPath}/logs/.procMD5
						sync;sync;sync
						continue
					fi
					
					cp ${BaseName}.ini ${MTConfigFile} >/dev/null 2>&1 || exit 255
					sync;sync;sync
				fi
				
				Run ${BaseName}.ini
			fi		
			;;
	esac	
done
echo "ok" > /TestAP/PPID/.ParalleFinishflag
cat ${MainLog} 2>/dev/null >> /TestAP/PPID/${pcb}.log
sync;sync;sync
exit 0


