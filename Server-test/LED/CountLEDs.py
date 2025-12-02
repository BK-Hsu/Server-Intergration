#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: CountLEDs.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2023-10-26
# Update   : 2023-10-26
# Version  : 1.0.0
# Desription:
# 将主板上随即控制的LED和一直常量的LED数量进行检测，同时可对主板不同颜色的LED 数量进行确认
# 同时将定义同一脚本控制的LED 的数量调整为可变，不再固定为1个，增加灵活性
# 如果所有LED 都是不可控的，只测试一次检查所有LED 点亮的数量和不同颜色的个数（可选）
# Change list:
# 2023-10-26: First Release
# 2024-07-16: 调整脚本模板，针对LED 颜色数量的逻辑调整
# ------------------------------------------------------------------------------------
"""
from supports import *
import os
import sys
from subprocess import run, Popen
from random import sample, randint
AP_version = "1.1.0"


class LED:
    """
    创建一个LED 类，属性：位置，方法（如果没有方法的情况下，不执行打开或者关闭LED 动作，根据定义的数量返回）：
    <config location="LED1" control_way="null" control_num="3"/>
    """
    def __init__(self, location, control_way, control_num):
        self.location = location
        self.control_way = control_way
        if self.control_way == "":
            self.light_num = int(control_num)
        else:
            self.light_num = int(control_num)

    def light_led(self):
        run(["bash", self.control_way, '1'])

    def light_led1(self):
        Popen(["bash", self.control_way, '1'])

    def turnoff_led(self):
        run(["bash", self.control_way, '0'])


# 获取xml配置档案
def get_parameter(xml_config_path: str) -> tuple[dict, list]:
    import xml.etree.ElementTree as ET
    this_case = None
    _config: dict = {}
    _led_list: list = []
    tree = ET.ElementTree(file=xml_config_path)
    root = tree.getroot()
    for program in root.iter(tag='TestCase'):
        for c in program.iter(tag="ProgramName"):
            if c.text == BaseName:
                this_case = program
    if this_case is None:
        fail_action("未找到对应xml 配置")
    for d in this_case.iter(tag='led_list'):
        _led_list = [x.attrib for x in d]
    _config['prompt_info'] = [x['location'] for x in _led_list]
    _config['ErrorCode'] = this_case.find("ErrorCode").text
    _config['ColorCount'] = this_case.find('ColorVerify').attrib
    _config['MarkedWords'] = this_case.find("MarkedWords").text
    return _config, _led_list
    

def test_sequence(test_list):
    """
    取LED测试总数的一半作为基数，如果LED 数量少于4个，则第一次从0～3 里面选取随机数
    如果LED 数量大于等于4个，则第一次从一半减一到一半加一之间选随机数
    """
    global control_test
    temp_num = len(test_list) // 2
    if temp_num < 2:
        temp_num1 = randint(0, len(test_list))
        round1_list = sample(test_list, temp_num1)
        left_list = list(set(test_list) - set(round1_list))
        round2_list = left_list + sample(round1_list, randint(0, len(round1_list)))
    else:
        temp_num1 = randint(temp_num - 1, temp_num + 1)
        round1_list = sample(test_list, temp_num1)
        round2_rand = 2 if temp_num1 >= 2 else len(round1_list)
        left_list = list(set(test_list) - set(round1_list))
        # round1_list = sample(ledtest_list, temp_num1)
        round2_list = left_list + sample(round1_list, randint(0, round2_rand))
    if len(round1_list) + len(round2_list) == 0:
        control_test = False
    return round1_list, round2_list


def show_msg(show_list):
    prompty("*" * 68)
    prompty("%-11s%s% 9s" % ("**", "若發現LED點亮的數量和輸入的確實不符,請轉入維修站", "**"))
    prompty("%-11s%s% 10s" % ("**", "觀察以下指定位置上的LED燈並按要求輸入點亮的個數", '**'))
    n = 1
    while n <= len(show_list):
        if len(show_list) % 2 == 1 and n == len(show_list):
            prompty("%-11s%-46s%s" % ('**', "<{}>".format(n) + show_list[n - 1], '         **'))
        else:
            prompty("%-11s%-23s%-23s%s" % (
                '**', '<{}>'.format(n) + show_list[n - 1], "<{}>".format(n + 1) + show_list[n], '         **'))
        n += 2
    prompty("*" * 68)


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
        <ProgramName>CountLEDs</ProgramName>
        <ErrorCode>TXLE9|LED NO Function</ErrorCode>
        <!--程式將隨機點亮受控LEDs,然後和常亮LEDs計數測試-->
        <!--使用該程式的時候,以下這些LEDs應該比較集中在一起,顏色測試不能100%防止錯料-->
        <MarkedWords>請觀察JFP1面板上的以下LEDs,填入點亮的數量</MarkedWords>
        <!--顏色數量確認測試,將所有的LED點亮後詢問各顏色數量是多少,全部置0不檢查顏色-->
        <ColorVerify red="1" green="2" blue="1" orange="0"/>
        <led_list>
            <config location="JLED1_Middle" control_way="/TestAP/LED/HDD_LED.sh" control_num="2"/>
            <config location="JLED1_DOWN" control_way="/TestAP/LED/STATUS_LED.sh" control_num="1"/>
            <config location="F_PANEL_PWR" control_way="" control_num="1"/>
            <config location="JLED1_UP" control_way="" control_num="1"/>
            <config location="PWR_BTN1" control_way="" control_num="1"/>
        </led_list>
    </TestCase>
    """
    sys.exit(1)


