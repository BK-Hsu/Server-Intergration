#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: CPLD_ver_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-06-19
# Update   : 2024-12-18
# Version  : 1.0.1
# Desription:
# 读取SCM 及主板 CPLD FW version，并进行比对
# Change list:
# 2024-06-19: First Release
# 2024-12-18: 增加power board CPLD 比对，如果读出来CPLD 数量为2,则判断是否在对应位置的功能
# 2024-12-18: 其他位置时都需要测试3个CPLD version.
# -----------------------------------------------------------------------------------
"""
import os
import sys
from subprocess import run, PIPE
import xml.etree.ElementTree as ET
from supports import *

AP_version = "1.0.1"


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
        <ProgramName>CPLD_ver_check</ProgramName>
        <config name="ErrorCode" value="TXC83|CPLD version check fail"/>
        <config name="CPLD_ver_cmd" value="ipmitool raw 0x32 0xd6 0"/>
        <config name="scm_ver" value="16 00 8d 36"/>
        <config name="hpm_ver" value="13 00 01 38"/>
        <config name="pwr_ver" value="0e 00 0a 38"/>
    </TestCase>
    """
    sys.exit(1)


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


def get_Node_ID():
    __res = run("ipmitool raw 0x28 0xa2 0x21 2>/dev/null", shell=True, stdout=PIPE, encoding='utf-8')
    if __res.returncode == 0:
        return __res.stdout.strip()
    return None


def cpld_ver_check() -> bool:
    _error_flag: int = 0
    command = config['CPLD_ver_cmd']
    _res = run(command, shell=True, stdout=PIPE, encoding='utf-8')
    if _res.returncode != 0:
        fail_action(f"ipmi raw 命令{command} 运行FAIL")
    _ver_res = _res.stdout.strip()
    _cpld_config = {'scm_ver': 183, 'hpm_ver': 376, 'pwr_ver': 569}
    # CPLD version读取格式为13 00 01 38，长度为11
    _string_length = 11
    if (_cpld_sum := _ver_res[0:2].strip()) == "02":
        _Node_ID = get_Node_ID()
        if _Node_ID is None:
            fail_action("未读取到Node信息,手动输入 ipmitool raw 0x38 0xa2 0x21 2>/dev/null 可以查看具体信息")
        if _Node_ID == "00":
            fail_action("Node 连接在S308A 右下方位置,应该读取到3个CPLD version,但是实际只读取到2个,请检查！")
        check_list = ['hpm_ver', 'scm_ver']
    elif _cpld_sum == "03":
        check_list = ['hpm_ver', 'scm_ver', 'pwr_ver']
    else:
        fail_action(f"实际CPLD version读取到{int(_cpld_sum)},应该读取到2或者3个CPLD version,请检查！")
    for __cpld_type in check_list:
        __cpld_ver_reading = _ver_res[_cpld_config[__cpld_type] : _cpld_config[__cpld_type] + _string_length]
        if __cpld_ver_reading == config[__cpld_type]:
            processpass(f"{__cpld_type} version: {__cpld_ver_reading}")
        else:
            promptr(f"{__cpld_type} version: {__cpld_ver_reading}, 正确版本为： {config[__cpld_type]}")
            _error_flag += 1
    if _error_flag == 0:
        echopass("CPLD version check")
        # 启用sensor
        # os.system("ipmitool raw 0x38 0x41 1 1 >/dev/null 2>&1")
        sys.exit(0)
    else:
        fail_action("CPLD version check")


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config = get_parameter(xml_config)
    cpld_ver_check()
