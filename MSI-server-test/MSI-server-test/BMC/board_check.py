#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: board_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-09-05
# Update   : 2024-12-20
# Version  : 1.0.1
# Description:
# 1.检查待测试机器是否已经有log在临时服务器上，该测试机台与系统条码是否匹配，并且测试时间与现在的时间是否相差24小时以内，
# 2.如果时间超过24小时，重新测试，如果在24小时以内，说明该log已经测试过，则无需重复测试
# 3.在执行此动作之前,需要先判断目前的S368D的MAC号，和S3801的主板条码是否对应这个系统条码
# Change list:
# 2024-09-05: First Release
# 2024-12-20：增加Node 检测及板子过站时间检测,来检查板子是否进维修或者测试后重工返回上一站后重新流线
# -----------------------------------------------------------------------------------
"""
import os
import sys
import re
import time
import urllib.request
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
        <ProgramName>board_check</ProgramName>
        <config name="ErrorCode" value="TXS97|fru info check fail"/>
        <config name="ftp_ip" value="20.40.1.41"/>
        <config name="ftp_dir" value="eps-pe/SlotTestLog"/>
        <config name="ftp_username" value="epspe"/>
        <config name="ftp_password" value="epsips"/>
        <config name="mount_local" value="/mnt/Slotlogs"/>
        <config name="ppid_file" value="/TestAP/PPID/PPID.TXT"/>
        <config name="node_id_file" value="/TestAP/PPID/Node_ID.TXT"/>
        <!--获取node的方式, 设定为bmc, 通过BMC读取获取node id,scan通过扫描获取id-->
        <config name="get_node" value="bmc"/>
        <config name="mac_save_path" value="/TestAP/PPID/"/>
        <config name="get_mb_barcode" value="fru"/>
        <config name="mb_barcode_path" value="/TestAP/PPID/mb_ppid.txt"/>
        <config name="WebSite" value="http://20.40.1.40/eps-web/upload/uploadservice.asmx"/>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> dict:
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
    return _config


def mes_mac(web_target, src_file):
    """
    通过系统条码查询MAC号，并将MAC 记录在列表当中
    :param web_target: mes查询网页链接地址
    :param src_file: 供查询的source_file
    :return: 返回查询到的MAC list
    """
    if not os.path.exists(src_file):
        fail_action(f"{src_file} not found")
    with open(src_file, 'r', encoding='utf-8') as f:
        _ppid = f.read().strip()
    cmd_format = f'mes {web_target} 8 "sBarcode={_ppid}" 2>/dev/null'
    _res = run(cmd_format, shell=True, stdout=PIPE, encoding='utf-8')
    if _res.returncode != 0:
        fail_action(f"{cmd_format} 查询结果失败,请检查格式及网络是否正常")
    _res_detail = _res.stdout.splitlines()[1].strip()
    mes_data = _res_detail.replace('&lt;', '<').replace('&gt;', '>')
    tree = ET.fromstring(mes_data)
    mac_list = [mac_case.text for mac_case in tree.iter(tag='MAC')]
    if len(mac_list) == 0:
        fail_action("Not find any MAC address")
    # print(mac_list)
    return mac_list


def get_barcode_by_component(web_target, mb_barcode):
    cmd_format = f'mes {web_target} 6 "sComponentNo={mb_barcode}" 2>/dev/null'
    _res = run(cmd_format, shell=True, stdout=PIPE, encoding='utf-8')
    if _res.returncode != 0:
        fail_action(f"{cmd_format} 查询结果失败,请检查格式及网络是否正常")
    _res_detail = _res.stdout.splitlines()[1].strip()
    if len(_res_detail) == 0 or "Can not find the barcode" in _res_detail:
        fail_action(f"mes 查询到的条码为空！")
    return _res_detail
    

def get_mb_ppid_by_fru():
    """
    从fru中读取到烧录的PCBA 主板条码
    :return: 从FRU中读取的PCBA 主板条码
    """
    _mb_barcode = None
    _fru_res = run("ipmitool fru print 0", shell=True, stdout=PIPE, encoding='utf-8')
    for line in _fru_res.stdout.splitlines():
        if "Board Serial" in line:
            _mb_barcode = line.split(" : ")[-1].strip()
    if _mb_barcode is None:
        fail_action("FRU中未发现主板条码信息...,请输入ipmitool fru print 0查看")
    return _mb_barcode


def get_node_id():
    # local node number,最后返回格式为Node1
    __node_id = None
    get_node_res = run("ipmitool raw 0x28 0xa2 0x21 2>/dev/null", shell=True, stdout=PIPE, encoding='utf-8')
    if get_node_res.returncode == 0 and get_node_res.stdout.strip().isdigit():
        __node_num = int(get_node_res.stdout.strip())
        __node_id = "Node" + str(__node_num)
        with open(config['node_id_file'], 'w', encoding='utf-8') as f:
            f.write(__node_id)
        return __node_id
    if __node_id is None:
        fail_action("未获取到Node ID相关信息")


def compare_sys_barcode():
    """
    透过主板条码查询MES 组装系统条码，主板条码可以通过扫描或者FRU中获取
    此条码将会与扫描的系统条码进行比对，如果比对FAIL,会直接FAIL
    如果PASS，将主板条码储存在PPID下，用作比对及上传时使用
    :return:None
    """
    if config['get_mb_barcode'] == "scan":
        if not os.path.exists(mb_barcode_path):
            fail_action(f"主板文件{mb_barcode_path} 未找到,请确认！")
        with open(mb_barcode_path, 'r', encoding='utf-8') as f:
            mb_barcode = f.read().strip()
    else:
        mb_barcode = get_mb_ppid_by_fru()
    if re.match('\w{10,18}', mb_barcode) is None:
        fail_action(f"获取到的主板条码{mb_barcode}格式错误!")
    mes_barcode = get_barcode_by_component(web_url, mb_barcode)
    with open(ppid_file, 'r', encoding='utf-8') as f:
        _sys_barcode = f.read().strip()
    if mes_barcode == _sys_barcode:
        with open(mb_barcode_path, 'w', encoding='utf-8') as f1:
            f1.write(mb_barcode)
    else:
        fail_action(f"系统条码{_sys_barcode} 与主板条码{mb_barcode} 不对应,请检查！")


def compare_mac() -> None:
    """
    通过从本机读取其中的两个MAC号，与通过系统条码查询出来的MES记录MAC号进行比对，如果比对正确，将MLAN 的MAC号，作为log的标志存储在PPID下
    比对的结果格式化打印出来，此程式将顺便完成BMC MAC的比对
    :return:None
    """
    channel_list = ["1", "8"]
    _check_mac_flag: int = 0
    mac_save_path = config['mac_save_path']
    mac_pool = mes_mac(web_url, ppid_file)
    for _index, _channel in enumerate(channel_list):
        mac_shell = f"ipmitool lan print {_channel} | grep 'MAC Address' | head -n1 | cut -c 27-43 | tr -d ': ' | tr [a-z] [A-Z]"
        _cur_mac = run(mac_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
        if re.match('^[0-9a-fA-F]{12}', _cur_mac) is not None and _cur_mac in mac_pool:
            processpass(f"Check BMC Channel {_channel} MAC address {_cur_mac}")
            _save_file = os.path.join(mac_save_path, f"BMCMAC{_index + 1}.TXT")
            with open(_save_file, 'w', encoding='utf-8') as f:
                f.write(_cur_mac)
        else:
            processfail(f"Check BMC Channel {_channel} MAC address fail, current MAC is {_cur_mac}, not in {mac_pool}")
            _check_mac_flag += 1
    if _check_mac_flag != 0:
        fail_action("BMC MAC Check FAIL!!!")


def con2server():
    _try_times: int = 0
    while _try_times <= 3:
        _res = run("ping 20.40.0.1 -c 2 -w 3", shell=True, stdout=PIPE, encoding='utf-8')
        if _res.returncode != 0:
            for _line in _res.stdout.splitlines():
                print(_line)
            promptr(f"Ping 网检查Fail, 请检查网络连接及设定是否正确")
            _try_times += 1
            input("请检查网络连接，确认正常后，请回车继续测试...")
            continue
        else:
            processpass("网络连接")
            break
    if _try_times > 3:
        fail_action("网络连接异常，请检查网络是否正常连接")


def mount_ftp():
    ftp_ip = config['ftp_ip']
    ftp_dir = config['ftp_dir']
    ftp_username = config['ftp_username']
    ftp_password = config['ftp_password']
    mount_local = config['mount_local']
    retry_time: int = 0
    while retry_time < 3:
        if not os.path.exists(mount_local):
            os.mkdir(f'{mount_local}')
        mount_shell = f"mount -t cifs //{ftp_ip}/{ftp_dir}/ -o username={ftp_username},password={ftp_password},vers=1.0 {mount_local}"
        # print(mount_shell)
        if run(mount_shell, shell=True, encoding='utf-8').returncode == 0:
            processpass(f"Mount //{ftp_ip}/{ftp_dir}/")
            time.sleep(1)
            break
        else:
            prompty(f"Mount //{ftp_ip}/{ftp_dir}/ Fail, will try again, please wait for a moment....")
            os.system(f"umount {mount_local} >/dev/null 2>&1")
            retry_time += 1
            time.sleep(1)
    if retry_time == 3:
        processfail(f"Mount //{ftp_ip}/{ftp_dir}/")
        os.system(f"umount {mount_local} >/dev/null 2>&1")
        return False
    return True


def get_work_order(web_target, src_barcode):
    """
    通过系统条码查询MAC号，并将MAC 记录在列表当中
    :param web_target: mes查询网页链接地址
    :param src_barcode: 供查询的source_barcode,此处为系统条码
    :return: 返回查询到的工单号
    """
    cmd_format = f'mes {web_target} 5 "sBarcode={src_barcode}" 2>/dev/null'
    _res = run(cmd_format, shell=True, stdout=PIPE, encoding='utf-8')
    if _res.returncode != 0:
        raise Exception(f"{cmd_format} 查询结果失败,请检查格式及网络是否正常")
    _res_detail = _res.stdout.splitlines()[1].strip()
    if re.match('\w{10}', _res_detail) is None:
        promptr(f"查询工单信息错误：{_res_detail}")
    return _res_detail


def get_station_time(web_target, barcode):
    work_order = get_work_order(web_target, barcode)
    # web_url1 是IT 端web 服务器
    web_url1 = "http://20.20.0.30/mes.wip.webservice/ftservice.asmx"
    _function = '/GetBarcodeStationInfoByWipNo?sWipNo='
    url = ''.join([web_url1, _function, work_order])
    web_res = urllib.request.urlopen(url, timeout=30).read().decode('utf-8')
    root = ET.fromstring(web_res)
    for globalcfg in root.iter(tag='NewDataSet'):
        for _table1 in globalcfg.iter(tag='Table1'):
            if _table1.find('BARCODENO').text == barcode:
                # print(_table1.find('CURRENTSTATIONID').text)
                cur_station_time = _table1.find('CURRENTSTATIODATE').text
                cur_station_time = cur_station_time.strip().replace('-', '').replace(' ', '').replace(':', '')
                if re.match('\d{14}', cur_station_time) is not None:
                    print(cur_station_time)
                    return int(cur_station_time)
    return None


def check_logs():
    # log 格式FT_20240829115829_O6E0000001_S368M0N_O81B273505_047C11223344_Node1,站别_时间_条码_网络号(主板条码)
    log_files = []
    if not mount_ftp():
        fail_action("挂载log服务器失败，请检查网络及设定")
    model_file = "/TestAP/PPID/MODEL.TXT"
    if not os.path.exists(model_file):
        fail_action(f"Not find {model_file} file, please run GetMDL.sh before this item!")
    with open(model_file, 'r', encoding='utf-8') as f:
        model_name = f.read().strip().split("-")[1]
    with open(ppid_file, 'r', encoding='utf-8') as f:
        sys_barcode = f.read().strip()
    with open('/TestAP/PPID/BMCMAC1.TXT', 'r', encoding='utf-8') as f1:
        S368D_MAC = f1.read().strip()
    with open(mb_barcode_path, 'r', encoding='utf-8') as f2:
        _mb_barcode = f2.read().strip()
    # 如果是扫描选择的Node_ID, 需要从文件中获取到，bmc获取的，直接通过bmc读取
    if config['get_node'] == 'bmc':
        _local_node_id = get_node_id()
    else:
        with open(config['node_id_file'], 'r', encoding='utf-8') as node_f:
            _local_node_id = node_f.read().strip()
    __cur_station_time = get_station_time(web_url, sys_barcode)
    if __cur_station_time is None:
        fail_action("未查询到上一站的过站时间...")
    # log_path 的路径应该是/mnt/Slotlogs/S380/O6E0000001
    log_path = os.path.join(config['mount_local'], model_name, sys_barcode)
    # 如果还没测试，此时应该还没有路径出来，此时直接返回True
    if not os.path.exists(log_path):
        print(log_path)
        return False
    _cur_board_info = [sys_barcode, _mb_barcode, S368D_MAC, _local_node_id]
    # pattern_str = '[0-9A-Z]+_\d+_([0-9A-Z]+)_(\w+)_([0-9A-F]{12})'
    pattern_str = '[0-9A-Z]+_(\d+)_([0-9A-Z]+)_(\w+)_([0-9A-F]{12})_(Node\d)'
    for file in os.listdir(log_path):
        _file_path = os.path.join(log_path, file)
        if os.path.isfile(_file_path) and (_search_res := re.search(pattern_str, file)) is not None:
            _board_info = _search_res.groups()
            # _search_sys_barcode, _search_mb_barcode, _search_mac = _search_res
            # 这里应该还要加入针对系统条码的判断,只考虑检查该系统条码对应的log时间,只有在比当前站别之后时间的板子才作为判断的依据
            if _board_info[1] == sys_barcode and int(_board_info[0]) > __cur_station_time:
                _duplicate_info = set(_cur_board_info) & set(_board_info[1:])
                if len(_duplicate_info) == 4:
                    log_files.append(file)
                # 如果MAC和组装条码中有一个与之前测试的log相同，但是另一个不相同,则说明可能更换过小卡或者重烧过MAC
                # 此时系统匹配上不对应,应该禁止测试,给予提示信息,请人员检查
                # 目前此操作交由PE 来判断是否删除log还是重新测试
                elif 1 < len(_duplicate_info) < 4:
                    fail_action(f"此Node测试对应信息{_cur_board_info} 与已经测试过的Node 有如下信息重复{_duplicate_info}"
                                f"请检查是否调换了主板,是否调换过小卡, 是否与其他Node 在同一个插槽进行测试, 再通知PE进行处理.")
            elif _board_info[1] != sys_barcode:
                fail_action(f"{log_path} 路径下储存的log条码{_board_info[1]} 与实际测试条码{sys_barcode}不同")
    # 如果没有找到log，则继续正常返回开始测试，如果已经找到1个log，并且log的时间符合条件，则退出测试，如果不符合条件，并继续正常测试
    # 如果找到多个log，则每个log 都正常判断，只要其中有一个log的时间符合要求，则退出测试，如果都不符合的话，则继续正常测试
    if len(log_files) == 0:
        return False
    if any(check_timestamp(log_file) for log_file in log_files):
        return True
    else:
        return False


def check_timestamp(logfile: str) -> bool:
    """
    将log的时间与现在运行的时间进行比对，在正常时间gap内，返回True，否则返回False
    log名称范例：FT_20240903104852_06E0000001_D843AEA9FBDA.log
    :param logfile: 需要解析时间的log file名称（其名称内有当时上传的时间）
    :return: bool
    """
    import datetime
    import textwrap
    _time_str = logfile.split("_")[1]
    _time_list = textwrap.wrap(_time_str[4:], 2)
    _time_list.insert(0, _time_str[:4])
    _int_list = [int(item) for item in _time_list]
    _log_time = datetime.datetime(_int_list[0], _int_list[1], _int_list[2], _int_list[3], _int_list[4], _int_list[5])
    _cur_time = datetime.datetime.now()
    _gap_time = _cur_time - _log_time
    _gap_days = _gap_time.days
    _gap_secs = _gap_time.seconds
    # 如果测试log超过24小时, 则需要重新测试，不认可其为可接受的log
    if _gap_days <= 0 and _gap_secs <= 86400:
        return True
    else:
        return False


def main():
    con2server()
    # 确认测试机台BMC MAC是否与系统一致
    compare_mac()
    # 确认主板条码与系统条码是否对应
    compare_sys_barcode()
    # 检查该机器是否已经测试过,是否需要重新测试
    if not check_logs():
        print("这个模块没有测试过，或者测试间隔时间超过24小时，将重新测试")
        sys.exit(0)
    else:
        while True:
            user_ans = input("这个模块已经测试过，请确认是否重新测试，输入Y|y将重新测试，输入N|n 将退出测试： ")
            if user_ans.lower() == "y":
                sys.exit(0)
            elif user_ans.lower() == 'n':
                sys.exit(1)
            else:
                prompty("输入选项错误，请重新输入！")
                continue


if __name__ == '__main__':
    # serial_number = "O6E0000001"
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config = get_parameter(xml_config)
    web_url = config['WebSite']
    ppid_file = config['ppid_file']
    mb_barcode_path = config['mb_barcode_path']
    if not os.path.exists(ppid_file):
        fail_action(f"未找到系统条码文件{ppid_file},请检查！")
    main()



