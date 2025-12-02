#!/usr/bin/env python3
# coding:utf-8
# ------------------------------------------------------------------------
# File Name: fanled.py
# Author: Kingsley
# mail: kingsleywang@msi.com Ext:2573
# Created Time: 06,07,2022
# Script Release Ver: 1.0.0.0
# ------------------------------------------------------------------------
from print_format import echopass, echofail, promptg
import random 
from random import sample, choice
import os, sys
import time

promptg("press any key to continue")
input("press any key to continue")


if len(sys.argv) > 1:
    print("SerialTest")
    exit(1)

promptg("请观察U15_RED_LED点亮的次数")
time.sleep(3)
test_times = random.randint(2,4)
os.system("ipmitool raw 0x28 0x1 0 116 1 1 > /dev/null 2>&1")
os.system("ipmitool raw 0x28 0x1 0 115 1 1 > /dev/null 2>&1")
i =1
while i<= test_times:
    os.system("ipmitool raw 0x28 0x1 0 115 1 0 > /dev/null 2>&1")
    time.sleep(1)
    os.system("ipmitool raw 0x28 0x1 0 115 1 1 > /dev/null 2>&1")
    time.sleep(2)
    i += 1
user_input = int(input("请输入U15_RED_LED点亮的次数并回车: "))
if user_input != test_times:
    echofail("The  U15_RED LED CHECK")
    os.system("ipmitool raw 0x28 0x1 0 115 1 1 > /dev/null 2>&1")
    exit(1)
echopass("The U15_RED LED CHECK")
os.system("ipmitool raw 0x28 0x1 0 115 1 1 > /dev/null 2>&1")
exit(0)

