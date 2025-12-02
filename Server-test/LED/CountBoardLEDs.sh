#!/bin/bash
WorkPath=$(cd `dirname $0`; pwd)
cd ${WorkPath}
if [ -f CountBoardLEDs ] ; then
	chmod 777 CountBoardLEDs
else
	echo "No such file: CountBoardLEDs"
fi

./CountBoardLEDs $@
exit $?


