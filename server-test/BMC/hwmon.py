#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: hwmon.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-06-12
# Update   : 2024-06-12
# Version  : 1.0.0
# Description:
# 读取风扇，电压，温度，电流所有参数，然后check 值是否在正确范围内
# Change list:
# 2024-06-12: First Release
# -----------------------------------------------------------------------------------
"""
from subprocess import run, PIPE
from supports import *
import os
import sys
import xml.etree.ElementTree as ET
AP_version = "1.1.1"
check_point = ["Volts", "Amps", "degrees", "RPM", "Watts"]


def Fail_action(msg):
    beepremind(1)
    try:
        ErrorCode = config["ErrorCode"]
    except KeyError:
        ErrorCode = "NULL|NULL"
    raise AutoTestFail(ErrorCode, __file__, msg)


def check_line(line):
    # Sys_inlet      | 33.000    | degrees C  | ok    | 0.000   | 2.000   | 5.000   | 65.000  | 68.000  | 69.000
    # 可以在此位置加入检查,判断是否存在错误的关键字,比如读取sensor 时报错
    # if check_string in line:
    #     return line
    line_detail = line.split("|")
    if (sensor_name := line_detail[0].strip()) in skip_list:
        # skip_list.remove(sensor_name)
        return None
    if line_detail[2].split()[0] in check_point:
        if "ok" in line.lower() and sensor_name not in check_sensor.keys():
            print(line)
            return None
        if "ok" in line.lower() and sensor_name in check_sensor.keys():
            _lower_define, _upper_define = check_sensor[sensor_name].split()
            if float(_lower_define) <= float(line_detail[1]) <= float(_upper_define):
                print(line)
                return None
        return line
    return None


def config_format():
    """
    <TestCase>
        <ProgramName>hwmon</ProgramName>
        <ErrorCode>CXSAF|Hardware Monitor test fail</ErrorCode>
        <!-- hwmon.sh： HardWareMonitor 測試 -->
        <!--  支持SuperIO/AST1300/AST1400,ipmitool(AST2300/AST2400/AST2500)  -->
        <!--  TestTool is the tool read the Fan speed ,temperature,and voltage from registers  -->
        <!-- 測試工具從如下選項中選擇TestTool=AST1300FW/AST1400FW/HWM/ipmitool(internal command) and so on  -->
        <TestTool>ipmitool</TestTool>
        <!-- 忽略的測試選項清單 -->
        <IgnoreItem>PSU0_Iin</IgnoreItem>
        <IgnoreItem>PSU1_Iin</IgnoreItem>
        <IgnoreItem>SYS_FAN_7</IgnoreItem>
        <IgnoreItem>U2_1_Temp</IgnoreItem>
        <IgnoreItem>U2_2_Temp</IgnoreItem>
        <IgnoreItem>U2_3_Temp</IgnoreItem>
        <IgnoreItem>M2_1_Temp</IgnoreItem>
        <range_check>
            <sensor_item name="FANTACH1" range_value="500 1800"/>
            <sensor_item name="FANTACH2" range_value="500 1800"/>
            <sensor_item name="FANTACH3" range_value="500 1800"/>
        </range_check>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_config: str) -> tuple[dict, dict]:
    this_case = None
    _config = {}
    tree = ET.ElementTree(file=xml_config)
    root = tree.getroot()
    for program in root.iter(tag='TestCase'):
        for c in program.iter(tag="ProgramName"):
            if c.text == BaseName:
                this_case = program
    if this_case is None:
        Fail_action("未找到对应xml 配置")
    _config['ErrorCode'] = this_case.find("ErrorCode").text
    _config['sensor_tool'] = this_case.find("TestTool").text
    _config['skip_list'] = [x.text for x in this_case.findall("IgnoreItem")]
    _sensor_check: dict = {}
    for d in this_case.iter(tag='sensor_item'):
        __name = d.attrib['name']
        __value = d.attrib['range_value']
        _sensor_check[__name] = __value
    return _config, _sensor_check


def check_ipmitool():
    if run('ipmitool mc info 2>&1 >/dev/null', shell=True, stdout=PIPE, encoding='utf-8').returncode != 0:
        Fail_action("IPMI Driver not work")


def check_hwmon():
    retry_time = 1
    if len(skip_list) != 0:
        print("Below sensor name is skipped during check")
        print(skip_list)
    while retry_time <= trace_times:
        promptg("This is {} time Check sensor".format(retry_time))
        # 读取sensor之前先检查ipmitool 是否可以work,之前发现S368D 搭配之后出现ipmitool 不工作的状况.
        check_ipmitool()
        # 1. 读取出来sensor 值，赋值给变量
        sensor_cmd = "ipmitool sensor"
        sensor_result = run(sensor_cmd, shell=True, stdout=PIPE, encoding='utf-8')
        # 2. 针对每个值进行比对，如果不是风扇，电温度压， 则改项目跳过，如果项目在skip 清单中，项目也同样不比对
        print("*" * 70)
        if sensor_result.returncode == 0:
            for line in sensor_result.stdout.splitlines():
                if (_check_res := check_line(line)) is not None:
                    fail_sensor.append(_check_res)
            print("*" * 70)
            if len(fail_sensor) != 0:
                promptr("below sensor check failed, please check value")
                for failed_item in fail_sensor:
                    promptr(failed_item)
                print("*" * 70)
                Fail_action("sensor check fail")
        else:
            Fail_action("read sensor fail")
        retry_time += 1
        # 3. 无论PASS 或者Fail 都需要将sensor 信息打印出来，以便人员确认，同时不跳出测试，在所有sensor 都确认完之后再Fail
        # 4. 循环测试3次，3次结果都PASS 才是PASS


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    fail_sensor = []
    # xml_config = "E:\\python3\\SQLite3\\MS-S3361.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    os.chdir(WorkPath)
    config, check_sensor = get_parameter(xml_config)
    skip_list = config['skip_list']
    trace_times = 1
    check_hwmon()
    echopass("HWM Check")
    exit(0)
