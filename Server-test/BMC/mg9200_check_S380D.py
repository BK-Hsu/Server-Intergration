#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: mg9200_check.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-06-27
# Update   : 2024-06-27
# Version  : 1.0.0
# Description :
# 主要实现通过mg9200 寄存器控制实现1.SSD 状态侦测（0x28, 0x29,0x2a) 2.SGPIO/VPP/SHP/NPEM 状态侦测（0x24, 0x25, 0x26, 0x27， 0x2f）
# 3.对SSD 控制电源的方式来控制其进入睡眠模式 4.HW strap及soft 设定check(0x5c 对应参数0, 1, 2) 5. LED control测试
# 目前ipmitool raw 写入指令存在bug，会报错，但是实际已经执行成功，待后续bug fix 后修改模板，目前方式为先写入，然后再读取状态，确保指令有执行
# Change list:
# 2024-06-27: First Release
# -----------------------------------------------------------------------------------
"""
import os
import sys
import time
from subprocess import run, PIPE
import subprocess
import xml.etree.ElementTree as ET
from supports import *
AP_version = "1.0.0"


class MG9200:
    def __init__(self, smbus_addr, sata_register, nvme_register, e6_register, GPIO_VPP_register, strap_register, fru_fw, chipset_fw, cfru_checksum):
        self.nvme_dis_setting = None
        self.smbus_addr = smbus_addr
        self.sata_register = sata_register
        self.nvme_register = nvme_register
        self.e6_register = e6_register
        self.GPIO_VPP_register = GPIO_VPP_register
        self.strap_register = strap_register
        self.fru_fw = fru_fw
        self.cfru_checksum = cfru_checksum
        self.chipset_fw = chipset_fw
        if self.smbus_addr == "c0":
            self.slot_start_num = 1
        elif self.smbus_addr == "c2":
            self.lot_start_num = 9
        elif self.smbus_addr == "c4":
            self.slot_start_num = 17

    def nvme_detect(self):
        nvme_reading = self.read_register_value("0x3a")
        _detect_err_list: list = []
        _no_detect_list: list = []
        _error_flag: int = 0
        # 转换成二进制格式
        nvme_reading_bin = bin(int(nvme_reading, 16))[2:].zfill(8)
        for i in range(len(nvme_reading_bin)):
            if nvme_reading_bin[i] != (slot_bit := self.nvme_register[i]):
                if slot_bit == "0":
                    _detect_err_list.append(self.slot_start_num + 7 - i)
                elif slot_bit == "1":
                    _no_detect_list.append(self.slot_start_num + 7 - i)

        if len(_detect_err_list) != 0:
            promptr(f"硬盘卡 slot{_detect_err_list} 位置不应该插NVME SDD，请确认配备或检查接口P4 pin")
            _error_flag += 1
        if len(_no_detect_list) != 0:
            promptr(f"硬盘卡 slot{_no_detect_list} 位置未侦测到NVME SSD，请确认配备或检查接口P4 pin")
            _error_flag += 1
        if _error_flag == 0:
            self.nvme_dis_setting: tuple = (nvme_reading, nvme_reading_bin)
            echopass("NVME SSD detect")
        else:
            fail_action("NVME SSD detect")

    def nvme_dis_control(self, status):
        """
        此函数针对侦测到的NVME SSD 执行disable或者enable 操作，此程式需要在已经完nvme_check的前提下进行，
        通过对寄存器0x4f 位置写入对应的数值来执行disable 动作，每个bit 位写1 为disable，写0为enable
        :param status:status 为disable 或者enable， disable执行关闭， enable执行打开
        :return:None
        """
        if status == "disable":
            if self.nvme_dis_setting is None:
                self.nvme_register()
            nvme_control_reg = self.nvme_dis_setting[0]
        else:
            nvme_control_reg = "00"
        nvme_control_command = f"{ipmi_command} 0x{self.smbus_addr} 0 0x4f 0x{nvme_control_reg} 2>&1 >/dev/null"
        run(nvme_control_command, shell=True, encoding='utf-8')
        nvme_control_reading = self.read_register_value("0x4f")
        if nvme_control_reading != nvme_control_reg:
            fail_action(f"nvme {status} control fail")
        return self.nvme_dis_setting[1].count("1") if status == "disable" else None

    def sata_detect(self):
        sata_reading = self.read_register_value("0x39")
        _detect_err_list: list = []
        _no_detect_list: list = []
        _error_flag: int = 0
        # 转换成二进制格式
        sata_reading_bin = bin(int(sata_reading, 16))[2:].zfill(8)
        for i in range(len(sata_reading_bin)):
            if sata_reading_bin[i] != (slot_bit := self.sata_register[i]):
                if slot_bit == "0":
                    _detect_err_list.append(self.slot_start_num + 7 - i)
                elif slot_bit == "1":
                    _no_detect_list.append(self.slot_start_num + 7 - i)

        if len(_detect_err_list) != 0:
            promptr(f"硬盘卡 slot{_detect_err_list} 此位置不应该插SATA SDD，请确认配备或检查接口P10 and P4 pin")
            _error_flag += 1
        if len(_no_detect_list) != 0:
            promptr(f"硬盘卡 slot{_no_detect_list} 此位置未侦测到SATA SSD，请确认配备或检查接口P10 and P4 pin")
            _error_flag += 1
        if _error_flag == 0:
            echopass("SATA SSD detect")
        else:
            fail_action("SATA SSD detect")

    def strap_check(self) -> None:
        strap_addr_list: list = ['0x5c 0', '0x5c 1', '0x5c 2']
        strap_reading_list = list(map(self.read_register_value, strap_addr_list))
        if (strap_reading_value := " ".join(strap_reading_list)) == self.strap_register:
            echopass(f"MG9200 strap_register: {strap_reading_value} check")
        else:
            promptr(f"MG9200 strap_register: {strap_reading_value} , 定义值为{self.strap_register},请确认！！")
            fail_action("MG9200 strap_register 0x5c check")

    def gpio_vpp_check(self) -> None:
        gpio_vpp_addr_list: list = ['0x24', '0x25', '0x26', '0x27', '0x2f']
        gpio_vpp_reading_list = list(map(self.read_register_value, gpio_vpp_addr_list))
        if (gpio_vpp_reading_value := " ".join(gpio_vpp_reading_list)) == self.GPIO_VPP_register:
            echopass(f"MG9200 gpio_vpp_register: {gpio_vpp_reading_value} check")
        else:
            promptr(f"MG9200 gpio_vpp_register: {gpio_vpp_reading_value} , 定义值为{self.GPIO_VPP_register},请确认！！")
            fail_action("MG9200 gpio_vpp_register check")

    def e6_detect(self):
        e6_reading = self.read_register_value("0x2a")
        if e6_reading == self.e6_register:
            echopass(f"E6 pin detect status: {e6_reading}")
        else:
            promptr(f"E6 pin current status: {e6_reading}, should be {self.e6_register}")
            fail_action("MG9200 register 0x2a 读值 check fail")

    def read_register_value(self, addr: str) -> str:
        _full_command = f"{ipmi_command} 0x{self.smbus_addr} 1 {addr}"
        _res = run_shell(_full_command)
        if _res.returncode != 0:
            fail_action(f"run command {_full_command} fail")
        else:
            return _res.stdout.strip()[:2]
        # return run_shell(_full_command).stdout.splitlines()[0].strip()

    def mg9200_fw_check(self):
        fw_addr_list: list = ['0x60', '0x61', '0x62', '0x63', '0x64', '0x65', '0x66', '0x67']
        fw_reading_list = list(map(self.read_register_value, fw_addr_list))
        if (fw_reading_value := " ".join(fw_reading_list)) == self.chipset_fw:
            echopass(f"MG9200 chipset_fw: {fw_reading_value} check")
        else:
            promptr(f"MG9200 chipset_fw: {fw_reading_value} , 定义值为{self.chipset_fw},请确认！！")
            fail_action("MG9200 chipset_fw check")

    def fru_fw_check(self):
        fru_addr_list: list = ['0x6e', '0x6f']
        fru_reading_list = list(map(self.read_register_value, fru_addr_list))
        if (fru_reading_value := " ".join(fru_reading_list)) == self.fru_fw:
            echopass(f"MG9200 CFRU: {fru_reading_value} check")
        else:
            promptr(f"MG9200 CFRU 读值: {fru_reading_value} , 定义值为{self.fru_fw},请确认！！")
            fail_action("MG9200 CFRU check")

    def check_cfru(self):
        _read_checksum_cmd = f"{ipmi_command} 0x{self.smbus_addr} 0x04 0x55 0xaa 0xd8 0x1 0xe0 0x10"
        _checksum_res = run_shell(_read_checksum_cmd)
        if _checksum_res.returncode != 0:
            fail_action("读取MG9200 CFRU checksum值失败")
        if (__cfru_checksum := _checksum_res.stdout.strip()) == self.cfru_checksum:
            echopass(f"MG9200 CFRU checksum: {__cfru_checksum} check")
        else:
            promptr(f"MG9200 CFRU checksum: {__cfru_checksum} , 定义值为{self.cfru_checksum},请确认！！")
            fail_action("MG9200 CFRU checksum 比对FAIL")


def fail_action(msg):
    beepremind(1)
    run_shell(config['start_scan'])
    try:
        error_code = config["ErrorCode"]
    except KeyError:
        error_code = "NULL|NULL"
    raise AutoTestFail(error_code, __file__, msg)


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
        _bus_raw = hex(int(i2c_bus))
        # ipmitool raw 0x38 0x52 0x9
        _ipmi_command = " ".join([_ipmi_command, _bus_raw])
    else:
        # ipmitool i2c bus=4
        _ipmi_command = ''.join([_ipmi_command, i2c_bus])
    return _ipmi_command


def config_format():
    """
    <TestCase>
        <ProgramName>mg9200_check</ProgramName>
        <config name="ErrorCode" value="EXF13|MG9200 function fail"/>
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
            <port bus="c0" sata_list="00000000" nvme_list="00111111" strap_register="fc 21 03" mg9200_fw= "00 00 3c f0 23 02 b0 17" fru_fw="01 03" e6_register="ff" GPIO_VPP_status="00 00 0f 30 00" cfru_checksum="77 27 bd 6a"/>
        </portlist>
    </TestCase>
    """
    sys.exit(1)


def nvme_dis_test(test_list: list[MG9200]):
    prompty("将开始测试SSD 关闭，打开测试，请等待....")
    # 在执行关闭前的NVME SSD的数量
    detect_nvme_shell = "lsblk -do name,tran,type | grep -ic 'nvme' "
    detect_count_before = run_shell(detect_nvme_shell).stdout.strip()
    prompty("测试SSD关闭测试中....")
    pwdis_count = 0
    for mg9200_t in test_list:
        pwdis_count += mg9200_t.nvme_dis_control("disable")
        time.sleep(1)
    time.sleep(4)
    detect_count_after = run_shell(detect_nvme_shell).stdout.strip()
    if int(detect_count_after) != int(detect_count_before) - pwdis_count:
        for mg9200_t in test_list:
            mg9200_t.nvme_dis_control("enable")
        fail_action("应该关闭的SSD 的个数为{},实际关闭的数量为{},清检查SSD接口P3 pin及对应线路".
                    format(pwdis_count, (int(detect_count_before) - int(detect_count_after))))
    for mg9200_t in test_list:
        mg9200_t.nvme_dis_control("enable")
    time.sleep(2)
    echopass("NVME SSD 关闭测试PASS")
    pass


def mg9200_func():
    global ipmi_command
    ipmi_command = create_command()
    stop_res = run_shell(config['stop_scan'])
    if stop_res.returncode != 0:
        fail_action("stop scan fail")
    if not switch_mux(ipmi_command, switch_mg9200):
        fail_action("切换Switch 通道Fail")
    mg9200_test_list: list[MG9200] = []
    # 建立一个mg9200 对象的列表
    for item in mg9200_port_list:
        mg9200_case = MG9200(item['bus'], item['sata_list'], item['nvme_list'], item['e6_register'],
                             item['GPIO_VPP_status'], item['strap_register'], item['fru_fw'], item['mg9200_fw'], item['cfru_checksum'])
        mg9200_test_list.append(mg9200_case)
    for mg9200_t in mg9200_test_list:
        # FW check
        mg9200_t.fru_fw_check()
        mg9200_t.mg9200_fw_check()
        # SSD & NVME detect
        mg9200_t.sata_detect()
        mg9200_t.nvme_detect()
        # strap check
        mg9200_t.strap_check()
        mg9200_t.gpio_vpp_check()
        # checksum check
        mg9200_t.check_cfru()
    # NVME SSD disable 测试
    # nvme_dis_test(mg9200_test_list)


if __name__ == '__main__':
    xml_config = parser_argv(AP_version)
    ipmi_command = "ipmitool raw 0x38 0x52"
    # xml_config = "MS-S3351.xml"
    WorkPath = os.path.dirname(os.path.abspath(__file__))
    BaseName = os.path.basename(__file__).split(".")[0]
    config, mg9200_port_list, switch_mg9200, switch_fru = get_parameter(xml_config)
    mg9200_func()
    run_shell(config['start_scan'])
    #print(switch_fru,switch_mg9200)