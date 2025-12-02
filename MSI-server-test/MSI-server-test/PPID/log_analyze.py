#!/usr/bin/env python3
# coding:utf-8
"""
针对制定路径下的log 进行检查，并判断是否符合上传条件,针对不同状况返回不同返回值
"""
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from subprocess import run, PIPE
from supports import *


def sorted_logs(log_list):
    """
    每次取其中一个跟其他所有log进行比较
    :param log_list:
    :return:
    """
    if len(log_list) == 1:
        return log_list[0], []
    __temp_list = []
    __newest_log = log_list[0]
    __temp_list.append(__newest_log)
    for item in log_list[1:]:
        # 列表格式：('20241109121512', 'OBE0000021', 'S38010N_O71B486680', 'D843AEA9FAF4', 'Node1')
        # 查找是同一块Node的板子,并以最后更新的一次作为记录,以便后续检查时间
        _duplicate_info = set(item[1:]) & set(__newest_log[1:])
        if len(_duplicate_info) == 4:
            __temp_list.append(item)
            if int(item[0]) > int(__newest_log[0]):
                __newest_log = item
        # 如果相同的项目在2～3个话,此是这两个条码 要么是更换了S368D,要么是在同一个Slot当中测试, 要么更换了主板
        # 此时应该通知PE处理
        if 1 < len(_duplicate_info) < 4:
            raise Exception(f"{item} 和 {__newest_log} 有部分项目{_duplicate_info}重复, 请请检查是否调换了主板,是否调换过小卡,"
                            f" 是否与其他Node 在同一个插槽进行测试, 再通知PE进行处理.")
    # 如果相同的项目不是4个话,判定不是同一个Node的测试log,此时单独记录
    log_list = list(set(log_list) - set(__temp_list))
    return __newest_log, log_list


def check_timestamp(log_info) -> bool:
    """
    将log的时间与现在运行的时间进行比对，在正常时间gap内，返回True，否则返回False
    log_info名称范例：[('20241113150650', 'OBE0000264', 'S38010N_O71B486649', 'D843AEA9FA32', 'Node2')]
    :param log_info: 需要解析时间的log info
    :return: bool
    """
    import datetime
    import textwrap
    _time_str = log_info[0]
    _time_list = textwrap.wrap(_time_str[4:], 2)
    _time_list.insert(0, _time_str[:4])
    _int_list = [int(item) for item in _time_list]
    _log_time = datetime.datetime(_int_list[0], _int_list[1], _int_list[2], _int_list[3], _int_list[4], _int_list[5])
    _cur_time = datetime.datetime.now()
    _gap_time = _cur_time - _log_time
    _gap_days = _gap_time.days
    _gap_secs = _gap_time.seconds
    if _gap_days < 1 and _gap_secs <= 86400:
        return True
    else:
        promptr(f"{log_info} 测试时间距离现在已经超过24小时...")
        return False


def analyze_logs(search_path):
    """
    在指定路径下将符合条件的log找出，并将每个Node的最新log记录下来，最后确认所有Node的测试记录数量与定义的Slot数量进行比较
    查找条件：a.log规格符合制定格式 b.系统条码与本机条码一致 c.时间规则,应该选取在功能维修站别之后时间测试的log
    :param search_path:
    :return: None
    """
    # 查询功能测试前一站的过站时间,如果测试log在此时间之前测试的,是无效的log.
    __cur_station_time = get_station_time(eps_web_site, SerialNumber)
    if __cur_station_time is None:
        raise Exception("未查询到上一站的过站时间...")
    pattern_str = '[0-9A-Z]+_(\d+)_([0-9A-Z]+)_(\w+)_([0-9A-F]{12})_(Node\d)'
    # _match_log_list 内为符合时间要求的所有log
    _match_log_list = []
    _sorted_log_list = []
    for file in os.listdir(search_path):
        _file_path = os.path.join(search_path, file)
        if os.path.isfile(_file_path) and (_search_res := re.search(pattern_str, file)) is not None:
            # ('20241109121512', 'OBE0000021', 'S38010N_O71B486680', 'D843AEA9FAF4', 'Node1')
            # _test_time, _search_sys_barcode, _search_mb_barcode, _search_mac, _search_Node = _search_res.groups()
            __temp_list = _search_res.groups()
            # 这里应该还要加入针对系统条码的判断,只考虑检查该系统条码对应的log时间,只有在比当前站别之后时间的板子才作为判断的依据
            if __temp_list[1] == SerialNumber and int(__temp_list[0]) > __cur_station_time:
                _match_log_list.append(__temp_list)
    # 去重,并针对每个Node 选取出最新测试的log
    _match_log_list = list(set(_match_log_list))
    while len(_match_log_list) > 0:
        _newest_log, _match_log_list = sorted_logs(_match_log_list)
        _sorted_log_list.append(_newest_log)
    # print(_sorted_log_list)
    if len(_sorted_log_list) == int(SlotNum):
        # 所有条码的测试时间都是在24内完成,系统条码上传
        if all(check_timestamp(__log_info) for __log_info in _sorted_log_list):
            exit(0)
        else:
            raise Exception(f"系统中不同Node的测试时间相差超过24小时, 不可以上传,请重测超过24小时的Node.")
    elif len(_sorted_log_list) < int(SlotNum):
        # 测试数量未达到, 提示,并正常退出.
        exit(2)
    else:
        # 数量超过指定数量, 如果置换主板有可能会出现此状况,此时请PE确认，可将置换的条码log删除
        raise Exception(f"实际找到{len(_sorted_log_list)}块模块测试log,超过限定数量{SlotNum},请联系PE 确认!")


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
    web_url = "http://20.20.0.30/mes.wip.webservice/ftservice.asmx"
    _function = '/GetBarcodeStationInfoByWipNo?sWipNo='
    url = ''.join([web_url, _function, work_order])
    web_res = urllib.request.urlopen(url, timeout=30).read().decode('utf-8')
    root = ET.fromstring(web_res)
    for globalcfg in root.iter(tag='NewDataSet'):
        for _table1 in globalcfg.iter(tag='Table1'):
            if _table1.find('BARCODENO').text == barcode:
                # print(_table1.find('CURRENTSTATIONID').text)
                cur_station_time = _table1.find('CURRENTSTATIODATE').text
                cur_station_time = cur_station_time.strip().replace('-', '').replace(' ', '').replace(':', '')
                if re.match('\d{14}', cur_station_time) is not None:
                    # print(cur_station_time)
                    return int(cur_station_time)
    return None


if __name__ == '__main__':
    # BackupSlotLogPath = /mnt/Slotlogs, MidModelName：机种名, SerialNumber：系统条码, SlotNum 总共要cover的slot数量
    BackupSlotLogPath, MidModelName, SerialNumber, SlotNum, eps_web_site = sys.argv[1:]
    log_path = os.path.join(BackupSlotLogPath, MidModelName, SerialNumber)
    # print(BackupSlotLogPath, MidModelName, SerialNumber, SlotNum, eps_web_site)
    # SerialNumber = 'OBE0000264'
    # SlotNum = 0
    # eps_web_site = "http://20.40.1.40/eps-web/upload/uploadservice.asmx"
    # print(BackupSlotLogPath, MidModelName, SerialNumber, SlotNum)
    # WorkPath = os.path.dirname(os.path.abspath(__file__))
    # BaseName = os.path.basename(__file__).split(".")[0]
    analyze_logs(log_path)