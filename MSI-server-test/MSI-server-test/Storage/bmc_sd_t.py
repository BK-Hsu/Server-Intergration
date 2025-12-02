#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ----------------------------------------------------
# @Author  	: Ego
# @Tele	  	: 2573
# @Email   	: camelzheng@msi.com	
# @Version 	: 0.0.3
# @Create Time  : 2019-10-30 14:41:55
# ----------------------------------------------------
import os
import sys
import serial
import time
from print_format import echopass, echofail, promptr

#----------------------------------------------------
#
hostport = '/dev/ttyUSB0'
host232serial = serial.Serial(hostport, 115200, timeout=1)


def sendCommand(cmd):
	host232serial.write("{}\r".format(cmd).encode())
	#time.sleep(1)



def readCmdl():
	lines = host232serial.readlines()
	msgs = []
	for line in lines:
		msg = line.decode('utf-8', 'ignore')
		print("\033[1;34m%s\033[0m"%msg)
		msgs.append(msg)
	host232serial.flush()
	return msgs



#login system
def getStdout(String, cmd):
	for x in readCmdl():
		if String in x:
			sendCommand(cmd)



def loginSystem():
	try_choice = 0
	while True:
		if [x for x in readCmdl() if "#" in x]:break
		if try_choice == 5:
			promptr("无法login BMC console,请检查cable 线是否有正确安装在JBMC_DBG1位置")
			sys.exit(1)
		sendCommand('\r')
		getStdout("login", 'sysadmin')
		getStdout('Password', 'superuser')
		sendCommand('\r')
		try_choice += 1
		



def sdCardCheck():
	sd_location = ["/dev/mmcblk0p1", "/dev/mmcblk1p1"]
	for sd in sd_location:
		flag = False
		sendCommand("ls {}".format(sd))
		if [x for x in readCmdl() if "No such file or directory" in x]:
			echofail("\033[1;31mSD Device Not Fount\033[0m")
			sys.exit(1)
		else:
			sendCommand("mount {} /mnt".format(sd))
			readCmdl()
			
		sendCommand("echo 123 > /mnt/sd.txt")
		readCmdl()
		sendCommand("cat /mnt/sd.txt|grep 123")
		readCmdl()
		sendCommand("echo $?")
		for x in readCmdl():
			if '0' in x:
				echopass("\033[1;32mSD Card Test\033[0m")
				flag = True
				sendCommand("rm /mnt/sd.txt")
				sendCommand("umount /mnt")
				time.sleep(5)
				break
		if  not flag:
			echofail("\033[1;31mSD Card Test\033[0m")
			sendCommand("umount /mnt")
			sys.exit(1)				


if __name__ == '__main__':
	loginSystem()
	sdCardCheck()
	sendCommand("exit")
	sys.exit(0)