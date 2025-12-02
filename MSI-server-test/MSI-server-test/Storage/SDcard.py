#!/usr/bin/env python3
# coding:utf-8
# ------------------------------------------------------------------------
# File Name: SDcard.py
# Author: Kingsley
# mail: kingsleywang@msi.com Ext:2573
# Created Time: 09,05,2022
# Script Release Ver: 1.0.0.0
# ------------------------------------------------------------------------
from print_format import *
#import random 
#from random import sample, choice
import os, sys
import time
from subprocess import run , PIPE

def Fail_action(msg):
    echofail(msg)
    global config
    errorcode_file = "/TestAP/PPID/ErrorCode.TXT"
    errorcode = config['errorcode']
    with open(errorcode_file, 'a+', encoding='utf-8') as f:
        if BaseName not in f.read():
            f.write(errorcode + "|" + BaseName + "\n" )
    raise Exception("\033[1;31m %s \033[0m" % msg)

if __name__ == '__main__':
    try:
        if sys.argv[1] == "-P":
            print("SerialTest")
            exit(1)
    except IndexError:
        pass
    BaseName = os.path.basename(__file__)
    config_path = os.path.abspath(__file__).split(".")[0] + ".json"
    with open(config_path, 'r', encoding='utf-8') as json_file:
        config = json.load(json_file)
	time.sleep(2)
	#sd_shell = "ipmitool raw 0x38 0x18"
	sd_dict = config['sd_dict']
	detect_status = "00"
	errorflag = 0
	for sdcard in sd_dict:
	sd_detect = run(sdcard["shell_cmd"], shell=True, stdout=PIPE, encoding='utf-8')
	print(sd_detect.stdout.strip())
	if sd_detect.returncode != 0:
		echofail("{} 卡侦测".format(sdcard["name"]))
		errorflag += 1
	if sd_detect.stdout.strip() != "00":
		if sd_detect.stdout.strip() == "01":
			echofail("{} 卡读写失败".format(sdcard["name"]))
			errorflag += 1
		elif sd_detect.stdout.strip() == "02":
			echofail("{} 侦测失败".format(sdcard["name"]))
			errorflag += 1
		elif sd_detect.stdout.strip() == "03":
			echofail("{} 挂载失败".format(sdcard["name"]))
			errorflag += 1
		elif sd_detect.stdout.strip() == "04":
			echofail("{} 格式错误，请先将SD卡格式化成EXT2或者EXT3或者ext4格式".format(sdcard["name"]))
			errorflag += 1
		else:
			echofail("{} 测试失败".format(sdcard["name"]))
			errorflag += 1
	time.sleep(2)

	if errorflag != 0:
		Fail_action("SD card detect")
		sys.exit(1)
	else:
		echopass("SD card detect")
		sys.exit(0)
