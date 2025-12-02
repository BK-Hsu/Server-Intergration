#!/usr/bin/env python3
# coding:utf-8
'''
# -----------------------------------------------------------------------------------
# File Name: lanTCP.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2023-03-10
# Update   : 2023-03-13
# Version  : 1.0.0
# Desription:
1.选取2个LAN，提供2个LAN 对应的MAC ，通过MAC 找到Ethid，然后为2个LAN 分别设定Static IP
2.确认两个LAN口之间是否已经连接了网线，并且速度是否有达到1G
3.打开Server端运行在后台运行，并检查ps -aux 是否发现已经运行起来，如果已经运行起来，则运行Client 端服务
4.分析Client 和Server 端打印出来的log，分析bitrate 0-30s的值是否都大于spec，平均值是否大于spec
5. Reverse再执行一次，同样执行检查，spec 定义在json文件当中
6. 测试结果PASS或者Fail之后都要找到服务器端并杀掉进程
7. json需要定义 client 的名字，比如S3121-Client，iperf 的参数定义，client和host对应的MAC
8. fail之后的动作，关闭iperf3 server(如果服务未开启则跳过关闭)，同时creat Errorcdoe 信息，然后Raise Execption
# Change list:
# 2023-03-13: First Release
# ------------------------------------------------------------------------------------
'''


from subprocess import run, PIPE
import os, sys
import json
import time
import re
from print_format import *


