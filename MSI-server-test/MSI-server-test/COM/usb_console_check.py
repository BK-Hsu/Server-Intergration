#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: usb_console_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-06-18
# Update   : 2024-06-18
# Version  : 1.0.0
# Desription:
# 主要用于DC SCM2 USB侦测及USB console 功能测试
# USB 功能port 为down，USB console 为upper port，2个功能测试区分开进行测试，以便后续进行调整
# Change list:
# 2024-06-18: First Release
# -----------------------------------------------------------------------------------
"""
import time
from supports import *
import re
import sys
import string
import os
import xml.etree.ElementTree as ET
from serialport import SerialPort
from subprocess import run, PIPE
AP_version = "1.0.0"


def usb_console_verify() -> list:
    # 侦测本身的console ttyS0， 同时侦测USB转com 的ttyUSB0，需要注意ttyUSB 需要抓取最后一次识别到的信息，避免中途被移除导致测试Fail
    # <Port>COM1|/dev/ttyS0|0x3F8</Port>
    _temp_list = []
    _com_list: list[str] = []
    query_shell = 'dmesg | grep -i "tty"'
    query_res = run(query_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    for line in query_res:
        if config['DevName'].split("/")[-1] in line and config['DevName'] not in _com_list:
            _com_list.append(config['DevName'])
        if (com_chipset := config['ComChipset']) in line and "attached" in line:
            _temp_list.append(line)
        if com_chipset in line and "disconnected" in line:
            _temp_list = []
    if len(_temp_list) != 2:
        print(query_res)
        fail_action("usb_com not detect,please check cable or board")
    usb_com_name = re.match(".*?: +cp210x.*(ttyUSB\d+)$", _temp_list[0]).groups()[0]
    usb_com_name = "/dev/%s" % usb_com_name
    _com_list.append(usb_com_name)
    return _com_list


def fail_action(msg):
    beepremind(1)
    try:
        error_code = config["ErrorCode"]
    except KeyError:
        error_code = "NULL|NULL"
    raise AutoTestFail(error_code, __file__, msg)


def get_parameter(xml_path: str) -> dict:
    this_case = None
    _config = {}
    if xml_path is None:
        fail_action(f"xml config not found")
    else:
        if not os.path.exists(xml_path):
            fail_action(f"xml config {xml_path} not exist")
    tree = ET.ElementTree(file=xml_path)
    root = tree.getroot()
    for program in root.iter(tag='TestCase'):
        for c in program.iter(tag="ProgramName"):
            if c.text == BaseName:
                this_case = program
    if this_case is None:
        fail_action("未找到对应xml 配置")
    for item in this_case.iter(tag='config'):
        name = item.attrib['name']
        _config[name] = item.attrib['value']
    return _config


def usb_console_test(port_list: list, **kwargs) -> bool:
    """
    由ttyS0 向 ttyUSB0传输数据，并反向传输一次,两次均PASS 为OK
    :return: None
    """
    console_list = []
    for port_name in port_list:
        serial_port = SerialPort()
        serial_port.PortName = port_name
        serial_port.Baudrate = kwargs['bandrate']
        serial_port.Timeout = kwargs['timeout']
        serial_port.open()
        console_list.append(serial_port)
    reverse_list = console_list[::-1]
    #for item in console_list:
    #    print(item.Baudrate)
    if rx_tx_test(console_list):
        if rx_tx_test(reverse_list):
            echopass(f"Com baudrate {kwargs['bandrate']} 测试")
            for item in console_list:
                item.close()
            return True
    echofail(f"Com baudrate {kwargs['bandrate']} 测试")
    return False
    #sys.exit(1)


def rx_tx_test(list1: list[SerialPort]) -> bool:
    """
    控制列表中的2个port ，一个负责传输数据，另外一个接收并检查数据是否正确
    :param list1: 建立的SerialPort的实例对象
    :return: True or False
    """

    _string: str = "1234567890." + string.ascii_lowercase + string.ascii_uppercase
    for console_case in list1:
        console_case.clear_buffer()
    list1[0].write_string(f"{_string}\r")
    i:int  = 0
    while i < 3:
        rx_read = list1[1].read_string().strip()
        # print(rx_read)
        if rx_read == _string:
            return True
        else:
            time.sleep(1)
            i += 1
            print(i)
    return False


def main():
    com_list = usb_console_verify()
    setting_list = [{'bandrate':115200,'timeout':0.5}, {'bandrate':9600,'timeout':0.5}]
    for com_setting in setting_list:
        transfer_res = usb_console_test(com_list, **com_setting)
        if not transfer_res:
            sys.exit(1)
    sys.exit(0)


def config_format():
    """
    <TestCase>
        <ProgramName>usb_console_check</ProgramName>
        <config name="ErrorCode" value="TXC11|COM function fail"/>
        <config name="ComName" value="COM1"/>
        <config name="DevName" value="/dev/ttyS0"/>
        <config name="ComBase" value="0x3F8"/>
        <config name="ComChipset" value="cp210x"/>
    </TestCase>
    """
    pass


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    #xml_config = "MS-S3351.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config = get_parameter(xml_config)
    main()
