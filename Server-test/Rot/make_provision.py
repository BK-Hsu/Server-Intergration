#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: make_provision.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2025-04-28
# Update   : 2025-04-28
# Version  : 1.0.0
# Description :
# S368E AST1060对S368D BIOS&BMC 进行provision
# Change list:
# 2025-04-28: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import xml.etree.ElementTree as ET
from subprocess import run, PIPE


from supports import *
AP_version = "1.0.0"
error_code = "NULL|NULL"


def fail_action(msg):
    promptr(msg)
    beepremind(1)
    raise AutoTestFail(error_code, __file__, msg)


def config_format():
    """
    <TestCase>
        <ProgramName>make_provision</ProgramName>
        <config name="ErrorCode" value="NXF21|Make provision FAIL"/>
        <config name="provision_cmd" value="ipmitool raw 0x28 0x45 0x01 2>/dev/null"/>
        <config name="unprovision_cmd" value="ipmitool raw 0x28 0x45 0x02 2>/dev/null"/>
        <config name="check_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x0a"/>
        <config name="provision_status" value="20"/>
        <config name="action_status" value="02"/>
        <config name="unprovision_status" value="00"/>
        <config name="wait_time" value="30"/>
        <config name="production_part_number" value="S4051D270RAE8-X2-RBX"/>
        <config name="pfr_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x00"/>
        <config name="pfr_status" value="de"/>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> dict:
    if xml_path is None:
        fail_action(f"xml config not found")
    else:
        if not os.path.isfile(xml_path):
            fail_action(f"xml config {xml_path} not exist")
    tree = ET.ElementTree(file=xml_path)
    root = tree.getroot()
    this_case = None
    for program in root.iter(tag='TestCase'):
        for c in program.iter(tag="ProgramName"):
            if c.text == BaseName:
                this_case = program
                break
        if this_case:
            break
    if this_case is None:
        fail_action("未找到对应xml 配置")
    _config = {}
    for item in this_case.iter(tag='config'):
        name = item.attrib['name']
        _config[name] = item.attrib['value']
    global error_code
    error_code = _config.get('ErrorCode', 'NULL|NULL')
    return _config


def check_cur_status(config):
    print(f"check provison status cmd: {config['check_cmd']}")
    before_status = run(config['check_cmd'], shell=True, stdout=PIPE, encoding='utf-8', check=True).stdout.strip()
    print(f"The Rot is in status({before_status})")
    if before_status == config['unprovision_status']:
        return 'un_prov'
    elif before_status == config['provision_status']:
        return 'prov'
    elif before_status == config['action_status']:
        return 'prov_finished'
    else:
        return before_status


def check_pfr(config):
    print(f"Will read PFR status({config['pfr_cmd']})")
    _pfr_res = run(config['pfr_cmd'], shell=True, stdout=PIPE, encoding='utf-8')
    if _pfr_res.returncode != 0:
        fail_action("Detect PFR FAIL,please check S368E and FW!")
    if (_pfr_status := _pfr_res.stdout.strip()) != config['pfr_status']:
        fail_action(f"PFR status({_pfr_status}) error, should be {config['pfr_status']}")
    else:
        echopass(f"PFR status({_pfr_status})")


def check_part_number(config):
    """检查FRU中Product Part Number是否已经设置,如果没设置将无法进行provision"""
    sys_part_number = None
    _res = run("ipmitool fru print 0", shell=True, stdout=PIPE, encoding='utf-8')
    if "not present" in _res.stdout.lower():
        fail_action("读取FRU失败,请手动输入ipmitool fru print 0查看!")
    if _res.returncode != 0:
        fail_action("读取FRU失败,请手动输入ipmitool fru print 0查看!")
    for line in _res.stdout.splitlines():
        if "Product Part Number" in line:
            sys_part_number = line.split(" : ")[-1].strip()
            break
    if sys_part_number != config['production_part_number']:
        promptr(f"FRU Product Part Number({sys_part_number}), should be {config['production_part_number']}")
        promptr(f"请将配备主板的FRU通过指令(ipmitool fru edit 0 filed p 2 {config['production_part_number']})烧录对应信息,然后重新开机再次测试")
        fail_action("Check 主板FRU 信息不匹配,无法进行provision,请检查！")
    else:
        prompty(f"Read FRU Product Part Number: {sys_part_number}")


def main():
    import time
    config = get_parameter(xml_config)
    check_part_number(config)
    check_pfr(config)
    _status = check_cur_status(config)
    if _status == 'un_prov' or _status == "prov_finished":
        print(f"Will make provision by cmd: {config['provision_cmd']}")
        os.system(config['provision_cmd'])
        time.sleep(50)
        _cur_status = check_cur_status(config)
        if _cur_status == 'prov_finished':
            time.sleep(int(config['wait_time']))
            echopass("Rot Provision finished!")
        else:
            # 如果make provision失败，此时需要将状态切换为unprovision状态,避免人员关机之后无法再开机
            prompty("Provision FAIL, will make unprovision.")
            os.system(config['unprovision_cmd'])
            time.sleep(10)
            fail_action('Make provision failed, please contact PE for support!')
    elif _status == 'prov':
        promptg(f"Provision is already finished")
    else:
        fail_action(f"当前状态({_status}),正确状态应该是un_prov或者prov,请检查配备及FW 是否匹配！")


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    main()
