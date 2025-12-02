#!/bin/bash
###################################
# Version: V1.0.0
#  Create: 2017-08-10
#  Update: 2017-08-10
#  Author: Cody
###################################
sub_shell=(led1.sh led2.sh led3.sh)

cd  /TestAP/led 2>/dev/null || cd  /TestAP/LED 2>/dev/null
#------Sub Function-------------------------------------------------------------------------
echo_pass()
 { 	local String=$@ 
		echo -en "\e[1;32m $String\e[0m"
		String_byte=$(echo ${String} | wc -c); [[ ${pnt}x != "70"x && ${String_byte} -lt 60 ]] && pnt=60 || pnt=70
		let PNT=${pnt}+10 
		echo -e "\e[${pnt}G [\e[1;32m  PASS  \e[0;39m]"
		str=$(printf "%-${PNT}s" "-") ; echo  -e "\e[1;32m${str// /-}\e[0m"
 }
echo_fail()
 { 	local String=$@ 
		echo -en "\e[1;31m $String\e[0m"
		String_byte=$(echo ${String} | wc -c); [[ ${pnt}x != "70"x && ${String_byte} -lt 60 ]] && pnt=60 || pnt=70
		let PNT=${pnt}+10 
		echo -e "\e[${pnt}G [\e[1;31m  FAIL  \e[0;39m]"
		str=$(printf "%-${PNT}s" "-") ; echo  -e "\e[1;31m${str// /-}\e[0m"
 }

Execute ()
{
i_shell=$1
[ ! -f $i_shell ] && echo_fail "$i_shell is not exist" && exit 1
r=1
while [ "$r" != "0" ]
 do
   # Run the Test item
    echo "OK" > rlt.tmp
    { ( sh $i_shell ) || echo "NG" > rlt.tmp;} 2>/dev/null 
    sync;sync;sync;
    Result=$(cat rlt.tmp)
    rm -f rlt.tmp	
    if [ "$Result" != "OK" ]; then	
     let r++
	 [ $r -ge 4 ] && exit 1
    else
     r=0
    fi
 done
}

#------Main Function-------------------------------------------------------------------------
case ${#sub_shell[@]} in
 2)
  situation[0]="1 2"
  situation[1]="1 2"
  situation[2]="2 1"
  situation[3]="1 2"
  situation[4]="2 1"
  situation[5]="1 2"
  situation[6]="2 1"
  situation[7]="1 2"
  situation[8]="2 1"
  situation[9]="2 1"
  ;;

 3)
  situation[0]="1 2 3"
  situation[1]="1 3 2"
  situation[2]="3 2 1"
  situation[3]="3 1 2"
  situation[4]="2 1 3"
  situation[5]="2 3 1"
  situation[6]="1 2 3"
  situation[7]="1 3 2"
  situation[8]="3 2 1"
  situation[9]="3 1 2"
  ;;

 4)
  situation[0]="1 2 3 4"
  situation[1]="1 3 2 4"
  situation[2]="1 4 2 3"
  situation[3]="2 1 3 4"
  situation[4]="2 3 1 4"
  situation[5]="2 4 3 1"
  situation[6]="3 4 2 1"
  situation[7]="3 4 1 2"
  situation[8]="4 2 3 1"
  situation[9]="4 3 2 1"
  ;;

 5)
  situation[0]="1 2 3 4 5"
  situation[1]="1 2 3 5 4"
  situation[2]="1 3 2 4 5"
  situation[3]="1 4 5 2 3"
  situation[4]="1 5 4 2 3"
  situation[5]="5 4 3 2 1"
  situation[6]="5 4 2 3 1"
  situation[7]="5 3 4 1 2"
  situation[8]="5 2 3 4 1"
  situation[9]="5 1 4 2 3"
  ;;
 esac

rand_num=$(echo $((RANDOM%10)))
CASE=($(echo ${situation[$rand_num]}))
error_flag=0
for i_num in ${CASE[@]}
do
 let i_num=${i_num}-1
 Cmd=$(echo "./${sub_shell[$i_num]}")
 Execute "$Cmd"
 if [ $? -ne 0 ] ; then
  let error_flag++
 fi
done

[ $error_flag -ne 0 ] && exit 1

exit 0