def main():
    led_test_list = []
    alwayson_num = 0
    for i in range(len(led_list)):
        locals()[f'led{i}'] = LED(led_list[i]['location'], led_list[i]['control_way'], led_list[i]['control_num'])
        # print(locals()[f'led{i}'].control_way)
        if locals()[f'led{i}'].control_way == "":
            alwayson_num += locals()[f'led{i}'].light_num
            continue
        led_test_list.append(locals()[f'led{i}'])
    test_rounds = test_sequence(led_test_list)
    # 1 和 0的状态都需要测试一次，如何进行控制，要将常亮的LED 从列表中剔除，这样再随即控制其他的LED
    # 如果可控LED的数量为0， 则直接询问LED的数量，不再另外执行2次随机测试
    for item in test_rounds:
        show_msg(config['prompt_info'])
        lightled_total = alwayson_num
        for led_case in item:
            led_case.light_led1()
            lightled_total += led_case.light_num
        user_input1 = int(input("\033[1;33m{} : \033[0m".format(config['MarkedWords'])))
        if lightled_total != user_input1:
            for led_case in item:
                led_case.turnoff_led()
            fail_action(f"人员输入数量为{user_input1}, 实际点亮的LED数量是 {lightled_total},请确认")
        else:
            processpass("LED 点亮数量是 %s" % lightled_total)
            for led_case in item:
                led_case.turnoff_led()
        # 如果没有随即控制的LED，只有一直常量的LED，control_test 为False,确认完一次LED 数量后退出
        if not control_test:
            break

    # 检查LED不同颜色的数量，不要要求与LED 的数量一致，根据定义来判断，同时此项目应该为可选项
    color_define = config['ColorCount']
    check_num = 0
    for i in color_define.values():
        check_num += int(i)
    if check_num != 0:
        prompty("将会点亮所有LED, 请确认不同颜色LED 的数量...")
        for item in led_test_list:
            item.light_led1()
        color_show = {'red': '\033[1;31m红色\033[0m', 'green': '\033[1;32m绿色\033[0m',
                      'orange': '\033[1;33m橙色或琥珀色\033[0m', 'blue': '\033[1;34m蓝色\033[0m'}
        for color_set, color_num in color_define.items():
            if int(color_num) != 0:
                color_count = int(input("请输入{}LED灯的数量 : ".format(color_show[color_set])))
                if int(color_num) != int(color_count):
                    # print("亮{}LED的正确数量是 {}".format(color_show[color_set], int(color_num)))
                    for item in led_test_list:
                        item.turnoff_led()
                    fail_action("{}LED的数量确认Fail,正确应为{},实际输入为{}".format(color_show[color_set], color_num, color_count))
                else:
                    processpass("{}LED的数量是 {}".format(color_show[color_set], int(color_num)))
        for item in led_test_list:
            item.turnoff_led()


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3311.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    os.chdir(WorkPath)
    config, led_list = get_parameter(xml_config)
    control_test = True
    main()
    echopass("LED 测试")
    sys.exit(0)
