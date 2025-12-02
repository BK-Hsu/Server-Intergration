#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: checkncsi.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2023-03-10
# Update   : 2023-03-13
# Version  : 1.0.4
# Desription:
# 通过MAC号获取eth 名字，并设置eth 静态IP
# 通过此静态IP 与BMC static IP ping，并统计ping 网结果
# 通过DHCP分配地址给NCSI，并进行ping网测试
# 同时检查网络link speed 是否达到1G 的状态
# Change list:
# 2023-03-13: First Release
# 2023-07-13: 在开启dhcp server之前先将其他网口放入隔离网域内，可以使测试时间大幅度缩小 升级到1.0.2
# 2024-03-14: add choice get mac from S258E,not need scan MAC
# 2024-03-22: fix bug,升级到1.0.3
# 2024-03-28: 增加在开始测试前杀掉dhclient进程，设置兼容centos和ubuntu dhcp启动指令， 使用ip link方式获取ethid，fix ifconfig获取时
# 2024-03-28： 因为dhclient产生的avahi设备影响，bug修正，升级到1.0.4
# ------------------------------------------------------------------------------------
"""

AP_version = "1.0.4"

import os, sys
from subprocess import run, PIPE
import json
import time
import re
from supports import *

dhcp_execute = False


class pingtest:
    global Ethid_list

    def __init__(self, mac_addr, host_ip, bmc_channel, defaultmac, ip_status, link_speed):
        self.host_ip = host_ip
        self.mac_addr = mac_addr
        self.defaultmac = defaultmac
        self.bmc_channel = bmc_channel
        self.ip_status = ip_status
        self.link_speed = link_speed
        # if not os.path.exists(self.mac_file):
        #    Fail_action("mac file %s not exist" % self.mac_file)
        # with open(self.mac_file, 'r', encoding='utf-8') as f:
        #    __mac = f.read().strip()
        _tempmac = ':'.join([self.mac_addr[i:i + 2] for i in range(0, len(self.mac_addr), 2)])
        # tempmac = self.mac_addr[0:2] + ":" + self.mac_addr[2:4] + ":" + self.mac_addr[4:6] + ":" + self.mac_addr[6:8] \
        #          + ":" + self.mac_addr[8:10] + ":" + self.mac_addr[10:12]
        # cmd = ''' ifconfig -a 2>/dev/null | grep -v "inet" |
        #        grep -iPB3 "{}" | grep -iE "^e[nt]" | awk '{{print $1}}' | tr -d ':' '''.format(_tempmac)
        cmd = ''' ip link | grep -iPB 1 "{}" | grep -E "^[0-9]" | awk -F: '{{print $2}}' | tr -d " " '''.format(
            _tempmac)
        self.Ethid = run(cmd, shell=True, stdout=PIPE, encoding='utf-8', check=True).stdout.strip()

    # 通过eth_id 设置IP 地址
    def set_ip(self):
        global dhcp_execute
        # os.system("dhclient -r {} >/dev/null 2>&1".format(self.Ethid))
        os.system("nmcli device set {} managed no".format(self.Ethid))
        time.sleep(1)
        os.system("ifconfig {} {} netmask 255.255.255.0 up".format(self.Ethid, self.host_ip))
        if self.ip_status != "static":
            Ethid_list.remove(self.Ethid)
            pingtest.vdom_init()
            os.system("ip netns add vdom1")
            for ethid in Ethid_list:
                os.system("ip link set {} netns vdom1".format(ethid))
            time.sleep(1)
            os.system("systemctl start {}".format(dhcp_cmd))
            time.sleep(3)
            dhcpchk_result = run("systemctl status {}".format(dhcp_cmd), shell=True, stdout=PIPE, encoding='utf-8')
            if "active (running)" in dhcpchk_result.stdout:
                dhcp_execute = True
                # pass
            else:
                Fail_action(self.Ethid, "DHCP 服务未正常启动，请确认")

    # 检查联网速度是否达到网口的最高速度
    def linkspeed_check(self):
        link_shell = "ethtool {}".format(self.Ethid)
        result = run(link_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
        if "Speed: {}b/s".format(self.link_speed) in result and "Duplex: Full" in result:
            print("LAN1 LAN2 网络连接%sb/s正常" % self.link_speed)
        else:
            Fail_action(self.Ethid, "LAN1 LAN2网络检查失败，请确认网线是否正确连接")

    def get_ip(self):
        if self.ip_status != "static":
            os.system("dhclient -r {} >/dev/null 2>&1".format(self.Ethid))
            time.sleep(3)
            os.system("dhclient {}".format(self.Ethid))
            time.sleep(3)
            getip_cmd = ''' ifconfig -a 2>/dev/null | grep -iA3 {} | 
            grep -iw "inet" | awk '{{print $2}}' '''.format(self.Ethid)
            result = run(getip_cmd, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
            print(result)
            self.host_ip = result
        else:
            pass

    @property
    def Bmcip(self):
        shell_bmcip = '''ipmitool lan print {}| grep -iw "IP Address" |tail -n1 | awk -F: '{{print $NF}}' '''.format(
            self.bmc_channel)
        dhcpflag = 0
        while dhcpflag < 20:
            if dhcpflag == 11:
                input("\033[1;33m请将回路线重新插拔，并敲回车继续测试\033[0m")
                time.sleep(3)
            result = run(shell_bmcip, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
            if self.ip_status == "static":
                # 获取BMC static IP，并与default 值比对，并返回static IP
                if result == self.defaultmac:
                    return result
                    # break
                else:
                    Fail_action(self.Ethid, "The BMC default MAC should be %s " % self.defaultmac)
            else:
                if "192.168.1." in result:
                    return result
                    # break
                else:
                    time.sleep(2)
                    dhcpflag += 1
                    if dhcpflag >= 20:
                        Fail_action(self.Ethid,
                                    "BMC CH%s address is %s ,can't get dhcp address" % (self.bmc_channel, result))
                    continue


    @property
    def lan2ip(self):
        getip_shell = 'ifconfig -a |grep -A2 "enp107s0f1" |grep "inet"'
        result = run(getip_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.split()[1].strip()
        return result

    # 透过2个网口之间联网来进行pin 网测试
    def ping_test(self):
        checkflag = 0
        self.linkspeed_check()
        self.set_ip()
        # self.get_ip()
        shell_ping = "ping {} -I {} -c 5 -s 4096".format(self.Bmcip, self.host_ip)
        result = run(shell_ping, shell=True, stdout=PIPE, encoding='utf-8').stdout
        for line in result.splitlines():
            print(line)
            if "packet loss" in line:
                pattern = re.search("\d+% packet loss,", line).group().split()
                if float(pattern[0].strip("%")) > 20:
                    Fail_action(self.Ethid, "LAN2 ping LAN1_NCSI 网口测试fail")
                checkflag = 1
        if checkflag != 1:
            Fail_action(self.Ethid, "Ping 网测试失败")
            # print(ping_result)

    @staticmethod
    def vdom_init():
        vdom_list = run("ip netns list", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
        if len(vdom_list) != 0:
            for item in vdom_list:
                prompty("will delete vdom %s" % item)
                os.system("ip netns del {}".format(item.split()[0].strip()))
            time.sleep(2)
        else:
            pass


def GetEthid():
    # ifconfig 指令为之前net-tools中指令，目前新的release 中已经不包含此部分，建议改用ip 的指令来使用
    # cmd = ''' ifconfig -a 2>/dev/null | grep -v "inet" | grep -B 1 -E "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}"|
    # awk -F':' '/flag/{print $1}'| grep -vE "^v" '''
    cmd = ''' ip link 2>/dev/null | grep -E "^[0-9]" | grep -iv "loopback" | awk -F: '{print $2}' |tr -d " " '''
    result = run(cmd, shell=True, stdout=PIPE, encoding='utf-8').stdout.split()
    return result


def get_dhcp_format():
    _result = run('hostnamectl status | grep -i "Operating System" ', shell=True, stdout=PIPE, encoding='utf-8').stdout
    # os_version: str = _result.split()[2].strip()
    if 'ubuntu' in _result.lower():
        _dhcp_server = "isc-dhcp-server"
    else:
        _dhcp_server = "dhcpd"
    return _dhcp_server


def get_S258E_mac(nic: int) -> str:
    _netcard: str = "X710"
    _netindex: list[str] = []
    _eeupdateres = run("eeupdate64e", shell=True, stdout=PIPE, encoding='utf-8').stdout.strip().splitlines()
    for line in _eeupdateres:
        if _netcard in line:
            _netindex.append(line.split()[0].strip())
    if len(_netindex) != 4:
        Fail_action("S258E not detected")
    _netindex.sort()
    _mac_shell = "eeupdate64e /nic={} /mac_dump | grep 'LAN MAC Address'".format(_netindex[nic - 1])
    _mac_info = run(_mac_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.split()[-1].strip().rstrip(".")
    if not re.match('^[0-9A-F]{12}$', _mac_info):
        Fail_action("Check S258E MAC: %s Fail" % _mac_info)
    return _mac_info


def get_mac(macfile) -> str:
    if not os.path.exists(macfile):
        Fail_action("mac file %s not exist" % macfile)
    with open(macfile, 'r', encoding='utf-8') as f:
        _mac = f.read().strip()
    if not re.match('^[0-9A-F]{12}$', _mac):
        Fail_action("Check MAC: %s Fail" % _mac)
    return _mac


def kill_dhclient():
    _getpid_cmd = 'ps -ax |grep -i "client" | grep -v "grep"'
    _pid_info = run(_getpid_cmd, shell=True, stdout=PIPE, encoding='utf-8')
    if _pid_info.returncode == 0:
        for line in _pid_info.stdout.strip().splitlines():
            _pid = line.strip().split()[0]
            os.system("kill -9 {}".format(_pid))


def Fail_action(ethid, msg=''):
    try:
        ErrorCode = config['errorcode']
    except KeyError:
        ErrorCode = "NULL|NULL"
    if dhcp_execute:
        os.system("systemctl stop {}".format(dhcp_cmd))
    pingtest.vdom_init()
    os.system('nmcli device set {} managed yes'.format(ethid))
    raise AutoTestFail(ErrorCode, __file__, msg)


if __name__ == '__main__':
    parser_argv(AP_version)  # 定义成模块便于程式通用,如果为SerialTest 则不需要输入
    # Ethid_list = []
    kill_dhclient()
    Ethid_list = GetEthid()
    dhcp_cmd = get_dhcp_format()
    BaseName = os.path.basename(__file__)
    config_path = os.path.abspath(__file__).split(".")[0] + ".json"
    with open(config_path, 'r', encoding='utf-8') as json_file:
        config = json.load(json_file)
    if config['mac_define'] == 'scan':
        mac_address = get_mac(config['host_mac'])
    else:
        host_nic: int = int(config['host_nic'])
        mac_address = get_S258E_mac(host_nic)
    print(mac_address)
    # exit(0)
    ncsitest = pingtest(mac_address, config['host_ip'], config['bmc_channel'], config['client_ip'], config['ip_getway'],
                        config['link_speed'])
    ncsitest.ping_test()
    echopass("Ncsitest")
    if dhcp_execute:
        os.system("systemctl stop {}".format(dhcp_cmd))
    os.system("nmcli device set {} managed yes".format(ncsitest.Ethid))
    pingtest.vdom_init()
