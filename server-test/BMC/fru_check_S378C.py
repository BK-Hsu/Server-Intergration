#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: backplane_smbus_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-07-02
# Update   : 2024-07-02
# Version  : 1.0.0
# Description :
# 通过BMC smbus 读取Backplane上温度，FRU, NVME SSD FW, Current
# 目前ipmitool raw 写入指令存在bug，会报错，但是实际已经执行成功，待后续bug fix 后修改模板，目前方式为先写入，然后再读取状态，确保指令有执行
# Change list:
# 2024-07-02: First Release
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
        switch_command = f"{command} 0x{step['mux_addr']} 0 0x{step['mux_channel']} 2>/dev/null"
        # 因为现在BMC 有bug，实际运行功能成功但是返回错误，所以如下运行不检查返回值和stdout
        __switch_res = run_shell(switch_command)
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
        <ProgramName>fru_check_S380A</ProgramName>
        <config name="ErrorCode" value="EXF13|Backplane smbus check fail"/>
        <config name="command_type" value="raw_type"/>
        <config name="stop_scan" value="ipmitool raw 0x38 0x41 1 0 2>/dev/null"/>
        <config name="start_scan" value="ipmitool raw 0x38 0x41 1 1 2>/dev/null"/>
        <config name="raw_type" value="ipmitool raw 0x38 0x52"/>
        <config name="i2c_bus" value="7"/>
        <switch_mg9200>
            <step mux_addr="e0" mux_channel="02"/>
            <step mux_addr="e8" mux_channel="02"/>
        </switch_mg9200>
        <switch_fru>
            <step mux_addr="e0" mux_channel="02"/>
            <step mux_addr="e8" mux_channel="01"/>
        </switch_fru>
        <config1 smbus_type="fru" addr="aa" command="0x05 0x00 0x52" location="U23" stand_value="53 33 38 30 4d"/>
        <config1 smbus_type="temp" addr="90" command="0x01 0x00" location="UCC1" stand_value="15 50"/>
        <config1 smbus_type="temp" addr="92" command="0x01 0x00" location="UCC2" stand_value="15 50"/>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[dict], list[dict], list[dict], list[dict]]:
    this_case = None
    _config = {}
    _config1 = {}
    _switch_mg9200: list[dict] = []
    _switch_fru: list[dict] = []
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
    for item in this_case.iter(tag='switch_mg9200'):
        _switch_mg9200 = [c.attrib for c in item.iter(tag='step')]
    for item in this_case.iter(tag='switch_fru'):
        _switch_fru = [d.attrib for d in item.iter(tag='step')]
    _config1 = [item.attrib for item in this_case.iter(tag='config1')]
    _nvme_list = [item.attrib for item in this_case.iter(tag='nvmesmbus')]
    return _config, _config1, _nvme_list, _switch_mg9200, _switch_fru


def bin_to_int(bin_str) -> int:
    int_res = int(bin_str, 2)
    if bin_str[0] == "1":
        int_res = -((int_res ^ (2 ** len(bin_str) - 1)) + 1)
    return abs(int_res)


def fru_temp_cur_check(item_list: list):
    """
    读取fru，温度，Vshunt 并进行比对
    :param item_list: fru,温度，Vshunt 参数，包含type, smbus 地址，位置，对应指令，标准数值
    :return: None
    """
    for item in item_list:
        _res = read_register_value(item['addr'], item['command'])
        if item['smbus_type'] == 'temp':
            _res = int(_res.strip()[:2], 16)
            _temp_lower, _temp_up = item['stand_value'].split()
            if int(_temp_lower) <= _res <= int(_temp_up):
                echopass(f"{item['location']} Temp: {_res} degrees check")
            else:
                promptr(f"{item['location']} Current Temp: {_res}, not between {_temp_lower} and {_temp_up} degrees")
                fail_action(f"{item['smbus_type']} check fail")
        elif item['smbus_type'] == "pwrsmbus":
            _res = bin(int(_res.strip()[:5].replace(" ", ""), 16))[2:]
            _res_int = bin_to_int(_res)
            if _res_int < int(item['stand_value']):
                echopass(f"Backplane Power monitor {item['location']} Vshunt: {_res_int / 100} mV")
            else:
                promptr(f"Backplane Power monitor {item['location']} Vshunt: {_res_int / 100} mV, 应该小于 {int(item['stand_value']) / 100}")
                fail_action(f"Backplane {item['smbus_type']} check fail")
        elif item['smbus_type'] == "fru":
            _res = _res.strip()[:14]
            if _res == item['stand_value']:
                echopass(f"FRU info {_res} check")
            else:
                promptr(f"FRU Current info {_res}, 正确 FRU info应为{item['stand_value']}")
                fail_action(f"Backplane {item['smbus_type']} check fail")


def nvme_smbus_check(nvme_list: list[dict]):
    error_flag: int = 0
    # 在开始测试前先将所有的通道都关闭
    for nvme_config in nvme_list:
        run_shell(f"{ipmi_command} 0x{nvme_config['mux_addr']} 0 0x00 2>/dev/null")
    for nvme_config in nvme_list:
        channel_list = nvme_config['channel_list'].split()
        for channel in channel_list:
            switch_cmd = f"{ipmi_command} 0x{nvme_config['mux_addr']} 0 0x{channel} 2>/dev/null"
            run_shell(switch_cmd)
            # nvme_reg_shell = f"{ipmi_command} 0x4d 1"
            nvme_ver = read_register_value("4d", '1')
            if nvme_ver == "":
                promptr(f"PCA9548_addr {nvme_config['location']}, channel {channel} 未读取到NVME SSD FW")
                error_flag += 1
                continue
            nvme_reg_detect = nvme_ver.splitlines()[1].strip()
            prompty("PCA9548_addr {}, channel {}读取对应NVME SSD信息：{} ".format(nvme_config['mux_addr'], channel, nvme_reg_detect))
            if nvme_reg_detect != (nvme_ver_stand := nvme_config['stand_value']):
                prompty("PCA9548_addr {}, channel {}NVME SSD FW错误,正确应该为：{} ".format(nvme_config['mux_addr'], channel,nvme_ver_stand))
                error_flag += 1
                continue
        run_shell(f"{ipmi_command} 0x{nvme_config['mux_addr']} 0 0x00 2>/dev/null")

    if error_flag != 0:
        for nvme_config in nvme_list:
            run_shell(f"{ipmi_command} 0x{nvme_config['mux_addr']} 0 0x00 2>/dev/null")
        fail_action("NVME Smbus check fail")
    echopass("NVME Smbus check")


def read_register_value(smbus_addr, cmd: str) -> str:
    _full_command = f"{ipmi_command} 0x{smbus_addr} {cmd}"
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
    global ipmi_command
    ipmi_command = create_command()
    stop_res = run_shell(config['stop_scan'])
    if stop_res.returncode != 0:
        fail_action("stop scan fail")
    if not switch_mux(ipmi_command, switch_fru):
        fail_action("切换Switch 通道Fail")
    fru_temp_cur_check(config1)
    # nvme_smbus_check(nvme_smbus_list)
    run_shell(config['start_scan'])


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    ipmi_command = "ipmitool raw 0x38 0x52"
    # xml_config = "MS-S3351.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, config1, nvme_smbus_list, switch_mg9200, switch_fru = get_parameter(xml_config)
    main()
    sys.exit(0)
