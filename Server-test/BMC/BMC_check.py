#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: BMC_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2023-10-26
# Update   : 2024-02-07
# Version  : 1.1.1
# Desription:
# 通过USB com 登陆 BMC console端口，check BMC MLAN 口连接速度， BMC 可用内存，虚拟键鼠
# 虚拟网络，i2c device scan, 读取i2c slave 设备温度或者资料
# Change list:
# 2023-10-26: First Release
# 2024-02-07: 1.1.0 更新I2C scan逻辑，增加retry 机制，模板格式调整
# 2024-03-14: 1.1.1 add console flush before each item and get config in main process
# ------------------------------------------------------------------------------------
"""

AP_version = "1.1.1"

from serialport import SerialPort
from subprocess import run, PIPE
from supports import *
import time
import os
import re
import random
import sys
import json
import argparse


def check_mlan():
    """
    通过COM console login BMC debug port，读取Mlan 端口的网络连接speed
    """
    ser_port.clear_buffer()
    ser_port.write_string("ethtool eth0\r")
    time.sleep(0.5)
    result = ser_port.read_string()
    #print(result)
    if "Speed: 1000Mb/s" in result and "Duplex: Full" in result:
        print("MLAN1 link speed is 1000Mb/s")
    else:
        raise Exception("MLAN1 联网速度未达到1000M ，请确认")


def check_ncsi():
    """
    通过COM console login BMC debug port，读取Mlan 端口的网络连接speed
    """
    ser_port.clear_buffer()
    ser_port.write_string("ethtool eth1\r")
    time.sleep(0.5)
    result = ser_port.read_string()
    #print(result)
    if "Speed: 1000Mb/s" in result and "Duplex: Full" in result:
        echopass("NCSI link speed 1000Mb/s")
    else:
        raise Exception("NCSI 联网速度未达到1000M ，请确认")



def bmc_login():
    """
    login BMC debug console port
    通过主板JDBG_BMC 插针，其中DB9 第5pin接JDBG 第1pin(地)，第3pin接JDBG第2pin，第2pin接JDBG第3pin
    """
    # 输入ctrl + c
    ser_port.write_string("\03")
    #time.sleep(0.5)
    ser_port.clear_buffer()
    ser_port.write_string("\r")
    # print(ser_port.read_string())
    ser_data = ser_port.read_string()
    print(ser_data)
    if "login:" in ser_data:
        ser_port.write_string("sysadmin\r")
        t1 = 0
        while t1 <= 6:
            if "Password:" in ser_port.read_string():
                ser_port.write_string("superuser\r")
                t2 = 0
                while t2 < 5:
                    #print(ser_port.read_string())
                    if " #" in ser_port.read_string():
                        break
                    time.sleep(1)
                    t2 += 1
                if t2 >= 5:
                    raise Exception("login bmc console Fail after password input")
                else:
                    break
            time.sleep(1)
            t1 += 1
        if t1 > 6:
            echofail("login BMC fail after user input")
            raise Exception("login BMC fail after user input")
    elif " #" in ser_data:
        return 0
    else:
        raise Exception("login1 bmc console Fail")


def check_bmc_memory(bmc_memsize):
    """
    check BMC memory size， speed ， model info
    Now only check memory size
    """
    checkflag = 0
    ser_port.clear_buffer()
    ser_port.write_string("free -m\r")
    data = ser_port.read_string()
    for line in data.split("\n"):
        if "Mem:" in line:
            mem_size = int(line.split()[1])
            if mem_size != int(bmc_memsize):
                raise Exception("bmc memory size check fail")
            checkflag += 1
    if checkflag != 1:
        raise Exception("command fail")
    else:
        print("BMC memory size %sMB check PASS" % mem_size)


def control_mlan_led(speed):
    """
    control MLAN LED via bmc debug console port
    此部分需要考量是否跟LAN LED一起进行测试
    """
    cmd = "ethtool -s eth0 duplex full autoneg on speed {} >/dev/null 2>&1".format(speed)
    ser_port.write_string(cmd + "\r")
    if speed == "1000":
        ans_value = 3
    elif speed == "100":
        ans_value = 2
    elif speed == "10":
        ans_value = 1
    return ans_value


def mlan_init():
    cmd = "ethtool -s eth0 duplex full autoneg on speed 1000 >/dev/null 2>&1"
    ser_port.write_string(cmd + "\r")
    return 0


def Mlan_led():
    speed_list = ["100", "1000"]
    while len(speed_list) > 0:
        speed = random.choice(speed_list)
        stand_ans = control_mlan_led(speed)
        user_ans = input("\033[1;33mMlan 左边LED 亮绿色，右边LED 不亮， 请输入 数字1 并回车 \n"
                         "Mlan 左边LED 亮绿色，右边LED 亮橙色，请输入 数字2 并回车 \n"
                         "Mlan 左边LED 亮绿色，右边LED 亮绿色，请输入 数字3 并回车 \n"
                         "请输入对应的数值： \033[0m")
        if int(user_ans) != stand_ans:
            mlan_init()
            raise Exception("Mlan LED check FAIL")
        else:
            speed_list.remove(speed)
    mlan_init()


def bmc_virtual_usb():
    """
    check BMC 虚拟键鼠
    """
    # 检查虚拟键鼠
    virtual_usb_list = []
    ser_port.write_string("ls -l /sys/bus/usb/devices/ \r")
    ser_data = ser_port.read_string()
    for line in ser_data.split():
        if "1e6a3000.usb/usb1/1-0" in line:
            print(line)
            virtual_usb_list.append(line)
            continue
        elif "1e6b0000.usb/usb2/2-0" in line:
            print(line)
            virtual_usb_list.append(line)
            continue
    if len(virtual_usb_list) != 2:
        # for item in virtual_usb_list:
        #    print(item)
        print("虚拟键鼠设备应包括： 1e6a3000.usb/usb1/1-0，1e6b0000.usb/usb2/2-0， 请确认")
        raise Exception("虚拟键鼠设备确认Fail")


def bmc_virtual_network():
    """
    check BMC 虚拟网络设备，并check 虚拟网络设备是否已经link up
    """
    # 检查虚拟网口
    ser_port.clear_buffer()
    ser_port.write_string("ethtool usb0\r")
    link_data = ser_port.read_string()
    if "Link detected: yes" in link_data:
        print("虚拟网络USB0 连接正常")
    else:
        raise Exception("虚拟网络USB0 侦测异常")


def i2c_slave_check(slave_config):
    errflag = 0
    
    for item in slave_config:
        stand_list = item['slave_list']
        avl_list = item['slave_avl']
        retry_times = 0
        while retry_times < 2:
            ser_port.clear_buffer()
            ser_port.write_string("i2cdetect -al -y {}\r".format(item['i2c_port']))
            #if int(item['i2c_port']) == 3:
            #    time.sleep(1)
            #time.sleep(0.3)
            result = ser_port.read_string()
            if "Error" in result:
                retry_times += 1
                continue
                # raise Exception("scan slave i2c FAIL")
            result1 = result.split('\r\n')[2:-1]
            # start_index = result1.index('Slave list:')
            # detect_list = result1[start_index+1 : -1]
            detect_list = []
            for line in result1:
                temp_list = [x for x in line.split()[1:] if x != "--" and x != "00"]
                detect_list += temp_list
            # print("BMC I2C bus ", item['i2c_port'], detect_list)
            diff_list = list(set(stand_list) - set(detect_list))
            if len(diff_list) != 0:
                if len(avl_list) != 0:
                    if len(list(set(avl_list) - set(detect_list))) != 0:
                        processfail("BMC I2C bus {} not detect below address: {}".format(item['i2c_port'], diff_list))
                        retry_times += 1
                        continue
                    else:
                        processpass("BMC I2C bus {} detect {}".format(item['i2c_port'], detect_list))
                        break
                else:
                    processfail("BMC I2C bus {} not detect below address: {}".format(item['i2c_port'], diff_list))
                    retry_times += 1
                    continue
                # errflag += 1
            else:
                processpass("BMC I2C bus {} detect {}".format(item['i2c_port'], detect_list))
                break
        if retry_times >= 2:
            errflag += 1
            # if set(detect_list) != set(stand_list):
            #    errflag += 1
    if errflag == 0:
        echopass('SCAN I2C Slave device')
    else:
        raise Exception("scan slave i2c FAIL")


def ocp_hwm():
    ser_port.write_string("i2cget -f -y 8 0x48 0x00\r")
    ocp_temp = ser_port.read_string().split("\r\n")[1].strip()
    if "Error" in ocp_temp:
        raise Exception("Can't read OCP hwm ,please check S258E plugged")
    ocp_temp = eval(ocp_temp)
    # print(eval(ocp_temp))
    if 20 < ocp_temp < 50:
        print("Get OCP 温度：%s" % ocp_temp)
    else:
        raise Exception("OCP 温度 is not in range 20~50 degree")


def s322g_hwm():
    ser_port.write_string("i2cget -f -y 8 0x4f 0x00\r")
    s322g_temp = ser_port.read_string().split("\r\n")[1].strip()
    if "Error" in s322g_temp:
        print("please check S322G plugged, also check JM2_CLK1 JM2_DAT1 Jumper 2-3")
        raise Exception("Can't read S322G hwm")
    s322g_temp = eval(s322g_temp)
    # print(eval(ocp_temp))
    if 20 < s322g_temp < 50:
        print("Get S322G 温度：%s" % s322g_temp)
    else:
        raise Exception("OCP 温度 is %s ,not in range 20~50 degree" % s322g_temp)

def s101b_smbus():
    s101b_addr_list =[{"addr":"10", "location" :"PCI_E5"}, {"addr":"01", "location" :"PCI_E1"}]
    for smbus_addr in s101b_addr_list:
        os.system("ipmitool raw 0x06 0x52 0x01 0xe4 0x00 0x{} 2>&1 >/dev/null".format(smbus_addr['addr']))
        time.sleep(0.5)
        ser_port.write_string("i2c-test -b 0 --scan\r")
        time.sleep(0.5)
        detect_result = ser_port.read_string()
        temp = detect_result.split('\r\n')
        #print(temp.index('Slave list:'))
        #detect_temp = temp[temp.index('Slave list:')+1 : -1]
        #print(detect_temp)
        #test_list = ["0x0a", "0x44"]
        #print(list(set(test_list) - set(detect_temp)))
        #print(list(set(detect_temp) - set(test_list)))
        if "0x0a" in detect_result:
            print("{} smbus detect PASS".format(smbus_addr['location']))
        else:
            os.system("ipmitool raw 0x06 0x52 0x01 0xe4 0x00 0x00 2>&1 >/dev/null")
            raise Exception("{} smbus detect FAIL".format(smbus_addr['location']))
    os.system("ipmitool raw 0x06 0x52 0x01 0xe4 0x00 0x00 2>&1 >/dev/null")


def s322g_fru():
    read_list = ["00", "01", "02", "03", "04"]
    fru_info = ''
    stand_fru = "53 33 32 32 47"
    for address in read_list:
        ser_port.write_string("i2cget -f -y 8 0x57 0x{}\r".format(address))
        fru_temp = ser_port.read_string().split("\r\n")[1].strip()
        if "Error" in fru_temp:
            raise Exception("Can't read S322G fru")
        fru_info = fru_info + " " + (fru_temp.split("0x")[-1])
    # print(eval(ocp_temp))
    if fru_info.strip() == stand_fru:
        print("Get S322G fru: %s PASS" % fru_info)
    else:
        raise Exception("Get S322G FRU: %s ,should be %s" % (fru_info, stand_fru))

def sd_check():
    ser_port.write_string("mount /dev/mmcblk0p1 /mnt\r")
    time.sleep(0.5)
    ser_port.write_string("df -h\r")
    time.sleep(1)
    mount_info = ser_port.read_string().split("\r\n")[-2]
    #print(mount_info)
    if "mmcblk0p1" not in mount_info:
        ser_port.write_string("umount /mnt\r")
        raise Exception("SD mount fail, please check SD card")
    ser_port.write_string("cd /mnt\r")
    ser_port.write_string("rm test1 2>&1 >/dev/null\r")
    ser_port.write_string("echo 1234 > test1\r")
    ser_port.write_string("cat test1\r")
    read_value = ser_port.read_string()
    if "1234" not in read_value:
        ser_port.write_string("umount /mnt\r")
        raise Exception("SD read/Write test Fail")
    ser_port.write_string("umount /mnt\r")
    ser_port.write_string("cd\r")
    #time.sleep(0.5)
    ser_port.read_string()
    echopass("SD card Test")

def usb_console_name() -> str:
    # 侦测本身的console ttyS0， 同时侦测USB转com 的ttyUSB0，需要注意ttyUSB 需要抓取最后一次识别到的信息，避免中途被移除导致测试Fail
    # <Port>COM1|/dev/ttyS0|0x3F8</Port>
    _temp_list = []
    _usb_com_list = ['pl2303', 'FTDI', 'cp210x']
    pattern_str = "|".join(_usb_com_list)
    query_shell = 'dmesg | grep -i "ttyUSB"'
    query_res = run(query_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    for line in query_res:
        if re.search(pattern_str, line) is not None and "attached" in line:
            _temp_list.append(line)
        if re.search(pattern_str, line) is not None and "disconnected" in line:
            _temp_list = []
    if len(_temp_list) != 2:
        print(query_res)
        Fail_action("usb_com not detect,please check cable or board")
    usb_com_name = re.match(f".*?: [{pattern_str}].*(ttyUSB\d+)$", _temp_list[1]).groups()[0]
    usb_com_name = "/dev/%s" % usb_com_name
    return usb_com_name



def ID_LED(status: str):
    prompty("请在15S 内按ID_BTN...")
    if status == "on":
        _respond = "1"
        _stand_ans = "y"
    else:
        _respond = "0"
        _stand_ans = "n"
    time_stamp1 = 15
    while time_stamp1 > 0:
        _temp_res = ser_port.read_string()
        if f"Get process_id_button_handle [{_respond}]" in _temp_res:
            # echopass("ID_BTN press test")
            break
        else:
            time.sleep(1)
            time_stamp1 -= 1
            continue
    if time_stamp1 == 0:
        Fail_action("ID_BTN 按键超时，或者按过之后无反应，请确认")
    user_ans = input("\033[1;33m请确认ID LED是否点亮且颜色为蓝色，如果正确，请输入y|Y，否则输入n|N，并回车： \033[0m")
    if user_ans.lower() == _stand_ans:
        echopass(f"ID LED {status} 确认")
    else:
        Fail_action(f"ID LED {status} 确认") 

def ID_BTN():
    prompty("请观察ID LED，如果此时ID LED为点亮状态，请先按下ID_BTN,然后开始测试，避免影响测试结果判断")
    time.sleep(1)
    ser_port.clear_buffer()
    _status_list: list = ["on", "off"]
    for _stauts in _status_list:
        ID_LED(_stauts)

def emmc_info_check():
    ser_port.clear_buffer()
    ser_port.write_string("parted /dev/mmcblk0 print\r")
    #emmc_info_cmd = "parted /dev/mmcblk0 print"
    _item_flag:int  = 0
    _query_res = ser_port.read_string().split("\r\n")
    for line in _query_res:
        if (actual_model := re.search(f"Model: {config['emmc_model']}", line)) is not None:
            processpass(f"{line}")
            _item_flag += 1
        elif (actual_size := re.match(f"Disk /dev/mmcblk0: (\d+)MB", line)) is not None:
            if int(_size := actual_size.groups()[0]) >= config['emmc_size']:
                processpass(f"emmc size is {_size}")
                _item_flag += 1
            else:
                Fail_action(f"emmc size is {_size}, 低于spec 定义{config['emmc_size']}")       
    if _item_flag != 2:
        Fail_action(f"emmc {config['emmc_model']} info check fail, please check")

    
def Fail_action(msg):
    beepremind(1)
    try:
        ErrorCode = config["ErrorCode"]
    except KeyError:
        ErrorCode ="NULL|NULL"
    raise AutoTestFail(ErrorCode, __file__,msg)

if __name__ == '__main__':
    # 显示使用方法
    xml_config = parser_argv(AP_version)
    #if os.path.exists(xml_config):
    #    print(xml_config)
    # 定义文件basename和路径，并在文件所在路径下运行脚本
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__)
    #print(WorkPath)
    os.chdir(WorkPath)
    with open('bmc.json', 'r') as json_file:
        config = json.load(json_file)
    slave_config = config['i2c_list']
    bmc_memsize = config['memsize']
    console_name = usb_console_name()
    ser_port = SerialPort()
    # set com port
    ser_port.PortName = console_name
    # set baudrate
    ser_port.Baudrate = 115200
    # set read timeout
    ser_port.Timeout = 0.5
    ser_port.open()
    bmc_login()
    # i2c_slave_check(slave_config)
    check_mlan()
    # check_bmc_memory(bmc_memsize)
    # ID_BTN()
    # bmc_virtual_usb()
    bmc_virtual_network()
    emmc_info_check()
    # Mlan_led()
    exit(0)
