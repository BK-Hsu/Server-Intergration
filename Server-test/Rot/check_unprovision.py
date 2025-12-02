#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: check_unprovision.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2025-04-28
# Update   : 2025-04-28
# Version  : 1.0.0
# Description :
# check PFR provision后功能是否正常
# Change list:
# 2025-04-28: First Release
# -----------------------------------------------------------------------------------
"""
import os
import subprocess
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
        <ProgramName>check_unprovision</ProgramName>
        <config name="ErrorCode" value="NXF21|Check provision FAIL"/>
        <config name="pfr_status_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x00"/>
        <config name="pfr_status" value="de"/>
        <config name="pfr_ver_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x01"/>
        <config name="pfr_ver_status" value="01"/>
        <config name="rot_svn_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x01"/>
        <config name="rot_svn_number" value="01"/>
        <config name="bios_svn_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x14"/>
        <config name="bios_svn_number" value="00"/>
        <config name="bios_major_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x15"/>
        <config name="bios_minor_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x16"/>
        <config name="bmc_svn_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x17"/>
        <config name="bmc_svn_number" value="01"/>
        <config name="bmc_major_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x18"/>
        <config name="bmc_minor_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x19"/>
        <!--config name="bios_major_ver" value="01"/-->
        <config name="provision_cmd" value="ipmitool raw 0x32 0x1b 0x21 0x0a"/>
        <config name="unprovision_status" value="00"/>
        <config name="production_part_number" value="S4051D270RAE8-X2-RBX"/>
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


def check_pfr(config):
    _pfr_status = run_shell(config['pfr_status_cmd']).stdout.strip()
    if _pfr_status != config['pfr_status']:
        fail_action(f"PFR status({_pfr_status}) is wrong, should be {config['pfr_status']}")
    else:
        processpass(f"PFR status({_pfr_status})")
    _pfr_ver = run_shell(config['pfr_ver_cmd']).stdout.strip()
    if _pfr_ver != config['pfr_ver_status']:
        fail_action(f"PFR ver({_pfr_ver}) is wrong, should be {config['pfr_ver_status']}")
    else:
        processpass(f"PFR status({_pfr_ver})")
    _rot_svn_number = run_shell(config['rot_svn_cmd']).stdout.strip()
    if _rot_svn_number != config['rot_svn_number']:
        fail_action(f"PFR SVN Number({_rot_svn_number}) is wrong, should be {config['rot_svn_number']}")
    else:
        processpass(f"PFR SVN Number({_rot_svn_number})")


def check_bios(config):
    """通过Rot 读取BIOS version信息"""
    _bios_svn_num = run_shell(config['bios_svn_cmd']).stdout.strip()
    if _bios_svn_num != config['bios_svn_number']:
        fail_action(f"PFR BIOS SVN Number({_bios_svn_num}) is wrong, should be {config['bios_svn_number']}")
    else:
        processpass(f"PFR BIOS SVN Number({_bios_svn_num})")
    _bios_major = run_shell(config['bios_major_cmd']).stdout.strip()
    _bios_minor = run_shell(config['bios_minor_cmd']).stdout.strip()
    pfr_bios_ver = ''.join([_bios_major, _bios_minor]).lstrip("0")
    _bios_ver_cmd = '''dmidecode -t0 | grep -i "Version:" | head -n1 | awk -F':' '{print $2}' | tr -d '\n' | awk '$1=$1' '''
    _bios_ver = run_shell(_bios_ver_cmd).stdout.strip().split(".")[-1]
    if pfr_bios_ver != _bios_ver:
        fail_action(f"PFR BIOS ver info({pfr_bios_ver}) is wrong, should be {_bios_ver}")
    else:
        processpass(f"PFR BIOS ver info({pfr_bios_ver})")


def check_bmc(config):
    """通过Rot 读取BMC version信息"""
    _bmc_svn_num = run_shell(config['bmc_svn_cmd']).stdout.strip()
    if _bmc_svn_num != config['bmc_svn_number']:
        fail_action(f"PFR BMC SVN Number({_bmc_svn_num}) is wrong, should be {config['bmc_svn_number']}")
    else:
        processpass(f"PFR BMC SVN Number({_bmc_svn_num})")
    _bmc_major = run_shell(config['bmc_major_cmd']).stdout.strip()
    _bmc_minor = run_shell(config['bmc_minor_cmd']).stdout.strip()
    """_bmc_major,_bmc_minor 为16进制字符串,转换到10进制再比较"""
    _pfr_bmc_ver = '.'.join([str(int(_bmc_major, 16)), str(int(_bmc_minor, 16))])
    bmc_ver_cmd = 'ipmitool mc info 2>/dev/null | grep "Firmware Revision" | cut -c 29-| head -n1 | tr -d " "'
    _bmc_ver = run_shell(bmc_ver_cmd).stdout.strip()
    if _pfr_bmc_ver != _bmc_ver:
        fail_action(f"PFR BMC ver info({_pfr_bmc_ver}) is wrong, should be {_bmc_ver}")
    else:
        processpass(f"PFR BMC ver info({_pfr_bmc_ver})")


def check_unprovision(config):
    _provision_sta = run_shell(config['provision_cmd']).stdout.strip()
    if _provision_sta != config['unprovision_status']:
        fail_action(f"PFR provision status({_provision_sta}) is wrong, should be {config['unprovision_status']}")
    else:
        processpass(f"PFR provision status({_provision_sta})")


def run_shell(cmd: str) -> subprocess.CompletedProcess:
    print(f"Will run below command: {cmd}")
    _res = run(cmd, shell=True, stdout=PIPE, encoding='utf-8', check=True)
    return _res


def main():
    config = get_parameter(xml_config)
    check_pfr(config)
    check_unprovision(config)
    # check_bios(config)
    # check_bmc(config)


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    main()