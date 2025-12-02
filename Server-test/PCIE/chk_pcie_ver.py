#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: chk_pcie_ver.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-12-30
# Update   : 2024-12-30
# Version  : 1.0.0
# Description:
# 主要针对PCIE device 来检查对应的version,只需要知道PCIE的型号
# Change list:
# 2024-12-30: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import re
from subprocess import run, PIPE
import xml.etree.ElementTree as ET
from supports import *

AP_version = "1.0.0"


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
        <ProgramName>chk_pcie_ver</ProgramName>
        <config name="ErrorCode" value="TXS1T|PCIe function fail"/>
        <device>JMCIO5_1|8086:0953|02</device>
        <device>JMCIO5_1|8086:0953|02</device>
        <device>JMCIO5_1|8086:0953|02</device>
        <device>JMCIO5_1|8086:0953|02</device>
        <device>JMCIO5_1|8086:0953|02</device>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list]:
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
    _pcie_ver_list: list = []
    for _pcie_ver in this_case.iter(tag='device'):
        _pcie_info = _pcie_ver.text.split("|")
        _pcie_ver_list.append(_pcie_info)
    return _config, _pcie_ver_list


def get_pcie_info() -> dict:
    pcie_ver_dict = {}
    _pcie_details = run("lspci -n", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    # e0:0f.07 前面是bus number，占用8位最高ff，0f为device number，占用5位，最高1f，最后为functon number，占用3位，最高为07
    for _line in _pcie_details:
        # 00:14.2 0500: 8086:9def (rev 30)
        if (_name := re.search(".*([0-9a-fA-F]{4}:[0-9a-fA-F]{4})\s\(rev (\w\w)\)", _line)) is not None:
            # 以vendor_id和ver来进行管控，同一种vendor_id 应该只有一种version
            _vendor_id, _ver = _name.groups()
            if _vendor_id in pcie_ver_dict.keys() and pcie_ver_dict[_vendor_id] == _ver:
                continue
            elif _vendor_id in pcie_ver_dict.keys() and pcie_ver_dict[_vendor_id] != _ver:
                fail_action(f"{_vendor_id} 设备对应的version 不统一,请输入lspci -n |grep {_vendor_id}查看")
            elif _vendor_id not in pcie_ver_dict.keys():
                pcie_ver_dict[_vendor_id] = _ver
                continue
            else:
                fail_action("meet unknown issue")
    return pcie_ver_dict


def check_pcie(pcie_define: list, detect_dict: dict):
    _pcie_location, _pcie_vendor, _pcie_ver = pcie_define
    if _pcie_vendor in detect_dict.keys():
        if _pcie_ver.strip() == detect_dict[_pcie_vendor]:
            print("%-17s%-12s%-10s\033[1;32m%-10s\033[0m" % (_pcie_location, _pcie_vendor, _pcie_ver, detect_dict[_pcie_vendor]))
            return True
        else:
            print("%-17s%-12s%-10s\033[1;31m%-10s\033[0m" % (_pcie_location, _pcie_vendor, _pcie_ver, detect_dict[_pcie_vendor]))
            return False
    else:
        print("%-17s\033[1;31m%-12s\033[0m%-10s%-10s" % (_pcie_location, "NULL",  "NULL", 'NULL'))
        return False


def check_pcie_config(pcie_list: list) -> bool:
    """
    检查PCIE 的设置是否正常，是否重复，针对多种配置档案应该都可以支持，配置档案设置是否合理
    目前此程式主要针对是地址配置的PCIE 进行检查，针对指卡数量，但是不卡地址的方式还不能cover
    :return:比对正常返回True，否则raise Exception
    """
    _vendor_list = [item[1] for item in pcie_list]
    if len(set(_vendor_list)) != len(pcie_list):
        fail_action("配置档案中有重复,请检查！")
    _err_flag: int = 0
    for _index, _pcie_vendor in enumerate(_vendor_list):
        if len(_pcie_vendor.strip()) == 0:
            processfail(f"{pcie_list[_index][0]} 配置PCIE vendor不能为空，请检查设定！")
            _err_flag += 1
    if _err_flag != 0:
        fail_action("PCIE version配置档案设置错误")
    return True


def main():
    pcie_detect_list = get_pcie_info()
    check_pcie_config(pcie_ver_list)
    print("%-17s%-12s%-10s%-10s" %
          ("Location", "VendorID", "Std_ver", "Act_ver"))
    print("----------------------------------------------------------------------")
    _case_error_flag = 0
    for _pcie_ver_info in pcie_ver_list:
        if not check_pcie(_pcie_ver_info, pcie_detect_list):
            _case_error_flag += 1
    print("----------------------------------------------------------------------")
    if _case_error_flag == 0:
        echopass("device version check")
    else:
        fail_action("device version check FAIL")


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, pcie_ver_list = get_parameter(xml_config)
    main()
    # print(cpu_pcie_list)
