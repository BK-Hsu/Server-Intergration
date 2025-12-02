
#返回数组的最大/最小值和其对应的索引
List_tmp=(1 2 3 45 85 4)

ArrayMax()
{
	local List=($(echo $@))
	MaxValue=${List[0]}
	MaxIndex=0
	for((i=0;i<${#List[@]};i++))
	do
		if [ ${List[$i]} -gt ${MaxValue} ] ; then
			MaxValue=${List[$i]}
			MaxIndex=$i
		fi
	done
	printf "%s\n" "${MaxIndex} ${MaxValue}"
}

ArrayMin()
{
	local List=($(echo $@))
	MinValue=${List[0]}
	MinIndex=0
	for((i=0;i<${#List[@]};i++))
	do
		if [ ${List[$i]} -lt ${MinValue} ] ; then
			MinValue=${List[$i]}
			MinIndex=$i
		fi
	done
	printf "%s\n" "${MinIndex} ${MinValue}"
}

MaxTuple=($(ArrayMax "${List_tmp[@]}"))
MinTuple=($(ArrayMin "${List_tmp[@]}"))
echo "++++++++++++"
echo ${MaxTuple[0]}
echo ${MaxTuple[1]}
echo "++++++++++++"
echo ${MinTuple[0]}
echo ${MinTuple[1]}
