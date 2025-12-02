#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: chkCPU.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-07-10
# Update   : 2024-07-10
# Version  : 1.0.0
# Description :
# check CPU type/Speed/ Core(s)/ Thread(s)/ L1,2,3 Cache
# Change list:
# 2024-07-10: First Release
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
        <ProgramName>chkcpu</ProgramName>
        <config name="ErrorCode" value="TXCP2|Check the speed of CPU fail"/>
        <!--ChkCPU.sh: CPU型號信息等檢測-->
        <!--Frequency: 當前最小頻率-->
        <!--Stepping(僅針對SOC有效)/L#Cache缺省時不測試-->
        <config name="PhysicalNumber" value="2"/>
        <!--CPU_SOC 设定为SOC stepping调用lspci来读取，并且必须要检查, CPU时当stepping位置有维护值时才检查-->
        <config name="CPU_SOC" value="CPU"/>
        <!--Model: 用於區分板載不同的CPU測試,以防錯料-->
        <!--Model: SOC 板载CPU 通过Model 来查找对应的config来比对，所以需要确认GetMDL先运行-->
        <!--Model: 如果不想通过MODEL来管控，将CPU_SOC 项目设定为CPU，将直接search 型号-->
        <Case Model="609-S2581-010,609-S2581-020">
            <Name>Intel(R) Xeon(R) Gold 5416S</Name>
            <Cores>128</Cores>
            <Frequency>2300</Frequency>
            <Stepping></Stepping>
            <L1Cache>12 MiB</L1Cache>
            <L2Cache>40 MiB</L2Cache>
            <L3Cache>48 MiB</L3Cache>
        </Case>
        <Case Model="609-S2581-030">
            <Name>Intel(R) Xeon(R) 6710E</Name>
            <Cores>128</Cores>
            <Frequency>2300</Frequency>
            <Stepping></Stepping>
            <L1Cache>12 MiB</L1Cache>
            <L2Cache>128 MiB</L2Cache>
            <L3Cache>192 MiB</L3Cache>
        </Case>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[dict]]:
    this_case = None
    _config = {}
    _cpu_list: list[dict] = []
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
    for cpu_item in this_case.iter(tag='Case'):
        single_config = {'Model': None if cpu_item.attrib['Model'] == "" else cpu_item.attrib['Model'].split(",")}
        for single_cpu in cpu_item:
            single_config[single_cpu.tag] = single_cpu.text
        _cpu_list.append(single_config)
    return _config, _cpu_list


