#!/usr/bin/env python
# coding:utf-8
#------------------------------------------------------------------------
# Author: Ego
# mail: Yohua2013@outlook.com Ext:2573
# Created Time:  2019-09-16 13:18:05
# Script Release Ver: 0.0.0.1
# Function:
# Detail:
#------------------------------------------------------------------------
import os
import sys
from time import sleep
from subprocess import Popen, PIPE
#from print_format import printc, printr, printp, printf



def execCmd(cmd):
	#with Popen(cmd, shell=True, stdout=PIPE, encoding='utf-8') as f:
	with Popen(cmd, shell=True, stdout=PIPE) as f:
		print(f.stdout.read().strip())
		return f.stdout.read().strip()



def nmiButtonTest():
	cmd = "ipmitool raw 0x38 0x12 0x84"
	waitaSecond("NMI")
	desdata = execCmd(cmd)
	comparisonData("00", desdata, "NMI")
	


def idButtonTest():
	cmd = "ipmitool raw 0x38 0x12 0x24"
	waitaSecond("ID")
	desdata = execCmd(cmd)
	print(desdata)
	comparisonData("00", desdata, "ID")



def waitaSecond(promptstatement):
	print("Press and hold the %s button for few seconds."%promptstatement)
	print("You have 5 secs to operate.")
	sleep(5)



def comparisonData(srsdata, desdata, promptstatement):
	if srsdata == desdata:
		print("%s Button Test"%promptstatement)
	else:
		print("%s Button Test"%promptstatement)
		sys.exit(1)


if __name__ == '__main__':
	idButtonTest()
	nmiButtonTest()







