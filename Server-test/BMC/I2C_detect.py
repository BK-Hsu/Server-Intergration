#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: I2C_detect.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-06-21
# Update   : 2024-06-21
# Version  : 1.0.0
# Description :
# 主要用于针对BMC I2C 不同通道slave 设备进行detect的方式进行测试
# 对应的参数: I2C 的通道(bus 0)，slave address 地址(e0)，slave chipset（U181）,respond 状态（00），
# 对应的信号名称（SMB_TEMPSENSOR_STBY_LVC3_R）
# 还要考虑将FRU,Switch 切换的程式也一起做进来，Switch 芯片的地址，名称(0xa4，U181),切换通道每个通道对应的信号，便于维修查找
# 考虑在测试Fail的时候retry一次，避免因为BMC 动作影响结果导致FAIL
# Change list:
# 2024-06-21: First Release
# -----------------------------------------------------------------------------------
"""
from supports import *
import xml.etree.ElementTree as ET
from subprocess import run, PIPE
import os
import sys

AP_version = "1.0.0"


def config_format():
    """
    <TestCase>
        <ProgramName>I2C_detect</ProgramName>
        <config name="ErrorCode" value="EXF13|I2C device detect fail"/>
        <config name="raw1" value="ipmitool raw 0x38 0x52"/>
        <portlist>
            <port bus="3" slave_addr="9a" slave_chipset="JFP1_sensor" respond="00" i2c_signal="I3C_PCIE_BMC_LVC18" raw_command="raw1" query_args="1 0"/>
            <port bus="4" slave_addr="e0" slave_chipset="U168" respond="00" i2c_signal="SMB_HSBP_STBY_LVC3" raw_command="raw1" query_args="1 0"/>
            <port bus="5" slave_addr="c0" slave_chipset="CPU0 VRM" respond="00" i2c_signal="SMB_PMBUS2_BMC_LVC3" raw_command="raw1" query_args="1 0"/>
            <port bus="8" slave_addr="e0" slave_chipset="U148" respond="00" i2c_signal="SMB_HOST_SCM_SCL_LVC3" raw_command="raw1" query_args="1 0"/>
            <port bus="9" slave_addr="e2" slave_chipset="U142" respond="00" i2c_signal="SMB_PCIE_SCM_SCL_LVC3" raw_command="raw1" query_args="1 0"/>
            <port bus="13" slave_addr="a0" slave_chipset="IPMB" respond="00" i2c_signal="SMB_IPMB_SCM_SCL_LVC3" raw_command="raw1" query_args="1 0"/>
            <port bus="14" slave_addr="e0" slave_chipset="U181" respond="00" i2c_signal="SMB_SMC_FRU_SCL_LVC3" raw_command="raw1" query_args="1 0"/>
            <port bus="14" slave_addr="a4" slave_chipset="UFU1" respond="53 33 36 38 44" i2c_signal="SMB_SMC_FRU_SCL_LVC3" raw_command="raw1" query_args="0x05 0x00 0x2f"/>
            <port bus="15" slave_addr="a0" slave_chipset="U127" respond="53 33 36 38 31" i2c_signal="SMB_CPLD_UPDATE_SCM_SDA_LVC3" raw_command="raw1" query_args="0x05 52"/>
        </portlist>
    </TestCase>
    """
    sys.exit(1)


def fail_action(msg):
    beepremind(1)
    try:
        error_code = config["ErrorCode"]
    except KeyError:
        error_code = "NULL|NULL"
    raise AutoTestFail(error_code, __file__, msg)


def i2c_bus_detect(i2c_bus_info: dict) -> bool:
    """
    通过BMC 切换不同的通道check I2C bus上设备是否有侦测到来检测I2C 线路是否连接正常
    param i2c_bus_info: {'bus': '16', 'slave_addr': 'a0', 'slave_chipset': 'U127', 'respond': '00', 'i2c_signal':
    'SMB_CPLD_UPDATE_SCM_SDA_LVC3', 'raw_command': 'raw1', 'query_args': '1 0'}
    :return:True or False
    """
    raw_format = i2c_bus_info['raw_command']
    _i2c_bus = i2c_bus_info['bus']
    if _i2c_bus.isdigit():
        # _i2c_bus = hex(int(_i2c_bus) * 2 + 1)
        _i2c_bus = hex(int(_i2c_bus))
    else:
        fail_action(f"{_i2c_bus} is not digit")
    i2c_cmd = "{} {} 0x{} {}".format(config[raw_format], _i2c_bus, i2c_bus_info['slave_addr'],
                                     i2c_bus_info['query_args'])
    # print(i2c_cmd)
    retry_times:int = 0
    while retry_times <= 1:
        _i2c_scan_res = run(i2c_cmd, shell=True, stdout=PIPE, encoding='utf-8')
        if _i2c_scan_res.returncode == 0:
            if (res_length := len(i2c_bus_info['respond'])) == 2:
                _res_result = _i2c_scan_res.stdout.split()[1]
            else:
                _res_result = _i2c_scan_res.stdout.strip()[:res_length]
                print(_res_result)
            if _res_result == i2c_bus_info['respond']:
                echopass(f"i2c bus {i2c_bus_info['bus']} signal {i2c_bus_info['i2c_signal']} detect slave chipset"
                         f" {i2c_bus_info['slave_chipset']}")
                return True
            else:
                echofail(f"i2c bus {i2c_bus_info['bus']} signal {i2c_bus_info['i2c_signal']} detect slave chipset"
             f" {i2c_bus_info['slave_chipset']}")
                return False
        else:
            retry_times += 1
            continue
    echofail(f"i2c bus {i2c_bus_info['bus']} signal {i2c_bus_info['i2c_signal']} detect slave chipset"
             f" {i2c_bus_info['slave_chipset']}")
    return False


def get_parameter(xml_path: str) -> tuple[dict, list[dict]]:
    this_case = None
    _config = {}
    _port_list: list[dict] = []
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
    _port_list = [item.attrib for item in this_case.iter(tag='port')]
    return _config, _port_list


def main():
    # os.system("ipmitool raw 0x38 0x41 1 0 >/dev/null 2>&1")
    if all(i2c_bus_detect(i2c_port) for i2c_port in i2c_port_list):
        echopass("i2c detect")
        # os.system("ipmitool raw 0x38 0x41 1 1 >/dev/null 2>&1")
        sys.exit(0)
    else:
        echofail("i2c detect")
        # os.system("ipmitool raw 0x38 0x41 1 1 >/dev/null 2>&1")
        sys.exit(1)


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3351.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, i2c_port_list = get_parameter(xml_config)
    main()