class LanTCP:
    ip_status = 10
    def __init__(self, mac_file, vdom, link_speed):
        self.mac_file = mac_file
        self.link_speed = link_speed
        #self.eth_id = None
        self.ipaddress = "192.168.1." + str(LanTCP.ip_status)
        self.vdom = vdom
        if not os.path.exists(self.mac_file):
            Fail_action("mac file %s not exist" % self.mac_file)
        with open(self.mac_file, 'r', encoding='utf-8') as f:
            __mac = f.read().strip()
        tempmac = __mac[0:2] + ":" + __mac[2:4] + ":" + __mac[4:6] + ":" + __mac[6:8] \
                  + ":" + __mac[8:10] + ":" + __mac[10:12]
        cmd = ''' ifconfig -a 2>/dev/null | grep -v "inet" | 
                grep -iPB3 "{}" | grep -iE "^e[nt]" | awk '{{print $1}}' | tr -d ':' '''.format(tempmac)
        self.Eth_id = run(cmd, shell=True, stdout=PIPE, encoding='utf-8', check=True).stdout.strip()
        LanTCP.ip_status += 1
    #@property
    #def mac(self):
    #    if not os.path.exists(self.mac_file):
    #        Fail_action("mac file %s not exist" % self.mac_file)
    #    with open(self.mac_file, 'r', encoding='utf-8') as f:
    #        __mac = f.read().strip()
     #   return __mac

    #@property
    #def Eth_id(self):
    #    tempmac = self.mac[0:2] + ":" + self.mac[2:4] + ":" + self.mac[4:6] + ":" + self.mac[6:8] \
    #              + ":" + self.mac[8:10] + ":" + self.mac[10:12]
    #    cmd = ''' ifconfig -a 2>/dev/null | grep -v "inet" |
    #    grep -iPB3 "{}" | grep -iE "^e[nt]" | awk '{{print $1}}' | tr -d ':' '''.format(tempmac)
    #    __eth_id = run(cmd, shell=True, stdout=PIPE, encoding='utf-8', check=True).stdout.strip()
    #    return __eth_id

    # 检查联网速度是否达到1G
    def linkspeed_check(self):
        link_shell = "ethtool {}".format(self.Eth_id)
        result = run(link_shell, shell=True, stdout=PIPE, encoding='utf-8').stdout.strip()
        if "Speed: {}b/s".format(self.link_speed) in result and "Duplex: Full" in result:
            print("\033[1;32m %s link status check pass \033[0m" % self.link_speed)
        else:
            Fail_action("网络连接速度未达到 %s，清检查" % self.link_speed)

    # 通过eth_id 设置IP 地址
    def set_ip(self):
        #self.linkspeed_check()
        vdom_list = run("ip netns list", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
        if len(vdom_list) != 0:
            print(self.vdom, vdom_list)
            vdom_found = False
            for item in vdom_list:
                if re.search(self.vdom, item):
                    vdom_found = True
                    break
            if not vdom_found:
                if run("ip netns add {}".format(self.vdom), shell=True, stdout=PIPE, encoding='utf-8').returncode != 0:
                    Fail_action("set %s fail" % self.vdom)
        else:
            if run("ip netns add {}".format(self.vdom), shell=True, stdout=PIPE, encoding='utf-8').returncode != 0:
                Fail_action("set %s fail" % self.vdom)
        os.system("ip link set {} netns {}".format(self.Eth_id, self.vdom))
        os.system("ip netns exec {} ifconfig {} {} netmask 255.255.255.0".format(self.vdom, self.Eth_id, self.ipaddress))
        time.sleep(1)
        os.system("ip netns exec {} ip link set dev {} up".format(self.vdom, self.Eth_id))
        os.system("ip netns exec {} ifconfig {}".format(self.vdom, self.Eth_id))
        time.sleep(5)

    def lan_status_check(self):
        lan_status_cmd = "ethtool -S {}".format(self.Eth_id)
        err_list = []
        lan_status_result = run(lan_status_cmd, shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
        print("\033[1;32m 如下为信息为网口传输统计： \033[0m")
        for line in lan_status_result:
            if "dropped" in line:
                print(line)
                pattern1 = re.compile('.*dropped.*: 0$')
                re1 = pattern1.match(line)
                if re1 is None:
                    err_list.append(line)
            elif "error" in line:
                print(line)
                pattern2 = re.compile('.*error.*: 0$')
                re2 = pattern2.match(line)
                if re2 is None:
                    err_list.append(line)
            else:
                continue
        if len(err_list) != 0:
            for line in err_list:
                print("\033[1;31m{}\033[0m".format(line))


def run_shell(cmd):
    result = run(cmd, shell=True, stdout=PIPE, encoding='utf-8')
    return result


def block(file):
    block = []
    for line in file:
        if "Connecting to host" in line:
            block.clear()
        elif " 0.00-{}.00".format(config['time']) in line and "SUM" in line:
            block.append(line)
        else:
            continue
    if len(block) == 0 :
        Fail_action("The iperf3 bandwidth test not finish normally")
    return block


def logcheck(log):
    errflag = 0
    bandwidth_log = block(log)
    for line in bandwidth_log:
        temp_list = line.split()
        bandvalue = temp_list[temp_list.index("Mbits/sec") - 1]
        if int(bandvalue) >= config['bandwidth']:
            print("%-95s%-10s%-6s" % (line.strip(), config['bandwidth'], " \033[1;32m[ OK ]\033[0m "))
        else:
            errflag += 1
            print("%-95s%-10s%-6s" % (line.strip(), config['bandwidth'], " \033[1;31m[ NG ]\033[0m "))
    if errflag != 0:
        os.system("kill -9 {} >& /dev/null".format(server_pid))
        Fail_action("iperf3 网络TCP 带宽测试Fail")


def Fail_action(msg):
    echofail(msg)
    global config
    errorcode_file = "/TestAP/PPID/ErrorCode.TXT"
    errorcode = config['errorcode']
    with open(errorcode_file, 'a+', encoding='utf-8') as f:
        if BaseName not in f.read():
            f.write(errorcode + "|" + BaseName + "\n" )
    raise Exception("\033[1;31m %s \033[0m" % msg)

def vdom_init():
    vdom_list = run("ip netns list", shell=True, stdout=PIPE, encoding='utf-8').stdout.splitlines()
    if len(vdom_list) != 0:
        for item in vdom_list:
            prompty("will delete vdom %s" % item)
            os.system("ip netns del {}".format(item.split()[0].strip()))
        time.sleep(5)
    else:
        pass


if __name__ == '__main__':
    try:
        if sys.argv[1] == "-P":
            print("SerialTest")
            exit(1)
    except IndexError:
        pass
    print("\033[1;32m 下面将开始测试iperf3 TCP 带宽测试，请等待.... \033[0m")
    BaseName = os.path.basename(__file__)
    config_path = os.path.abspath(__file__).split(".")[0] + ".json"
    with open(config_path, 'r', encoding='utf-8') as json_file:
        config = json.load(json_file)
    #with open("/TestAP/LAN/lanTCP.json", 'r', encoding='utf-8') as json_file:
    #    config = json.load(json_file)
    vdom_init()
    port_list = []
    for item in config['port']:
        if item['name'] == "client":
            client_port = LanTCP(item['MAC'], item['vdom'], config['link_speed'])
            port_list.append(client_port)
            client_port.linkspeed_check()
        elif item['name'] == "server":
            server_port = LanTCP(item['MAC'], item['vdom'], config['link_speed'])
            port_list.append(server_port)
            server_port.linkspeed_check()
        else:
            raise Exception("config format error")
    for port in port_list:
        port.set_ip()
    client_cmd = "ip netns exec {} iperf3 --bandwidth 10000m --format {} --interval {} --parallel {} --{} --time {} " \
        "--get-server-output --omit {} --title {}-Client -w 200K --port 5201 --client {}"\
        .format(client_port.vdom, config['format'], config['interval'], config['parallel'], config['ipv46'], config['time'],
                config['omit'], config['title'], server_port.ipaddress)
    client_reverse_cmd = client_cmd + " --reverse"
    server_cmd = "ip netns exec {} iperf3 --format {} --interval {} --server --port 5201 &"\
        .format(server_port.vdom, config['format'], config['interval'])
    server_exist_check = '''ps -aux |grep -iE "iperf3.*server" |grep -iv "grep" |awk '{{print $2}}' '''
    os.system(server_cmd)
    check_result = run_shell(server_exist_check)
    server_pid = check_result.stdout.strip()
    if len(server_pid) == 0:
        Fail_action("iperf3 Server not work")
    for cmd in [client_cmd, client_reverse_cmd]:
        client_result = run_shell(cmd)
        if client_result.returncode == 0:
            print(client_result.stdout)
            logcheck(client_result.stdout.splitlines())
        else:
            input("waiting for test")
            os.system("kill -9 {} >& /dev/null".format(server_pid))
            Fail_action("iperf3 网络TCP 带宽测试Fail")
    os.system("kill -9 {} >& /dev/null".format(server_pid))
    vdom_init() 
    for port in port_list:
        port.lan_status_check()   
    print("\033[1;32m{} {} [ PASS ]\033[0m".format("Iperf3 function Test", '-' * (70 - len("Iperf3 function Test"))))
