#!/bin/bash
Permutation_Combination ()
{
	for Argument in ${1} ${2} # Usage: Permutation_Combination 6 3 p 
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



echoPass()
 { 	local String=$@ 
	echo -en "\e[1;32m $String\e[0m"
	str_len=$(echo ${#String}) 
	[[ ${pnt}x != "70"x && ${str_len} -lt 60 ]] && pnt=60 || pnt=70
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;32m  PASS  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;32m${str// /-}\e[0m"
 }
echoFail()
 { 	local String=$@ 
	echo -en "\e[1;31m $String\e[0m"
	str_len=$(echo ${#String})
	[[ ${pnt}x != "70"x && ${Str_len} -lt 60 ]] && pnt=60 || pnt=70
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;31m  FAIL  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;31m${str// /-}\e[0m"
 }
 
Permutation_Combination  $1 $2 $3