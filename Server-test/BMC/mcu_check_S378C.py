#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: mcu_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-12-12
# Update   : 2024-12-12
# Version  : 1.0.0
# Description :
# 通过BMC smbus 读取MCU上FW APROM和LDROM version
# Change list:
# 2024-12-12: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import time
from subprocess import run, PIPE
import subprocess
import xml.etree.ElementTree as ET
from supports import *

AP_version = "1.0.0"


def run_shell(cmd: str) -> subprocess.CompletedProcess:
    _res = run(cmd, shell=True, stdout=PIPE, encoding='utf-8')
    return _res


def switch_mux(command: str, step_list: list[dict]) -> bool:
    """
    ipmitool 指令实现MUX 切换到对应的设定通道（不同平台对应的指令可能会有差异，需要在config档案中修改）
    注意config中需要按照顺序填入切换的参数，如果顺序错误，将无法成功，比如应先切主板上mux，然后切小卡上mux
    :param command: ipmitool 控制指令
    :param step_list: 需要切换MUX的步数,已经对应的slave addr 和channel registeer
    :return: 如果成功切换返回True，否则为False
    """
    for step in step_list:
        switch_command = f"{command} 0x{step['mux_addr']} 1 0x{step['mux_channel']} 2>/dev/null"
        # 因为现在BMC 有bug，实际运行功能成功但是返回错误，所以如下运行不检查返回值和stdout
        __switch_res = run(switch_command, shell=True, stdout=PIPE, encoding='utf-8')
        if __switch_res.returncode != 0:
            promptr(f"{switch_command} FAIL")
            return False
        time.sleep(0.5)
    return True


def create_command() -> str:
    """
    根据不同的场景使用不同的ipmitool 指令方式
    :return: 最后返回合适的格式，比如ipmitool i2c bus=4 或者 ipmitool raw 0x38 0x52 0x9
    """
    _command_type = config['command_type']
    _ipmi_command = config[_command_type]
    i2c_bus = config['i2c_bus']
    if _command_type == 'raw_type':
        # _bus_raw = hex(int(i2c_bus) * 2 + 1)
        _bus_raw = hex(int(i2c_bus))
        # ipmitool raw 0x38 0x52 0x9
        _ipmi_command = " ".join([_ipmi_command, _bus_raw])
    else:
        # ipmitool i2c bus=4
        _ipmi_command = ''.join([_ipmi_command, i2c_bus])
    return _ipmi_command


def fail_action(msg):
    beepremind(1)
    run_shell(config['start_scan'])
    try:
        error_code = config["ErrorCode"]
    except KeyError:
        error_code = "NULL|NULL"
    raise AutoTestFail(error_code, __file__, msg)


