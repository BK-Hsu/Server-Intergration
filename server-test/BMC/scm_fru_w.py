#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: mcu_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-12-12
# Update   : 2024-12-12
# Version  : 1.0.0
# Description :
# 通过BMC smbus 读取MCU上FW APROM和LDROM version
# Change list:
# 2024-12-12: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import time
from subprocess import run, PIPE
from supports import *

AP_version = "1.0.0"



if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    # xml_config = "MS-S3361.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    flash_cmd = "ipmitool raw 0x28 0x52 14 0xa4 0 0x60 0 0 0 0 0 0 0 0 0 0 0 0 0 2>/dev/null"
    print(flash_cmd)
    res1 = run(flash_cmd, shell=True, stdout=PIPE, encoding='utf-8')
    if res1.returncode != 0:
    	promptr("SCM FRU flash fail")
    	raise Execption("SCM FRU flash fail")
    echopass("SCM FRU flash")
    sys.exit(0)
