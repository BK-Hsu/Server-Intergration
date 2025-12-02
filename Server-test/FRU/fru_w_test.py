#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: fru_w.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-08-06
# Update   : 2025-01-01
# Version  : 1.0.3
# Description:
# 通过ipmitool fru 来写入FRU 信息
# Change list:
# 2024-08-06: First Release
# 2024-11-12: 针对Product Serial和Product Version 在PCBA 烧录了PCBA的条码和阶层码,
# 组装时比对default值将action设置为check_pcba,同时default_vaule设置成PCBA 烧录的fru type
# 会从FRU中读取出对应的值作为其default值,同时针对FRU print 0未找到设备的报错进行cover
# 2025-01-01: 在联网获取机种时对6阶的机种判断是否为主板，而不是小卡，避免组合程式烧录FRU时将小卡信息烧录HPM当中，版本升级到1.0.3
# -----------------------------------------------------------------------------------
"""
import os
import sys
import re
import time
from pprint import pprint
from subprocess import run, PIPE
import xml.etree.ElementTree as ET
from supports import *

AP_version = "1.0.1"
factory_type = "shenzhen"


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
        <ProgramName>fru_w</ProgramName>
        <config name="ErrorCode" value="TXS97|fru info check fail"/>
        <config name="flash_cmd" value="ipmitool fru edit 0 field"/>
        <config name="WebSite" value="http://20.40.1.40/eps-web/upload/uploadservice.asmx"/>
        <!--如果不需要烧录bin档，请置空,其他则填上需要烧录的档案名-->
        <config name="fru_bin_file" value="fru_512_msi.bin"/>
        <config name="fru_bin_checksum" value="3231"/>
        <!--bin_flash_flag 的状态设定为flash 或者skip, flash表示需要烧录，skip 表示跳过bin档烧录-->
        <config name="bin_flash_flag" value="skip"/>
        <config name="double_flash" value="disable"/>
        <fru_list>
            <!--string 表示直接烧录value内容，file从文件中读取内容烧录，write_date 表示需要烧录时间，mes_PCBA 表示PCB时，从mes 获取机种信息-->
            <!--mes_BB 表示从mes 获取组装机种信息，单板条码，单板机种信息，scan表示直接提示扫码，将扫码内容烧录进去-->
            <!--Node 表示此参数是多模块模式, 此时动作是将原始FRU 对应的值, 检查是否为正确匹配此系统的值, 同时将此值作为将要烧录的值-->
            <!--action 参数表明此项参数，在测试时的动作，目前设定如果为check的话，只执行比对，跳过烧录动作，如果不设定或者其他，则正常烧录-->
            <!--action 设定为check_pcba的情况下,将default_value 设定为对应fru_type,比如Board Serial,会以FRU中主板条码作为default值,目前仅对Product Version和Product Serial 设置-->
            <fru type="Board Part Number" param1="b 3" value="" value_type="mes_BB" default_value="" action=""/>
            <fru type="Board Serial" param1="b 2" value="" value_type="mes_BB" default_value="" action=""/>
            <fru type="Board Product" param1="b 1" value="D4051" value_type="string" default_value="" action=""/>
            <fru type="Product Name" param1="p 1" value="CX270-S5062" value_type="string" default_value="" action=""/>
            <fru type="Product Part Number" param1="p 2" value="S5062X270RAU8" value_type="string" default_value="" action=""/>
            <fru type="Product Version" param1="p 3" value="" value_type="mes_BB" default_value="" action=""/>
            <fru type="Product Serial" param1="p 4" value="/TestAP/PPID/PPID.TXT" value_type="file" default_value="" action=""/>
            <fru type="Chassis Part Number" param1="c 0" value="309-S380102-H76" value_type="string" default_value="" action=""/>
            <fru type="Chassis Serial" param1="c 1" value="/TestAP/Scan/chassis_sn.txt" value_type="file" default_value="" action=""/>
            <fru type="Chassis Extra" param1="c 2" value="2U" value_type="string" default_value="" action=""/>
            <fru type="Board Mfg Date" param1="./FRUSH MDT" value="" value_type="write_date"/>
        </fru_list>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[dict]]:
    this_case = None
    _config = {}
    _fru_list: list = []
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
    for _fru_case in this_case.iter(tag='fru_list'):
        _fru_list = [x.attrib for x in _fru_case]
    return _config, _fru_list


def date_time_check(flash_time) -> bool:
    """
    从BMC 读取时间，比对时间与现在系统时间是否一致，主要卡年月日相同，同时时间为”08：00：00“
    :param flash_time:从ipmitool fru print 0中读取出来的 “Board Mfg Date        : Thu Aug 22 08:00:00 2024”
    :return:bool
    """
    import datetime
    parsed_time = time.strptime(flash_time, "%a %b %d %H:%M:%S %Y")
    formatted_str = time.strftime("%Y-%m-%d %H:%M:%S", parsed_time)
    _flashed_date, _flashed_time = formatted_str.split()
    current_time = datetime.datetime.now()
    _cur_date = current_time.strftime("%Y-%m-%d")
    if _flashed_date == _cur_date and _flashed_time == "08:00:00":
        processpass(f"Board Mfg Date：{flash_time}")
        return True
    else:
        processfail(f"Board Mfg Date：{flash_time}, 当前日期为：{_cur_date}")
        return False


def fru_check() -> bool:
    err_flag: int = 0
    _res = run('ipmitool fru print 0', shell=True, stdout=PIPE, encoding='utf-8')
    for fru_case in fru_list:
        for line in _res.stdout.splitlines():
            if (_fru_type := fru_case['type']) in line:
                if _fru_type == "Board Mfg Date":
                    if date_time_check(line.split(" : ")[-1].strip()):
                        break
                    else:
                        err_flag += 1
                        break
                else:
                    _flash_value = get_flash_value(fru_case)
                    if _flash_value != (_actual_value := line.split(" : ")[-1].strip()):
                        processfail(f"{_fru_type} 读值：{_actual_value}, 与实际标准值{_flash_value}比对")
                        err_flag += 1
                        break
                    else:
                        processpass(f"{_fru_type} 读值：{_actual_value}, 与实际标准值{_flash_value}比对")
                        break
    return True if err_flag == 0 else False


def fru_status_check(stage, next_station):
    """
    根据板子目前的阶层和站别来检查板子是否需要更新FRU，在PCBA并且在功能站，读取资料比对主板条码，如果是默认空白，则烧录资料，如果已经跟条码一致，则跳过烧录，直接比对
    组装的方式类似，但是组装需要检查chassis 的serial，Part Number，Extra 这三项，项目定义内容设置成可调整方式，便于后续调整
    :param stage:板子目前所处的阶，是PCBA还是BB
    :param next_station:板子目前的站别
    :return:返回目前板子烧录的状况，是允许烧录"allow"，还是跳过烧录"skip"，还是禁止烧录"forbidden"
    """
    _flash_pointer: str = "forbidden"
    if stage == "PCBA" and next_station in ['1528', '2695']:
        _check_item = ['Board Serial']
        _res = list(map(lambda _single_case: case_compare(_single_case), _check_item))
    elif stage == "BB" and next_station in ['1543', '1545', '0']:
        _check_item = ['Chassis Serial', 'Chassis Part Number']
        _res = list(map(lambda _single_case: case_compare(_single_case), _check_item))
    else:
        fail_action(f"板子站别为{next_station},不在功能测试站别，不允许进行FRU 烧录!!!")
    if len(set(_res)) == 1 and _res[0] == "allow":
        _flash_pointer = "allow"
    elif len(set(_res)) == 1 and _res[0] == "skip":
        _flash_pointer = "skip"
    else:
        fail_action(f"FRU 状态既不是默认状态，也不是将要烧录的状态，请确认！！！")
    return _flash_pointer


def case_compare(single_case):
    # 默认状态设置成禁止,只有在check 正常之后才会改成正常， 为default值则为改为allow, 与要烧录值相同，则改为skip,其他条件下为forbidden
    _flash_flag = "forbidden"
    _case_matched = fru_list[relation_dict[single_case]]
    _flash_value = get_flash_value(_case_matched)
    if _case_matched['default_actual'] == _case_matched['default_value']:
        _flash_flag = "allow"
    elif _case_matched['default_actual'] == _flash_value:
        _flash_flag = "skip"
    else:
        _flash_flag = "forbidden"
    return _flash_flag


def fru_w():
    _err_flag = 0
    for fru_item in fru_list:
        if fru_item['value_type'] == "write_date":
            flash_fru_date()
        else:
            if fru_item['action'] == "check":
                # 如果action 设定为check, 只比对，不执行其他操作
                continue
            elif fru_item['action'] == "check_pcba":
                fru_item['default_value'] = def_actual_dict[fru_item['default_value']].strip()
            _flash_value = get_flash_value(fru_item)
            _flash_cmd = f"{config['flash_cmd']} {fru_item['param1']} {_flash_value}"
            if config['double_flash'] == "disable":
                # 先比较是不是default值，如果是default值，则可以开始烧录，如果不是default 值，
                # 现在读出来的值与要烧录的值是不是一样的，如果是一样的，直接跳过，不用烧录
                if (_default_act := def_actual_dict[fru_item['type']].strip()) == fru_item['default_value']:
                    if _default_act == _flash_value:
                        processpass(f"{fru_item['type']} 默认值与要烧录值{_flash_value}一致，将SKIP 此项目烧录")
                        continue
                    else:
                        run_shell(_flash_cmd)
                elif _default_act == _flash_value:
                    processpass(f"{fru_item['type']} 此前已经烧录{_flash_value}，将SKIP 此项目烧录")
                else:
                    fail_action(
                        f"{fru_item['type']}当前值{_default_act}不是初始值{fru_item['default_value']}，"
                        f"也不是要烧录的值{_flash_value}，不允许重复烧录，请确认！")
            else:
                run_shell(_flash_cmd)


def check_string_format(value, fru_type) -> bool:
    """
    针对6阶和7阶机种名，检查设定的内容是否符合要求，这个只限定在MSI内部使用，因为外部不会使用msi的机种名定义方式
    定义factory_type 为shenzhen，只有符合此设定的情况下才检查，其他情况不检查
    :param value: 设定在string或者file中的值，格式为str
    :param fru_type: 需要烧录的fru 类别，主要检查Product Version，Board Part Number这两项
    :return: 如果符合要求，返回True，否则False
    """
    if factory_type != "shenzhen":
        return True
    if fru_type != "Board Part Number" and fru_type != "Product Version":
        return True
    elif fru_type == "Board Part Number" and re.search("^609-[0-9a-zA-Z]{4,5}-[0-9a-zA-Z]{3}", value) is not None:
        return True
    elif fru_type == "Product Version" and re.search("^709-[0-9a-zA-Z]{4,5}-[0-9a-zA-Z]{3}", value) is not None:
        return True
    elif fru_type == "Chassis Part Number":
        _model = mes_dict['bb_model'].split("-")[1]
        if re.search("^309-%s\w{3}-\w{3}" % _model, value) is not None:
            return True
        else:
            return False
    else:
        return False


def get_flash_value(_config) -> str:
    _flash_value = None
    if _config['value_type'] == "file":
        if not os.path.exists(_config['value']):
            fail_action(f"{_config['value']} is not exist, please check!")
        else:
            with open(_config['value']) as f:
                _flash_value = f.read().strip()
        if not check_string_format(_flash_value, _config['type']):
            fail_action(f"xml 中{_config['type']} 要烧录的值设定格式不正确，请检查！")
    elif _config['value_type'] == "string":
        if _config['value'] == "":
            fail_action(f"{_config['type']} value 设定值不能为空, please check!")
        else:
            _flash_value = _config['value'].strip()
        if not check_string_format(_flash_value, _config['type']):
            fail_action(f"xml 中{_config['type']} 要烧录的值设定格式不正确，请检查！")
    elif _config['value_type'] == "mes_PCBA":
        # 从MES 获取对应的需要烧录的value值,从PCBA PPID中获取机种名
        if _config['type'] == "Board Part Number":
            _flash_value = mes_dict['pcb_model']
        elif _config['type'] == "Product Version":
            _flash_value = mes_dict['pcb_model']
        else:
            fail_action(f"{_config['type']} 不能适用mes 获取资料，请检查设定")
    elif _config['value_type'] == "mes_BB":
        if _config['type'] == "Board Serial":
            _flash_value = mes_dict['pcb_sn']
        elif _config['type'] == "Board Part Number":
            _flash_value = mes_dict['pcb_model']
        elif _config['type'] == "Product Version":
            _flash_value = mes_dict['bb_model']
            if _flash_value is None:
                fail_action(f"{_config['type']} 因为站别问题或者已经更新BMC导致无法获取到7阶机种名，"
                            f"value_type 请设定为string或者file,并手动指定需要烧录的7阶料号")
        else:
            fail_action(f"{_config['type']} 不能适用mes 获取资料，请检查设定")
    elif _config['value_type'] == "scan":
        # 从扫码的方式获取value值
        _flash_value = input("please scan the serial Number: ")
    elif _config['value_type'] == "Node":
        _flash_value = def_actual_dict['Board Serial'].strip()
    else:
        fail_action("参数设定错误，请检查value_type")
    # 在测试烧录之前应该先比对是否已经烧录，如果相同则应该取消烧录动作
    if _flash_value is None:
        fail_action(f"{_config['type']} Not get available Data")
    return _flash_value


def run_shell(cmd) -> None:
    print(f"will begin to run: {cmd}")
    _res = run(cmd, shell=True, stdout=PIPE, encoding='utf-8')
    _res_lines = _res.stdout.splitlines()
    pprint(_res_lines)
    if _res.returncode != 0:
        if "Writing new FRU" in _res_lines[-2] and "Done" in _res_lines[-1]:
            processpass(f"{cmd}")
        else:
            fail_action(f"{cmd} flash FAIL")
    else:
        processpass(f"{cmd}")


def read_fru() -> dict:
    actual_dict: dict = {}
    # 增加在烧录前比对功能，同时应该还需要增加防呆功能，即不允许手动执行，只有在程式顺跑的时候才能运行程式
    _res = run("ipmitool fru print 0", shell=True, stdout=PIPE, encoding='utf-8')
    if "not present" in _res.stdout.lower():
        fail_action("读取FRU失败,请手动输入ipmitool fru print 0查看!")
    for line in _res.stdout.splitlines():
        if line:
            _fru_type, _type_value = line.split(" : ")
            actual_dict[_fru_type.strip()] = _type_value
    return actual_dict


def flash_bin() -> bool:
    """
    1. 检查文件是否存在
    2.检查checksum值是否正确
    2. 烧录成功，检查返回值，正常返回True，否则返回False
    :return: Bool
    """
    _fru_bin = config['fru_bin_file']
    if not os.path.exists(_fru_bin):
        fail_action(f"FRU bin file {_fru_bin} not exists!")
    # 检查文件checksum值是否正确
    _md5_res = run(f"checksum {_fru_bin}", shell=True, stdout=PIPE, encoding='utf-8').stdout.split(":")[-1].strip()
    if _md5_res == config['fru_bin_checksum']:
        echopass(f"FRU bin file: {_fru_bin} checksum: {_md5_res}")
    else:
        fail_action(f"RU bin file: {_fru_bin} checksum: {_md5_res}, 与定义checksum值{config['fru_bin_checksum']}不同!!")
    _flash_res = run(f"ipmitool fru write 0 {_fru_bin}", shell=True, stdout=PIPE, encoding='utf-8')
    if _flash_res.returncode == 0:
        processpass(f"Flash FRU bin {_fru_bin}")
        return True
    else:
        fail_action(f"Flash FRU bin {_fru_bin}")


def data_via_mes() -> dict:
    global _src_sn
    _mes_data: dict = {}
    # 在获取资料之前，先判断板子是PCBA 单板还是组装阶层
    _src_file = os.path.abspath("/TestAP/PPID/PPID.TXT")
    if not os.path.exists(_src_file):
        fail_action(f"{_src_file} not found, please check")
    else:
        with open(_src_file, 'r', encoding='utf-8') as f:
            _src_sn = f.read().strip()
    _model = query_mes(2, _src_sn)
    if re.match("^609-\w{4}\d-\w{3}", _model) is not None:
        _cur_stage = "PCBA"
    elif re.match("^709-", _model) is not None:
        _cur_stage = "BB"
    elif re.match("^939-", _model) is not None:
        _cur_stage = "BB"
    else:
        fail_action(f"查询机种的model信息{_model}错误,请确认板子状态！")
    _next_station = query_mes(4, _src_sn)
    _mes_data['next_station'] = _next_station
    if _cur_stage == "BB":
        # 如果在组装阶段，并且板子是模块，几块板子安装在同一个系统内，此时组装不允许烧录bin档，避免将已经烧录的Board 信息刷新掉
        _mes_data['bb_sn'] = _src_sn
        _mes_data['bb_model'] = _model
        # 如果MES 查询出来的组装model 名为939, 应该检查已经烧录的里面是否为709，如果不是709，则要求更改config value_type档案为 string
        if re.match("^939-", _mes_data['bb_model']) is not None:
            # 如果板子流程已经到了包装，回过来刷FRU，此时获取要烧录的资料的方式只有2种：1,读取原本已经烧录的内容，2, 手动输入要烧录的内容进行烧录
            # 如果是1的情况, 此时是在设定在mes获取的情况下，此时读取原本已经烧录的内容,如果读取的资料匹配不上，提示fail，需修改config设定
            if "mes" in fru_list[relation_dict['Product Version']]['value_type']:
                _cur_sys_model = def_actual_dict['Product Version'].strip()
                _model_name = _model.split("-")[1]
                if (_model_matched := re.search(f"^709-{_model_name}", _cur_sys_model)) is not None:
                    _mes_data['bb_model'] = _cur_sys_model
                else:
                    fail_action(f"mes 无法获取7阶料号，请将value_type设定为string,并手动设定7阶料号")
        _mes_data['pcb_sn'] = query_mes(7, _src_sn)
        _mes_data['pcb_model'] = query_mes(2, _mes_data['pcb_sn'])
        if re.match("^609-", _mes_data['pcb_model']) is None:
            fail_action(f"单板机种信息为{_mes_data['pcb_model']}, 应该是6阶料号609-xxxx-xxx")
    else:
        _mes_data['pcb_sn'] = _src_sn
        _mes_data['pcb_model'] = _model
    return _mes_data


def query_mes(mes_param1, serial_number) -> str:
    if mes_param1 == 7:
        _barcode = "sBarcodeNo"
    elif mes_param1 == 6:
        _barcode = "sComponentNo"
    elif mes_param1 == 9:
        _barcode = "sMac"
    else:
        _barcode = "sBarcode"
    cmd_format = f'mes {config["WebSite"]} {mes_param1} "{_barcode}={serial_number}" 2>/dev/null'
    _res = run(cmd_format, shell=True, stdout=PIPE, encoding='utf-8')
    if _res.returncode != 0:
        pprint(_res.stdout)
        fail_action(f"{cmd_format} 查询结果失败,请检查格式及网络是否正常")
    _res_detail = _res.stdout.splitlines()[1].strip()
    if len(_res_detail) <= 25:
        return _res_detail
    else:
        fail_action(f"{cmd_format} 查询结果为{_res_detail}，长度应该在小于25位之间")


def flash_fru_date():
    import datetime
    stand_time = datetime.datetime(1996, 1, 1)
    time2 = datetime.datetime.now()
    current_time = datetime.datetime(time2.year, time2.month, time2.day)
    time_gap = (current_time - stand_time).days
    time_gap_minutes = time_gap * 24 * 60
    time_hex = hex(time_gap_minutes)[2:].upper()
    fru_date_process = run("./FRUSH MDT {}".format(time_hex), shell=True, stdout=PIPE, encoding='utf-8')
    print(f'The flash return code is {fru_date_process.returncode}')
    _res_lines = fru_date_process.stdout.splitlines()
    for line in _res_lines:
        print(line)
    if fru_date_process.returncode != 0:
        if "Command is completely" in _res_lines[-2]:
            processpass(f"FLASH Board Mfg Date")
        else:
            fail_action(f"FLASH Board Mfg Date FAIL")
    else:
        processpass(f"FLASH Board Mfg Date")


def check_status():
    """
    结合读取的状态和目前MES 的站别信息，来判断是否需要烧录bin档，并且后续要烧录的资料是否使用目前读取出来的信息，比如主板条码等等
    :return:None
    """
    node_item = "Board Serial"
    check_station = ['1528', '2695', '1547', '1545']
    if mes_dict['next_station'] not in check_station:
        # 检查是否在功能站, 后续可以考虑输入密码的方式来允许debug 烧录
        fail_action(f"该机器目前不在功能测试站, 不能进行FRU烧录!!")
    # 如果读取到的未烧录FRU的信息数量少于设定值，同时config 设定为disable 的状况，则判定设定有错误，
    if len(def_actual_dict) != 17 and config['bin_flash_flag'] != "flash":
        fail_action("FRU 初始状态错误，请输入ipmitool fru print 0 查看")
    # 如果Board serial value_type 为Node模式的话，需要在此位置资料读取出来并确认资料的正确性，后面测试时使用此def_actual_dict，以便后续烧录使用
    if fru_list[relation_dict[node_item]]['value_type'] == "Node":
        if len(def_actual_dict[node_item].strip()) == 0:
            fail_action(f"Board serial 读取为空, 请检查板子状态及流程!")
        _mes_serial = query_mes(6, def_actual_dict[node_item].strip())
        if _mes_serial != _src_sn:
            fail_action(f"目前Node内烧录Board Serial 不对应此系统,请检查Node 是否安装错误或者烧录错误.")


def parser_argv_new(AP_version, TestMode='SerialTest'):
    import argparse
    # 当未指定xml名字时使用默认路径下的xml
    xml_file = GetXmlPath()
    # 显示使用方法
    parser = argparse.ArgumentParser()
    # -x 后面带xml档案路径或者是后续json 的路径
    parser.add_argument('-x', nargs='?', default=xml_file, help='The parameter should be xml or json file')
    # -p 代表目前Parallel 测试设定，如果-p， 默认值为打印parallel
    parser.add_argument('-p', '-P', action='store_const', const=TestMode, help='Serial Test or Parallel Test mode')
    # -U 代表调用程式的人员,
    parser.add_argument('-U', '--user', type=str, default="operator")
    # -v 默认显示程式版本
    parser.add_argument('-v', '--v', action='version', version='%(prog)s {}'.format(AP_version))
    #
    params = parser.parse_args()
    if params.p is not None:
        print(params.p)
        sys.exit(1)
    return params.x, params.user


def main():
    global mes_dict
    global def_actual_dict
    # 在烧录动作执行前，先将目前机台中fru信息读取出来，并存储在变量当中，依据后面的需求是执行比对还是执行烧录
    def_actual_dict = read_fru()
    print(def_actual_dict)
    # 在查询MES资料之前还需要检查联网是否正常,for 深圳工厂测试时必配网络获取
    if factory_type == "shenzhen":
        _res = run("ping 20.40.0.1 -c 2 -w 3", shell=True, stdout=PIPE, encoding='utf-8')
        if _res.returncode != 0:
            pprint(_res.stdout)
            promptr(f"Ping 网检查Fail, 请检查网络连接及设定是否正确")
        else:
            processpass("网络连接")
        prompty("will begin to 查询MES资料，请等待...")
        mes_dict = data_via_mes()
        print(mes_dict)
        check_status()
    if config['bin_flash_flag'] == "flash":
        flash_bin()
    fru_w()
    time.sleep(0.5)
    if not fru_check():
        fail_action(f"FRU check FAIL!!")


if __name__ == '__main__':
    relation_dict: dict = {}
    mes_dict: dict = {}
    def_actual_dict: dict = {}
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, fru_list = get_parameter(xml_config)
    for _index_case, fru_single_case in enumerate(fru_list):
        relation_dict[fru_single_case['type']] = _index_case
    os.chdir(WorkPath)
    main()
