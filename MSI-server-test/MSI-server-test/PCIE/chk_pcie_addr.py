#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: chk_pcie_addr.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-08-10
# Update   : 2024-08-10
# Version  : 1.0.0
# Desription:
# 通过PCIE 地址树状图来确认PCIE与实际location的对应关系，此程式目前仅用来实现对此关系的check，
# 后续待加入PCIE check 的功能
# Change list:
# 2024-08-10: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import re
from subprocess import run, PIPE
import xml.etree.ElementTree as ET
from supports import *

AP_version = "0.0.1"


def fail_action(msg):
    promptr(msg)
    beepremind(1)
    try:
        error_code = config["ErrorCode"]
    except KeyError:
        error_code = "NULL|NULL"
    raise AutoTestFail(error_code, __file__, msg)


def config_format():
    """
    <TestCase>
        <ProgramName>chk_pcie_addr</ProgramName>
        <config name="ErrorCode" value="TXS1T|PCIe function fail"/>
        <Case index="1">
            <Card>JMCIO5_1|03:00.0|8086:0953|8GT/s|x4|00-01.3</Card>
            <Card>JMCIO5_2|04:00.0|8086:0953|8GT/s|x4|00-01.4</Card>
            <Card>JMCIO6_1|01:00.0|8086:0953|8GT/s|x4|00-01.1</Card>
            <Card>JMCIO6_2|02:00.0|8086:0953|8GT/s|x4|00-01.2</Card>
            <Card>JMCIO7_1|a3:00.0|8086:0953|8GT/s|x4|a0-01.3</Card>
            <Card>JMCIO7_2|a4:00.0|8086:0953|8GT/s|x4|a0-01.4</Card>
            <Card>JMCIO8_1|a1:00.0|8086:0953|8GT/s|x4|a0-01.1</Card>
            <Card>JMCIO8_2|a2:00.0|8086:0953|8GT/s|x4|a0-01.2</Card>
            <Card>JMCIO3_1|c1:00.0|8086:0953|8GT/s|x4|c0-01.1</Card>
            <Card>JMCIO3_2|c2:00.0|8086:0953|8GT/s|x4|c0-01.2</Card>
            <Card>JMCIO4_1|c3:00.0|8086:0953|8GT/s|x4|c0-01.3</Card>
            <Card>JMCIO4_2|c4:00.0|8086:0953|8GT/s|x4|c0-01.4</Card>
            <Card>JMCIO9_1|41:00.0|8086:0953|8GT/s|x4|40-01.1</Card>
            <Card>JMCIO9_2|42:00.0|8086:0953|8GT/s|x4|40-01.2</Card>
            <Card>JMCIO10_1|43:00.0|8086:0953|8GT/s|x4|40-01.3</Card>
            <Card>JMCIO10_2|44:00.0|8086:0953|8GT/s|x4|40-01.4</Card>
            <Card>M2-1|a5:00.0|144d:a808|8GT/s|x2|a0-03.5</Card>
            <Card>M2-2|a6:00.0|144d:a808|8GT/s|x2|a0-03.3</Card>
            <Card>OCP1|21:00.0|8086:1572|8GT/s|x8|20-01.1</Card>
            <Card>OCP1|21:00.1|8086:1572|8GT/s|x8|20-01.1</Card>
            <Card>OCP1|21:00.2|8086:1572|8GT/s|x8|20-01.1</Card>
            <Card>OCP1|21:00.3|8086:1572|8GT/s|x8|20-01.1</Card>
            <Card>JMCIO12|e1:00.0|8086:1592|16GT/s|x16|e0-01.1</Card>
            <Card>JMCIO12|e1:00.1|8086:1592|16GT/s|x16|e0-01.1</Card>   
            <Card>AST2600|a7:00.0|1a03:1150|5GT/s|x1|a0-03.4</Card>
        </Case>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[list]]:
    this_case = None
    _config = {}
    _pcie_list: list = []
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
    for _pcie_case in this_case.iter(tag='Case'):
        if _pcie_case.attrib['index'] == "1":
            for _single_item in _pcie_case:
                _pcie_list.append(_single_item.text.split("|"))
    if len(_pcie_list) == 0:
        fail_action("未找到对应pcie 地址设定信息")
    return _config, _pcie_list


def get_pcie_info() -> dict:
    pcie_dict = {}
    temp_name = None
    _pcie_details = run("lspci -nvt", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    for _line in _pcie_details:
        # 这个是最开始节点
        if (_name := re.search(".*\[(\d\d\d\d:\w\w)\]-\+-(\d\d\.\d)  (\w{4}:\w{4})", _line)) is not None:
            temp_name = _name.groups()[0]
            pcie_dict[temp_name] = []
            pcie_dict[temp_name].append(_name.groups()[1:])
            continue
        elif (_name := re.search("\| {10,13}[+\\\]-(\d\d\.\d)  (\w{4}:\w{4})", _line)) is not None:
            # 将子树的下面节点先不计入统计，后续再考量
            pcie_dict[temp_name].append(_name.groups()[0:])
            continue
            # print(_line)
        # elif (_name := re.search(".*(\d\d\.\d)-\[.*\]----.*(\w{4}:\w{4})", _line)) is not None:
        #     pcie_dict[temp_name].append(_name.groups()[0:])
        # print(_name.groups()[:])
        elif (_name := re.search(".*[\\\+]-(\d\d\.\d)-\[.*\]--[+-]-.*(\w{4}:\w{4})", _line)) is not None:
            pcie_dict[temp_name].append(_name.groups()[0:])
            continue
            # print(_name.groups()[0:])
    # print(pcie_dict)
    return pcie_dict


def check_dev(bus_info: list, item_dict: dict):
    _pcie_bus, _pcie_dev = bus_info[-1].split("-")
    if (_temp_value := f"0000:{_pcie_bus}") in item_dict.keys():
        for _case in item_dict[_temp_value]:
            if _pcie_dev == _case[0]:
                processpass(f"{bus_info[0]} 设备地址0000:{_pcie_bus}-{_pcie_dev}侦测")
                return True
    processfail(f"{bus_info[0]} 设备地址0000:{_pcie_bus}-{_pcie_dev}侦测")
    return False


def main():
    pcie_detect_dict = get_pcie_info()
    # print(pcie_detect_dict)
    _res_list = list(map(lambda _pcie_define: check_dev(_pcie_define, pcie_detect_dict), pcie_addr_list))
    # for _pcie_define in pcie_addr_list:
    #     check_dev(_pcie_define, pcie_detect_dict)
    if all(_res_list):
        echopass("PCIE 设备地址侦测")
        sys.exit(0)
    else:
        fail_action("PCIE 设备地址侦测")
    pass


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, pcie_addr_list = get_parameter(xml_config)
    # print(pcie_addr_list)
    main()
