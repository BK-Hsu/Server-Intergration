#/bin/bash
cd /TestAP/LED
python -u DimmLED.py

if [[ $? == "0" ]]
then
	echo "$0 test pass"
	exit 0
else
	echo "$0 test fail"
	exit 1
fi

