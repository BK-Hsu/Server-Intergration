#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: elist_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-07-25
# Update   : 2024-10-30
# Version  : 1.0.1
# Description :
# ipmitool sel list 读取BMC 记录log信息，并解析log当中是否有关键字，将对应信息记录在log当中
# 注意此项目不要放在多进程当中运行，此项目运行之后将会删除掉sel list资料，重新测试将会FAIL
# Change list:
# 2024-07-25: First Release
# 2024-10-30: 更新log分析逻辑,版本升级到1.0.1
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
        <ProgramName>elist_check</ProgramName>
        <config name="ErrorCode" value="TXS97|Check sel list fail"/>
        <!--action选项为logging时,将找到的对应的log记录并打印出来, check时将会根据定义的状态来进行比对,此项目在后续将会关闭logging-->
        <config name="action" value="check"/>
        <check_list>
        <!--type中 warning仅表示此信息为警告信息，记录在log当中，exist 表示需要判断此信息是否有出现在list中如果未出现，判断FAIL -->
        <!--type中 critical表示如果出现此信息，则将对应信息记录下来，并且判断此为FAIL -->
        <!--limit 为预设出现的次数限制，detail 表示在string 出现的同时还要判断detail中的内容是否出现-->
            <target string="memory" type="critical" limit="" detail=""/>
            <target string="Timestamp Clock Sync" type="exist" limit="" detail=""/>
            <target string="cpu" type="critical" limit="" detail=""/>
            <target string="Critical" type="warning" limit="" detail=""/>
            <target string="Chassis" type="warning" limit="" detail=""/>
        </check_list>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[dict]]:
    this_case = None
    _config = {}
    _check_list: list[dict] = []
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
    for items in this_case.iter(tag='check_list'):
        _check_list = [_item.attrib for _item in items]
    return _config, _check_list


def chk_elist_log():
    err_flag: int = 0
    read_sel = run('ipmitool sel list', shell=True, stdout=PIPE, encoding='utf-8')
    if read_sel.returncode != 0:
        fail_action("读取sel list失败，请确认BMC 是否工作正常")
    sel_lines = read_sel.stdout.splitlines()
    for _item in check_list:
        _item = elist_sort(_item, sel_lines)
        if _item['type'] == 'critical' and len(_item['match_list']) != 0:
            promptr("BMC记录到如下报错信息,请检查设备！")
            print("-" * 75)
            for _match_case in _item['match_list']:
                print(_match_case)
            print("-" * 75)
            err_flag += 1
        elif _item['type'] == 'exist' and len(_item['match_list']) == 0:
            promptr(f"BMC未记录到{_item['string']}信息,请确认！")
            err_flag += 1
        elif _item['type'] == 'warning' and len(_item['match_list']) != 0:
            prompty("BMC记录到如下报警信息,此信息目前仅作记录使用,不会影响测试FAIL...")
            print("-" * 75)
            for _match_case in _item['match_list']:
                print(_match_case)
            print("-" * 75)
    if err_flag != 0 and config['action'] == 'check':
        fail_action("BMC elist check FAIL!!!")
    echopass("ipmitool sel list check")
    # os.system("ipmitool sel clear 2>&1 >/dev/null")
    sys.exit(0)


def elist_sort(pattern: dict, content: list) -> dict:
    pattern['match_list'] = []
    for _line in content:
        if re.search(pattern['string'], _line, re.I) is not None:
            pattern['match_list'].append(_line)
    return pattern


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, check_list = get_parameter(xml_config)
    chk_elist_log()
