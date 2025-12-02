#!/usr/bin/env python3
# coding:utf-8

'''
# ------------------------------------------------------------------------
# File Name: Netleds.py
# Author: Kingsley
# mail: kingsleywang@msi.com Ext:2250
# Created : 2022-06-07
# Update   : 2023-03-13
# Version  : 1.0.0
# Desription:
# 通过ethtool 来控制LED随即点亮，并确认LED 灯点亮的数量
# Change list:
# 2023-03-13: First Release
# ------------------------------------------------------------------------
'''
import time
from random import choice
from subprocess import run, PIPE
import sys
import xml.etree.ElementTree as ET
import os
from print_format import *


#scriptdir = os.path.split(os.path.realpath(__file__))[0]
#configpath = os.path.join(scriptdir, 'new_config.xml')
configpath = "/TestAP/Config/MS-S3121.xml"
config = {}
speed_color = []

class Lanled:
    speed_list = speed_color
    test_tool = None
    def __init__(self, mac_file):
        self.dual = True
        self.mac_file = mac_file
        self.eth_id = None
        #self.default_speed = None

    @property
    def mac(self):
        if not os.path.exists(self.mac_file):
            Fail_action("mac file %s not exist" % self.mac_file)
        with open(self.mac_file, 'r', encoding='utf-8') as f:
            __mac = f.read().strip()
        return __mac

    @property
    def Eth_id(self):
        tempmac = self.mac[0:2] + ":" + self.mac[2:4] + ":" + self.mac[4:6] + ":" + self.mac[6:8] + ":" + self.mac[8:10] + ":" + self.mac[10:12]
        cmd = ''' ifconfig -a 2>/dev/null | grep -v "inet" | 
        grep -iPB3 "{}" | grep -iE "^e[nt]" | awk '{{print $1}}' | tr -d ':' '''.format(tempmac)
        __eth_id = run(cmd, shell=True, stdout=PIPE, encoding='utf-8', check=True).stdout.strip()
        #__default_speed = run("ethtool %s |grep -iw 'Speed'" % __eth_id, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
        #self.default_speed = __default_speed.split(":")[1].strip()[:-4]
        return __eth_id

    def led_control(self, speed_config):
        if self.test_tool == "ethtool":
            speed = speed_config['speed']
            Amber_sum = int(speed_config['Amber'])
            Green_sum = int(speed_config['Green'])
            cmd = "ethtool -s {} duplex full autoneg on speed {} >/dev/null 2>&1".format(self.Eth_id, speed)
            result = run(cmd, shell=True, encoding='utf-8', check=True)
            if result.returncode != 0:
                Fail_action("LAN led command not work")
            if self.dual is True:
                ans_value = {"Green": Green_sum * 2, "Amber": Amber_sum * 2}
            else:
                ans_value = {"Green": Green_sum, "Amber": Amber_sum}
            return ans_value

    def led_count(self):
        speed_config = choice(self.speed_list)
        num_dict = self.led_control(speed_config)
        self.speed_list.remove(speed_config)
        return num_dict

    def led_init(self): 
        cmd = "ethtool -s {} duplex full autoneg on speed 1000 >/dev/null 2>&1".format(self.Eth_id)
        result = run(cmd, shell=True, encoding='utf-8', check=True)
        if result.returncode != 0:
            print("LAN led command not work")
            Fail_action("网口初始化失败")
        
def parse_platform_xml():
    global config, speed_color
    tree = ET.ElementTree(file=configpath)
    root = tree.getroot()
    for globalcfg in root.iter(tag='NetLED'):
        for c in globalcfg.iter(tag='config'):
            if list(c.attrib.keys())[0].strip() == "speed":
                speed_color.append(c.attrib)
            else:
                name = c.attrib['name']
                value = c.attrib['value']
                config[name] = value
                if c.text:
                    config[name] = c.text.strip()

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
    macaddress_list = []
    ledtest_list = []
    parse_platform_xml()
    Lanled.test_tool = config['test_tool_1G']
    for item in config['control_1G_led'].split():
        macaddress_list.append(config['%s' % item])
    for i in range(len(macaddress_list)):
        locals()[f'led{i}'] = Lanled(macaddress_list[i])
        ledtest_list.append(locals()[f'led{i}'])
    ledtest_time = len(speed_color)
    # 如下指令可以打印出来运行脚本的名字
    #print(os.path.basename(__file__))
    # 如下指令可以打印出来脚本的绝对路径名字
    # print(sys.argv[0])

    while True:
        num_G = 0
        num_B = 0
        alwayslightamber_sum = int(config['uncontrol_Amber'])
        alwayslightgreen_sum = int(config['uncontrol_Green'])
        prompt_led = config['led_location'].split()
        for led in ledtest_list:
            num_dict = led.led_count()
            num_G += num_dict["Green"]
            num_B += num_dict["Amber"]
        num_G += alwayslightgreen_sum
        num_B += alwayslightamber_sum
        prompty("请观察 %s LED 的颜色，并输入对应颜色LED灯的数量" % prompt_led[:])
        time.sleep(3)
        user_input1 = int(input("\033[1;33m请输入所亮 橙色灯的数量 : \033[0m"))
        if num_B != user_input1:
            promptr("橙色灯的数量错误，请确认")
            Fail_action("LAN LED test fail")
        user_input2 = int(input("\033[1;33m请输入所亮 绿色灯的数量 : \033[0m"))
        if num_G != user_input2:
            promptr("绿色灯的数量错误，请确认")
            Fail_action("LAN LED test fail")
        ledtest_time -= 1
        if ledtest_time == 0:
            break
    for led in ledtest_list:
        led.led_init()
    echopass("LAN led颜色检查正确")
    sys.exit(0)




