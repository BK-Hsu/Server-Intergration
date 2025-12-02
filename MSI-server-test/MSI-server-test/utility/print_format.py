#!/usr/bin/env python3
# coding:utf-8
# ------------------------------------------------------------------------
# File Name: print_format.py
# Author: Kingsley
# mail: kingsleywang@msi.com Ext:2250
# Created Time: 2022-04-21
# Script Release Ver: 1.0.0.0
# ------------------------------------------------------------------------
import os


def echopass(msg):
    print("\033[1;32m{} {} [ PASS ]\033[0m".format(msg, '-'*(70-len(msg))))


def echofail(msg):
    print("\033[1;31m{} {} [ FAIL ]\033[0m".format(msg, '-'*(70-len(msg))))
    beepremind(1)


def prompty(msg):
    print("\033[1;33m{} \033[0m".format(msg))


def promptr(msg):
    print("\033[1;31m{} \033[0m".format(msg))


def showtitle(msg):
    print("\033[1;33m{}{}{} \033[0m".format(' '*int((70-len(msg))/2), msg, ' '*int((70-len(msg))/2)))

def promptg(msg):
    print("\033[1;32m{} \033[0m".format(msg))

def processpass(msg):
    print("\033[1;32m{} {} [  OK  ]\033[0m".format(msg, '-' * (70 - len(msg))))

def processfail(msg):
    print("\033[1;31m{} {} [  NG  ]\033[0m".format(msg, '-' * (70 - len(msg))))
    beepremind(1)

def beepremind(status):
    os.system('lsmod | grep -iq "pcspkr" || modprobe pcspkr')
    if status == 0:
        os.system('beep -f 1800 > /dev/null 2>&1')
    else:
        os.system('beep -f 800 -l 800 > /dev/null 2>&1')


def creatErrorCode(msg, errorcode):
    #failcode = sys.argv[1]
    #print(failcode)
    echofail(msg)
    failcodepath = "/TestAP/PPID/ErrorCode.TXT"
    with open(failcodepath, "a+", encoding='utf-8') as f:
        f.write(errorcode+'\n')
    raise Exception("\033[1;31m %s \033[0m" % msg)

if __name__ == '__main__':
    showtitle("功能测试fail，将会删除所有资料")