def config_format():
    """
    <TestCase>
        <ProgramName>mcu_check</ProgramName>
        <config name="ErrorCode" value="EXF13|mcu check fail"/>
        <config name="command_type" value="raw_type"/>
        <config name="raw_type" value="ipmitool raw 0x38 0x52"/>
        <config name="mcu_command" value="0xc2 0x01"/>
        <config name="stop_scan" value="ipmitool raw 0x38 0x41 1 0 2>/dev/null"/>
        <config name="start_scan" value="ipmitool raw 0x38 0x41 1 1 2>/dev/null"/>
        <config name="i2c_bus" value="9"/>
        <!--如果插PCIE_SLOT0 channel=01, SLOT1 channel=40, SLOT2 channel=04-->
        <switch_mcu>
            <step mux_addr="e0" mux_channel="02"/>
            <step mux_addr="e8" mux_channel="01"/>
        </switch_mcu>
        <mcu_config mcu_addr="0xc2">
            <config1 mcu_reg="0x60" reg_name="APROM Major version"  stand_value="ff"/>
            <config1 mcu_reg="0x61" reg_name="APROM Minor version"  stand_value="ff"/>
            <config1 mcu_reg="0x62" reg_name="PDID_1"  stand_value="90"/>
            <config1 mcu_reg="0x63" reg_name="PDID_2"  stand_value="10"/>
            <config1 mcu_reg="0x64" reg_name="PDID_3"  stand_value="05"/>
            <config1 mcu_reg="0x65" reg_name="PDID_4"  stand_value="0c"/>
            <config1 mcu_reg="0x66" reg_name="LDROM Major version"  stand_value="ff"/>
            <config1 mcu_reg="0x67" reg_name="LDROM Minor version"  stand_value="ff"/>
            <config1 mcu_reg="0x68" reg_name="APROM Checksum low byte"  stand_value="e4"/>
            <config1 mcu_reg="0x69" reg_name="APROM Checksum high byte"  stand_value="92"/>
            <config1 mcu_reg="0x6A" reg_name="MCU Temp"  stand_value="10 60"/>
            <config1 mcu_reg="0x6B" reg_name="LDROM Checksum low byte"  stand_value="db"/>
            <config1 mcu_reg="0x6C" reg_name="LDROM Checksum high byte"  stand_value="bd"/>
            <config1 mcu_reg="0x6D" reg_name="System ID"  stand_value="05"/>
            <config1 mcu_reg="0x6E" reg_name="MCU Version"  stand_value="05"/>
            <config1 mcu_reg="0x70" reg_name="Wake_N"  stand_value="03"/>
        </mcu_config>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[dict], list[dict]]:
    this_case = None
    _config = {}
    _config1 = {}
    _switch_mcu: list[dict] = []
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
    for item in this_case.iter(tag='switch_mcu'):
        _switch_mcu = [c.attrib for c in item.iter(tag='step')]
    for __mcu_config in this_case.iter(tag="mcu_config"):
        _config.update(__mcu_config.attrib)
        _config1 = [item.attrib for item in __mcu_config]
    return _config, _config1, _switch_mcu


def mcu_check(command, item_list: list):
    """
    对MCU 不同地址的寄存器来读取check, 检查MCU 的FW和设定是否正常
    :param command: ipmitool 指令
    :param item_list: 有寄存器及对应设定构成的字典列表
    :return: None
    """
    for item in item_list:
        _res = read_register_value(command, config['mcu_addr'], item['mcu_reg'])
        _actual = _res.split()[0]
        if item['mcu_reg'].lower() == "0x6a":
            _actual_temp = int(_actual, 16)
            _temp_lower, _temp_up = item['stand_value'].split()
            if int(_temp_lower) <= _actual_temp <= int(_temp_up):
                echopass(f"MCU {item['reg_name']} Temp: {_actual_temp} degrees")
            else:
                promptr(f"MCU {item['reg_name']} Current Temp: {_actual_temp}, not between {_temp_lower} and {_temp_up} degrees")
                # fail_action(f"MCU FW 检查FAIL, 请确认FW 烧录是否正确!")
        else:
            if _actual == item['stand_value'].strip():
                echopass(f"MCU {item['reg_name']} register {item['mcu_reg']}: {_actual} ")
            else:
                promptr(f"MCU {item['reg_name']} register {item['mcu_reg']} 当前值: {_actual}, 应该是{item['stand_value']}")
                # fail_action(f"MCU FW 检查FAIL, 请确认FW 烧录是否正确!")


def read_register_value(command, smbus_addr, reg: str) -> str:
    _full_command = f"{command} {smbus_addr} 0x01 {reg}"
    retry_time = 0
    while retry_time <= 1:
        _res = run_shell(_full_command)
        if _res.returncode != 0:
            retry_time += 1
            time.sleep(1)
            continue
        else:
            return _res.stdout
    fail_action(f"run command {_full_command} fail")


def main():
    ipmi_command = create_command()
    stop_res = run_shell(config['stop_scan'])
    if stop_res.returncode != 0:
        fail_action("stop scan fail")
    if not switch_mux(ipmi_command, switch_mcu):
        fail_action("切换Switch 通道Fail")
    mcu_check(ipmi_command, config1)
    run_shell(config['start_scan'])


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3361.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, config1, switch_mcu = get_parameter(xml_config)
    main()
    sys.exit(0)
