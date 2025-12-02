#!/bin/bash
for((t=`xmlstarlet sel -t -v  //Programs/Item config.xml 2>/dev/null | grep -icE '[0-9A-Z]'`;t>0;t--))
do
	xmlstarlet sel -t -v  //Programs/Item[@index=\"${t}\"] config.xml 2>/dev/null | grep -iqE '[0-9A-Z]'
	if [ $? == 0 ] ; then 
		TotalItemCnt=$t
		break
	fi
done
echo "TotalItemCnt: $TotalItemCnt"

