#!/usr/bin/env python3
# -*- coding:utf-8 -*-
"""
# -----------------------------------------------------------------------------------
# File Name: supports.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2022-04-21
# Update   : 2023-07-05
# Version  : 1.0.1
# Desription:
# 提供功能测试辅助模块，不同颜色的显示提示， raise Exception 类重写，argparser类应用
# Change list:
# 2022-04-21: First Release
# 2023-07-05 增加argparser 模块，新增AutoTestFail模块（重写Exception 类）ver升级到1.0.1
# ------------------------------------------------------------------------------------
"""
AP_version = '1.0.1'

import os
import sys
import argparse
import re

if sys.platform == "win32":
    os.system('')
__all__ = ['echopass', 'echofail', 'prompty', 'promptg', 'promptr', 'parser_argv',
           'showmsg', 'processpass', 'processfail', 'AutoTestFail', 'beepremind']
ErrorCode_file = "/TestAP/PPID/ErrorCode.TXT"


def echopass(msg):
    print("\033[1;32m{} {} [ PASS ]\033[0m".format(msg, '-' * (70 - len(msg))))


def echofail(msg):
    print("\033[1;31m{} {} [ FAIL ]\033[0m".format(msg, '-' * (70 - len(msg))))
    beepremind(1)


def prompty(msg):
    print("\033[1;33m{} \033[0m".format(msg))


def promptr(msg):
    print("\033[1;31m{} \033[0m".format(msg))


def showmsg(list):
    print("\033[0;30;43m%-72s \033[0m" % ("*" * 72))
    for msg in list:
        print("\033[0;30;43m%-8s%-56s%8s\033[0m" % ("**  ", msg, "  **"))
    print("\033[0;30;43m%-72s \033[0m" % ("*" * 72))


def promptg(msg):
    print("\033[1;32m{} \033[0m".format(msg))


def processpass(msg):
    print("\033[1;32m[  OK  ]\033[0m  {}".format(msg))


def processfail(msg):
    print("\033[1;31m[  NG  ]\033[0m  {}".format(msg))


def beepremind(status):
    os.system('lsmod | grep -iq "pcspkr" || modprobe pcspkr')
    if status == 0:
        os.system('beep -f 1800 > /dev/null 2>&1')
    else:
        os.system('beep -f 800 -l 800 > /dev/null 2>&1')


class AutoTestFail(Exception):
    def __init__(self, code, path, msg="", context=""):
        self.code = code
        self.msg = msg
        self.context = context
        self.path = path
        with open(ErrorCode_file, 'a+', encoding='utf-8') as f:
            if self.code not in f.read():
                f.write(self.code + "|" + os.path.basename(self.path) + "\n")

    def __str__(self):
        return "AutoTest failed with exception {}".format(self.msg)


def GetXmlPath():
    xmlpath = "/TestAP/Config/"
    for path, dirs, files in os.walk(xmlpath):
        if path == xmlpath:
            for file in files:
                if re.match("MS-.*.xml", file):
                    return os.path.join(path, file)
    return None

def parser_argv(AP_version, TestMode='SerialTest'):
    # 当未指定xml名字时使用默认路径下的xml
    xml_file = GetXmlPath()
    # 显示使用方法
    parser = argparse.ArgumentParser()
    # -x 后面带xml档案路径或者是后续json 的路径
    parser.add_argument('-x', nargs='?', default=xml_file, help='The parameter should be xml or json file')
    # -p 代表目前Paralle 测试设定，如果-p， 默认值为打印parallel
    parser.add_argument('-p', '-P', action='store_const', const=TestMode, help='Serial Test or Parallel Test mode')
    # -v 默认显示程式版本
    parser.add_argument('-v', '--v', action='version', version='%(prog)s {}'.format(AP_version))
    params = parser.parse_args()
    if params.p is not None:
        print(params.p)
        sys.exit(1)
    return params.x


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    if os.path.exists(xml_config):
        print(xml_config)