def get_cache_stepping() -> dict:
    """
    从lscpu 读取出来信息中获取stepping信息，L1,L2,L3 缓存容量，其中L1的缓冲容量需要相加（比如L1d, L1i）
    :return:字典方式返回stepping，L1,L2,L3 缓存，如下
    {'stepping': '3', 'L2': '128 MiB', 'L3': '192 MiB', 'L1': '12 MiB'}
    如果是SOC 的话，其stepping 由lspci -s 00:00.0 | awk '{print $NF}' | tr -d '[[:punct:]]' | head -n1 获取
    """
    _cash_stepping_res = run("lscpu", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    _cpu_dict: dict = {}
    L1_cache_data: list = [0, 'MiB']
    for line in _cash_stepping_res[10:-10]:
        if "Stepping:" in line:
            cpu_stepping = line.split(":")[-1].strip()
            _cpu_dict['stepping'] = cpu_stepping
        elif (cache_match := re.match("L1.? cache:\s*(\d+ \w*) \(.*", line)) is not None:
            _res = cache_match.groups()[0]
            L1_cache_data[0] += int(_res.split()[0])
            if L1_cache_data[1] != _res.split()[1]:
                L1_cache_data[1] = _res.split()[1]
        elif (cache_match := re.match("(L[2-3].?) cache:\s*(\d+ \w*) \(.*", line)) is not None:
            _res = cache_match.groups()
            _cpu_dict[_res[0]] = _res[1]
        else:
            continue
    _cpu_dict['L1'] = f"{str(L1_cache_data[0])} {L1_cache_data[1]}"
    if len(_cpu_dict) != 4:
        print(_cpu_dict)
        fail_action("获取cpu stepping, 缓存信息不全")
    if config['CPU_SOC'] == "SOC":
        shell_cmd = "lspci -s 00:00.0 | awk '{print $NF}' | tr -d '[[:punct:]]' | head -n1"
        _cpu_dict['stepping'] = run(shell_cmd, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
    return _cpu_dict


def get_cpu_info() -> list[dict]:
    """
    从dmidecode -t processor 当中获取每个CPU socket 的名称Socket Designation(CPU0),CPU 名称Version（Intel(R) Xeon(R) 6710E）
    当前运行速度Current Speed(2400 MHz),使用核心数Core Enabled（64），线程数Thread Count（64）
    Processor Information 作为开始解析的开头标志
    读取出来之后，多CPU 需要比对version 是否一致，核心数和线程数相加，current speed 应该是同样，目前先设定为一样进行比对，后续如果有调整的话再修改
    :return:
    """
    _cpu_dmi_res = run("dmidecode -t processor", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    _cpu_list = []
    _cpu_dict = {}
    for line in _cpu_dmi_res:
        if "Processor Information" in line:
            if len(_cpu_dict) != 0:
                _cpu_dict = {}
        elif "Socket Designation" in line:
            _cpu_dict['cpu_socket'] = line.split(":")[-1].strip()
        elif "Version" in line:
            _cpu_dict['cpu_name'] = line.split("Version:")[-1].strip()
        # 将2400 MHz拆开成数字和单位，便于后面比较
        elif "Current Speed" in line:
            _cpu_dict['cur_speed'], config['speed_unit'] = line.split(":")[-1].split()
        elif "Core Enabled" in line:
            _cpu_dict['cpu_cores'] = line.split(":")[-1].strip()
        elif "Thread Count" in line:
            _cpu_dict['cpu_threads'] = line.split(":")[-1].strip()
            if len(_cpu_dict) != 5:
                print(_cpu_dict)
                fail_action("CPU 解析数据不完整，还请确认")
            _cpu_list.append(_cpu_dict)
        else:
            continue
    return _cpu_list


def analysis_cpu_info(cpu_info_list: list[dict]) -> dict:
    """
    将多CPU 的数据整理之后,储存在字典中返回，主要针对核心数，CPU 数量，CPU频率（取所有频率的最小值）
    :param cpu_info_list:所有针对的CPU 信息，每个CPU的信息是一个字典，最后组成列表
    :return:整理之后的CPU信息，字典格式
    """
    __cpu_info_dict: dict = {}
    _cpu_socket_list = [item['cpu_socket'] for item in cpu_info_list]
    __cpu_info_dict['phy_cnt']: int = str(len(_cpu_socket_list))
    _cpu_name_list = [item['cpu_name'] for item in cpu_info_list]
    if len((_cpu_name := set(_cpu_name_list))) != 1:
        # promptr(f"CPU型号{_cpu_name_list}不相同，请更换同型号CPU测试")
        fail_action(f"CPU型号{_cpu_name_list}不相同，请更换同型号CPU测试")
    __cpu_info_dict['cpu_name']: str = _cpu_name_list[0]
    # 多CPU模式，cur_speed 取其中最小值，cover下限, 同时此值将变更为int 格式，便于后面进行比对
    __cpu_info_dict['cur_speed']: int = min([int(item['cur_speed']) for item in cpu_info_list])
    __cpu_info_dict['cpu_socket']: list[str] = _cpu_socket_list
    __cpu_info_dict['cpu_cores'] = str(sum([int(item['cpu_cores']) for item in cpu_info_list]))
    __cpu_info_dict['cpu_threads'] = str(sum([int(item['cpu_threads']) for item in cpu_info_list]))
    return __cpu_info_dict


def compare_info(cur_cpu_info: dict, cur_cache_info: dict, stand_cpu_info: dict) -> bool:
    """
    比较目前CPU 信息与设定的CPU 信息是否匹配
    :param cur_cache_info: 从主板读取出来的缓存信息，以及stepping 版本
    :param cur_cpu_info: 从主板抓出来的CPU信息，CPU数量，内核数，线程数，频率
    :param stand_cpu_info: 从xml档案获取的CPU name与目前主板CPU一致的设定
    :return: 如果比对PASS，返回True， else False
    """
    _error_flag: int = 0
    promptg("CPU信息比对如下：")
    # CPU物理个数
    print("%-20s%-2s" % ("Physical Number", ":"), end='')
    if cur_cpu_info['phy_cnt'] == config['PhysicalNumber']:
        promptg(f" {cur_cpu_info['phy_cnt']} PCS {cur_cpu_info['cpu_socket']}")
    else:
        promptr(f"{cur_cpu_info['phy_cnt']} PCS (expect: {config['PhysicalNumber']})")
        _error_flag += 1
    # CPU Name
    print("%-20s%-2s%s" % ("Actual CPU Name", ":", cur_cpu_info['cpu_name']))
    # 比对核心数量
    print("%-20s%-2s" % ("Cores", ":"), end='')
    if (_value := cur_cpu_info['cpu_cores']) == (stand_value := stand_cpu_info['Cores']):
        promptg(f" {_value} cores ({stand_value} cores)")
    else:
        promptr(f" {_value} cores ({stand_value} cores)")
        _error_flag += 1
    # Frequency 比对
    print("%-20s%-2s" % ("CPU Frequency", ":"), end='')
    if (_value := cur_cpu_info['cur_speed']) >= (stand_value := int(stand_cpu_info['Frequency'])):
        promptg(f" {_value} {config['speed_unit']} ({stand_value} {config['speed_unit']})")
    else:
        promptr(f" {_value} {config['speed_unit']} ({stand_value} {config['speed_unit']})")
        _error_flag += 1
    # stepping, 如果Type 为SOC的情况下，一定要比对stepping，CPU情况下如果有设置就比对
    print("%-20s%-2s" % (f"Stepping", ":"), end='')
    if config['CPU_SOC'] != 'SOC' and stand_cpu_info['Stepping'] is None:
        print(f" {cur_cache_info['stepping']}")
    else:
        if (_value := cur_cache_info['stepping']) == (stand_value := stand_cpu_info['Stepping'].lower()):
            promptg(f" {_value} ({stand_value})")
        else:
            promptr(f" {_value} ({stand_value})")
            _error_flag += 1
    # L1,L2, L3缓存
    for cache_name in ['L1', 'L2', 'L3']:
        print("%-20s%-2s" % (f"{cache_name} cache", ":"), end='')
        if (stand_value := stand_cpu_info[f'{cache_name}Cache']) is not None:
            if (_value := cur_cache_info[cache_name]) == stand_value:
                promptg(f" {_value} ({stand_value})")
            else:
                promptr(f" {_value} ({stand_value})")
                _error_flag += 1
        else:
            print(f" {cur_cache_info[cache_name]}")
    # Hyperthreading 超线程，此部分仅做为记录，但是暂不在xml定义及比对
    # 在proc/cpuinfo 当中如果siblings = 2*cpu cores,则表示超频，如果直接相等，则未超频
    if int(cur_cpu_info['cpu_threads']) / int(cur_cpu_info['cpu_cores']) == 2:
        print("%-20s%-2s%s" % ("Hyperthreading", ":", "Yes"))
    else:
        print("%-20s%-2s%s" % ("Hyperthreading", ":", "No"))

    if _error_flag != 0:
        fail_action("CPU info check Fail")
    else:
        echopass("CPU info check")
    return True


def main() -> None:
    cpu_cache_stepping = get_cache_stepping()
    cpu_data_sort = analysis_cpu_info(get_cpu_info())
    if config['CPU_SOC'] == "SOC":
        # 如果是SOC板载的CPU,需要根据model 来查找CPU的信息来进行比对，和如下的方式比较，
        # 差异只是在SOC 根据MODEL信息来获取stand_cpu, 而安装CPU 则是在所有设定中search 型号，如果型号匹配则以当前信息来比对
        # 先通过getmdl 来获取对应的MES 型号,然后再来查找对应的config
        if not os.path.exists(model_file_path):
            fail_action("Model file not found, please run GetMDL.sh first")
        with open(model_file_path, 'r', encoding='utf-8') as f:
            cur_model: str = f.read().strip()
        for single_define in cpu_list:
            if cur_model in single_define['Model']:
                if compare_info(cpu_data_sort, cpu_cache_stepping, single_define):
                    sys.exit(0)
        fail_action(f"{cur_model} 在xml档案中未到到对应设置，请确认该erp CPU是否正确")
    else:
        if (cur_cpu_name := cpu_data_sort['cpu_name']) in (name_define_list := [item['Name'] for item in cpu_list]):
            match_case_index = name_define_list.index(cur_cpu_name)
            if compare_info(cpu_data_sort, cpu_cache_stepping, cpu_list[match_case_index]):
                sys.exit(0)
        else:
            fail_action(f"Current CPU: {cur_cpu_name} 不在配置档案设定型号{name_define_list}中")


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    previous_path = os.path.dirname(WorkPath)
    # 通过在model.txt 当中获取对应主板的erp，此主要针对onboard CPU小板测试（组合测试针对此点无效）
    model_file_path = os.path.join(previous_path, "PPID/MODEL.TXT")
    BaseName = os.path.basename(__file__).split(".")[0]
    config, cpu_list = get_parameter(xml_config)
    main()
