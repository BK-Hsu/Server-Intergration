#!/usr/bin/env python3
# coding:utf-8
'''
# ------------------------------------------------------------------------
# File Name: fanled.py
# Author: Kingsley
# mail: kingsleywang@msi.com Ext:2250
# Created : 2022-06-07
# Update   : 2023-03-13
# Version  : 1.0.0
# Desription:
# 通过BMC 控制随即点亮Fan LED 来测试
# Change list:
# 2023-03-13: First Release
# ------------------------------------------------------------------------
'''
from print_format import *
import random 
from random import sample, choice
import os, sys
import json


def fanled_init(list):
    for led_location in list:
        os.system("{} {} {} {} > /dev/null 2>&1".format(config['fanled_control'], led_location, config['manual_mode'], config['off_shell']))

def fanled_auto(list):
    for led_location in list:
        os.system("{} {} {} {} > /dev/null 2>&1".format(config['fanled_control'], led_location, config['auto_mode'], config['off_shell']))

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
    total_list = config['location']
    promptg("请观察风扇LED点亮的个数")

    fanled_init(total_list)
    test1_choice = random.choice([2, 3])
    test2_choice = random.choice([1, 2])
    list1 = random.sample(total_list, test1_choice)
    list2 = list(set(total_list) - set(list1))
    for i in random.sample(list1, test2_choice):
        list2.append(i)
    #print(list1, list2)
    array_list = [list1, list2]
    for temp in array_list:
        for location in temp:
            os.system("{} {} {} {} > /dev/null 2>&1".format(config['fanled_control'], location, config['manual_mode'], config['on_shell']))
        user_input = int(input("请输入风扇LED 点亮的个数并回车: "))
        if user_input != len(temp):
             echofail("The fan LED check fail, Input is %s , Actually is %s"%(user_input, len(temp)) )
             fanled_init(total_list)
             Fail_action("风扇LED数量确认错误")
        for location in temp:
            os.system("{} {} {} {} > /dev/null 2>&1".format(config['fanled_control'], location, config['manual_mode'], config['off_shell']))
    fanled_auto(total_list)
    echopass("Fan LED check")
