#!/bin/bash
rm -rf t.txt
touch t.txt
length=32
while :
do
	sort -u  t.txt  | wc -l | grep -wq "${length}" && break
	echo $(($RANDOM%${length}+1)) >>t.txt
done

#sort t.txt | uniq 
AllNum=($(cat t.txt))
a[0]=$(head -n1 t.txt) 	
for((j=1;j<${length};j++))
do
	SoleA=($(echo ${a[@]} | tr ' ' '\n' | sort -u ))
	SoleA=$(echo ${SoleA[@]} | sed 's/ /\\|/g')
	#echo SoleA: ${SoleA}
	for ((n=0;n<${#AllNum[@]};n++))
	do
		echo ${AllNum[n]} | grep -iwq "${SoleA}" 
		if [ $? != 0 ] ; then
			a[j]=${AllNum[n]}
			continue 2
		fi
	done
done
echo +++++++++++++
echo a: ${a[@]}

