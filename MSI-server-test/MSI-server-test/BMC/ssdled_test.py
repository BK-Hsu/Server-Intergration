#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: ssdled_test.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-07-01
# Update   : 2024-07-01
# Version  : 1.0.0
# Description :
# 主要实现通过mg9200 寄存器控制实现对硬盘背板卡上LED 的控制，主要控制0x40 绿色，0x44（红色&蓝色），同时实现Blink 功能的确认
# 单独验证时，需要确认LED 点亮位置与SSD 位置是否对应
# 目前ipmitool raw 写入指令存在bug，会报错，但是实际已经执行成功，待后续bug fix 后修改模板，目前方式为先写入，然后再读取状态，确保指令有执行
# Change list:
# 2024-07-01: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import time
from subprocess import run, PIPE
import subprocess
import random
from random import choice
import xml.etree.ElementTree as ET
from supports import *
AP_version = "1.0.0"


class MG9200:
    def __init__(self, smbus_addr, led_num):
        self.smbus_addr = smbus_addr
        self.led_num = int(led_num)

    def bin2_str1(self) -> str:
        """
        产生一个随机的二进制字符串，最低数量为总数/2,数量小于3时,取值范围为1-2, 其他的总数/2～总数/2+ 总数/4 + 1
        :return:
        """
        __start_num = int(self.led_num / 2)
        if __start_num <= 1:
            __data_length = 2
        else:
            __data_length = int(__start_num / 2) + 1
        rand_num1 = choice(list(range(__start_num, __start_num + __data_length)))
        while True:
            bin_list = [choice(["0", "1"]) for i in range(self.led_num)]
            if bin_list.count("1") == rand_num1:
                return "".join(bin_list)

    def bin2_str2(self) -> tuple[dict, dict]:
        bin_data1 = self.bin2_str1()
        def_num = int("".join(["1" for _i in range(self.led_num)]))
        bin_value1 = def_num - int(bin_data1)
        bin_value1 = str(bin_value1).zfill(self.led_num)
        if self.led_num <= 3:
            bin_data2 = bin_value1.replace("0", "1", random.randint(0, 1))
        else:
            bin_data2 = bin_value1.replace("0", "1", random.randint(0, 2))
        _hex_str1 = hex(int(bin_data1, 2))
        _hex_str2 = hex(int(bin_data2, 2))
        return {'hex_str': _hex_str1, 'led_cnt': bin_data1.count("1")}, {'hex_str': _hex_str2, 'led_cnt': bin_data2.count("1")}
        # return _hex_str1, _hex_str2, bin_data1.count("1"), bin_data2.count("1")

    def led_manual(self):
        # 切换手动控制LED点亮,此时才能由BMC 控制LED 点亮
        _manual_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x3c 0xff 2>&1 >/dev/null"
        run_shell(_manual_cmd)

    def led_auto(self):
        # 切换自动控制，由MG9200自行控制LED
        _auto_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x3c 0x00 2>&1 >/dev/null"
        run_shell(_auto_cmd)

    def led_init(self):
        # 初始化LED的状态
        _init_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x45 0xff 2>&1 >/dev/null"
        run_shell(_init_cmd)

    def led_off(self, color_code):
        off_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x{color_code} 0x00 2>&1 >/dev/null"
        run_shell(off_cmd)

    def led_all_on(self, color_code):
        all_on_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x{color_code} 0xff 2>&1 >/dev/null"
        run_shell(all_on_cmd)

    def led_on(self, color_code, hex_str):
        on_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x{color_code} {hex_str} 2>&1 >/dev/null"
        run_shell(on_cmd)

    def led_debug_on(self, color_code):
        __on_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 {color_code} 2>&1 >/dev/null"
        run_shell(__on_cmd)

    def led_exit_debug(self):
        __exit_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0 0x58 0 2>&1 >/dev/null"
        run_shell(__exit_cmd)


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
        <ProgramName>ssdled_test</ProgramName>
        <config name="ErrorCode" value="NXRD4|Backplane LED fail"/>
        <config name="command_type" value="raw_type"/>
        <config name="raw_type" value="ipmitool raw 0x38 0x52"/>
        <config name="stop_scan" value="ipmitool raw 0x38 0x41 1 0 2>/dev/null"/>
        <config name="start_scan" value="ipmitool raw 0x38 0x41 1 1 2>/dev/null"/>
        <config name="i2c_bus" value="4"/>
        <switch_mg9200>
            <step mux_addr="e0" mux_channel="02"/>
            <step mux_addr="e8" mux_channel="02"/>
        </switch_mg9200>
        <switch_fru>
            <step mux_addr="e0" mux_channel="02"/>
            <step mux_addr="e8" mux_channel="01"/>
        </switch_fru>
        <portlist>
            <port bus="c0" led_num="8"/>
        </portlist>
    </TestCase>
    """
    sys.exit(1)


def get_parameter(xml_path: str) -> tuple[dict, list[dict], list[dict], list[dict]]:
    this_case = None
    _config = {}
    _port_list: list[dict] = []
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
    _port_list = [item.attrib for item in this_case.iter(tag='port')]
    return _config, _port_list, _switch_mg9200, _switch_fru


def led_blink_test(test_list: list[MG9200], blink_set: list[dict]):
    from random import sample
    for item in sample(blink_set, 2):
        for led_test in test_list:
            # 切换手动控制模式
            led_test.led_manual()
            # 初始化LED状态
            led_test.led_init()
            # 控制blink
            led_test.led_on(item['code'], "0xff")
        user_input = int(input("\033[1;33m请输入SSD LED闪烁的颜色, 绿色输入1, 红色输入2: \033[0m"))
        print(f"User Input the number is {user_input}, the right code is {item['ans_code']}")
        if user_input != item['ans_code']:
            for _led_test in test_list:
                _led_test.led_off(item['code'])
                _led_test.led_auto()
            echofail(f"{item['prompt']} LED Blink check")
            fail_action("SSD LED Blink Check")
        for _led_test in test_list:
            _led_test.led_off(item['code'])
            # _led_test.led_auto()
    echopass("Backplane SSD LED Blink Check")


def led_single_color(test_list: list[MG9200], single_color: dict, led_parameter: list[dict]):
    light_num = 0
    for _led_test, hex_cnt in zip(test_list, led_parameter):
        # _led_test.led_off(single_color['code'])
        _led_test.led_on(single_color['code'], hex_cnt['hex_str'])
        light_num += hex_cnt['led_cnt']
    user_input = int(input("\033[1;33m请输入%sLED点亮的数量: \033[0m" % single_color["prompt"]))
    print(f"User Input the number is {user_input}, actual light on number is {light_num}")
    if user_input != light_num:
        for _led_test in test_list:
            _led_test.led_off(single_color['code'])
            _led_test.led_auto()
        echofail(f"{single_color['prompt']} LED check")
        fail_action("SSD LED check")


def led_count_test(test_list: list[MG9200], color_set: list[dict]):
    for color in color_set:
        hex_bin_list = []
        # 产生要控制的LED 的指令及数量
        for led_test in test_list:
            hex_bin_case = led_test.bin2_str2()
            hex_bin_list.append(hex_bin_case)
        for led_test in test_list:
            # 切换手动控制模式
            led_test.led_manual()
            # 初始化LED状态
            led_test.led_init()
        round1_parameter = [item[0] for item in hex_bin_list]
        round2_parameter = [item[1] for item in hex_bin_list]
        led_single_color(test_list, color, round1_parameter)
        led_single_color(test_list, color, round2_parameter)
        for led_test in test_list:
            led_test.led_off(color['code'])
    for led_test in test_list:
        led_test.led_auto()
    echopass("Backplane SSD LED Check")


def debug_count_test(test_list: list[MG9200], color_set: list[dict]):
    for color in color_set:
        _debug_count = 0
        for led_test in test_list:
            led_test.led_debug_on(color['code'])
            _debug_count += led_test.led_num
        user_input = int(input("\033[1;33m请输入%sLED点亮的数量: \033[0m" % color["prompt"]))
        print(f"User Input the number is {user_input}, actual light on number is {_debug_count}")
        if user_input != _debug_count:
            for _led_test in test_list:
                _led_test.led_exit_debug()
            echofail(f"{color['prompt']} LED check")
            fail_action("SSD LED check")
    for _led_test in test_list:
        _led_test.led_exit_debug()
    echopass("Backplane SSD LED Check")


def main():
    global ipmi_command
    ipmi_command = create_command()
    stop_res = run_shell(config['stop_scan'])
    if stop_res.returncode != 0:
        fail_action("stop scan fail")
    if not switch_mux(ipmi_command, switch_mg9200):
        fail_action("切换Switch 通道Fail")
    color_set = [{"color": "Green", "code": "40", "prompt": "绿色"},
                 {"color": "Blue", "code": "44", "prompt": "蓝色"},
                 {"color": "Red", "code": "44", "prompt": "红色"}]
    blink_set = [{"color": "Green", "code": "40", "prompt": "绿色", "ans_code": 1},
                 {"color": "Red", "code": "46", "prompt": "红色", "ans_code": 2}]
    debug_set = [{"color": "Blue", "code": "0x58 3", "prompt": "蓝色"}]
    led_test_list: list[MG9200] = []
    for item in mg9200_port_list:
        mg9200_led = MG9200(item['bus'], item['led_num'])
        led_test_list.append(mg9200_led)
    led_blink_test(led_test_list, blink_set)
    led_count_test(led_test_list, color_set)
    debug_count_test(led_test_list, debug_set)
    run_shell(config['start_scan'])


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    ipmi_command = "ipmitool raw 0x38 0x52"
    # xml_config = "MS-S3351.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, mg9200_port_list, switch_mg9200, switch_fru = get_parameter(xml_config)
    main()
