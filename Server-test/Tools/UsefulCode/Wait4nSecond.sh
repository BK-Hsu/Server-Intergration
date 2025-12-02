#!/bin/bash
Wait4nSeconds()
{
	local second=$1
	# Wait for OP n secondes,and auto to run
	for ((p=${second:-"5"};p>=0;p--))
	do
		printf "\r\e[1;33mAfter %02d seconds will auto continue ...\e[0m" "${p}"
		read -s -t1 -n1 Ans
		if [ -n "${Ans}" ]  ; then
			break
		else
			continue
		fi
	done
	echo '' 
}

Wait4nSeconds 125