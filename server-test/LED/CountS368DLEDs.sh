#!/bin/bash
WorkPath=$(cd `dirname $0`; pwd)
cd ${WorkPath}
if [ -f CountS368DLEDs ] ; then
	chmod 777 CountS368DLEDs
else
	echo "No such file: CountS368DLEDs"
fi

./CountS368DLEDs $@
exit $?


