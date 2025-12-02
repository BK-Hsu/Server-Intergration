#!/bin/bash
array_num=(121 122 211 212)
a=$[RANDOM%4]
aws=${array_num[$a]}
for((i=0;i<=2;i++));
do
	s1=$(echo $aws | cut -b $i+1 )
	read -p "please input the light num:" num
	echo "num:"$num
	echo "s1:"$s1
	if [[ $num == $s1 ]]
	then
		echo "pass"
	else:
		echo "fail"
	fi
done


