# -*- coding:utf-8 -*-
# 串口通信
#   Version : 1.0
#   Author  : Andy
#   Release : 2021-10-21

  

import serial
import serial.tools.list_ports
import time


class SerialPort:
        """ 串口通信 """
    
        @property
        def PortName(self):
            """ 获取或设置端口名 """
            return self.__portname

        @PortName.setter
        def PortName(self,value):
            self.__portname = value

        @property
        def Baudrate(self):
           """ 获取或设置波特率 """
           return self.__baudrate

        @Baudrate.setter
        def Baudrate(self,value):
            self.__baudrate = value

        @property
        def Timeout(self):
            """ 获取或设置读超时时间 """
            return self.__timeout

        @Timeout.setter
        def Timeout(self,value):
            self.__timeout = value
       
        @property
        def IsOpen(self):
            """ 获取串口是否已打开 """
            return self.__is_open

        @property
        def IsDataReady(self):
            """ 获取串口是否有数据可读 """
            if self.__is_open:
                return True if self.__ser.in_waiting > 0 else False
            else:
                return False

        @property
        def Encode(self):
            """ 获取或设置接收字符串编码，默认utf-8 """
            return self.__encode

        @Encode.setter
        def Encode(self,value):
            self.__encode = value

        @property
        def Decode(self):
            """ 获取或设置发送字符串编码，默认utf-8 """
            return self.__decode

        @Decode.setter
        def Decode(self,value):
            self.__decode = value    
            
        @property
        def DCD(self):
            """ 获取DCD状态 """
            if self.__is_open:
                if self.__ser.getCD():
                    return 1
            return 0

        @property
        def CTS(self):
            """ 获取CTS状态 """
            if self.__is_open:
                if self.__ser.getCTS():
                    return 1
            return 0

        @property
        def DSR(self):
            """ 获取DSR状态 """
            if self.__is_open:
                if self.__ser.getDSR():
                    return 1
            return 0

        @property
        def RI(self):
            """ 获取RI状态 """
            if self.__is_open:
                if self.__ser.getRI():
                    return 1
            return 0

        @property
        def DTR(self):
            """ 设置DTR状态 """
            pass

        @DTR.setter
        def DTR(self,value):
            if self.__is_open:
                if value == 0:
                    self.__ser.setDTR(0)
                else:
                    self.__ser.setDTR(1)

        @property
        def RTS(self):
            """ 设置RTS状态 """
            pass

        @RTS.setter
        def RTS(self,value):
            if self.__is_open:
                if value == 0:
                    self.__ser.setRTS(0)
                else:
                    self.__ser.setRTS(1)


        @staticmethod
        def get_port_list():
            """ 
            获取串口名称列表 
            返回值:[[device,description,hwid],...]
            """
            list_portname = []
            port_list = list(serial.tools.list_ports.comports(True))
            for i in range(0,len(port_list)):
                list_portname.append([port_list[i].device,port_list[i].description,port_list[i].hwid])
            return list_portname

        @staticmethod
        def get_port_info(_portname=None):
            """ 
            获取端口详细信息,返回{key:value}形式键值
            key = device,description,hwid,vid,pid,serial_number,location,manufacturer,product,interface
           """
            port_list = list(serial.tools.list_ports.comports(True))
            port_info = {}#.fromkeys(['device','description','hwid','vid','pid','serial_number','location','manufacturer','product','interface'])
            for port in port_list:
                if port.device == _portname:
                    port_info['device'] = port.device
                    port_info['description'] = port.description
                    port_info['hwid'] = port.hwid
                    port_info['vid'] = '{:04X}'.format(port.vid) if port.vid is not None else None
                    port_info['pid'] = '{:04X}'.format(port.pid) if port.pid is not None else None
                    port_info['serial_number'] = port.serial_number
                    port_info['location'] = port.location
                    port_info['manufacturer'] = port.manufacturer
                    port_info['product'] = port.product
                    port_info['interface'] = port.interface
            return port_info
            
        @staticmethod
        def is_port_exist(_portname):
            """ 检查端口是否存在 """
            return _portname in  [x.device for x in list(serial.tools.list_ports.comports(True))]

        def __init__(self):
            """ 初始化串口 """
            self.__ser = None
            self.__portname = None
            self.__baudrate = 9600
            self.__timeout = 0.5
            self.__is_open = False
            self.__encode = 'utf-8'
            self.__decode = 'utf-8'

        def open(self):
            """ 打开串口 """
            if self.__is_open:
                self.__ser.close()
            self.__ser = serial.Serial(port = self.__portname,baudrate = self.__baudrate,timeout = self.__timeout)
            self.__ser.interCharTimeout = 0.5
            self.__is_open = self.__ser.is_open
            return self.__is_open      

        def clear_buffer(self,_in_buff=True,_out_buff=True):
            """ 清除串口缓冲区 """
            if _in_buff:
                self.__ser.flushInput()
            if _out_buff:
                self.__ser.flushOutput()            

        def get_data_length(self):
            """ 获取串口接收缓冲区数据长度 """
            return self.__ser.in_waiting

        def read_data(self,_length=0):
            """ 从串口读取byte数据，如果不指定长度，则读取所有数据 """
            if _length > 0:
                return self.__ser.read(size=_length)
            else:
                return self.__ser.read_all()

        def read_line(self):
            """ 读取一行字符串(读取新行后结束) """
            return self.__ser.readline().decode(self.__decode)

        def read_string(self,_length=0):
            """ 从串口读取字符串，如果不指定长度，则读取所有数据 """
            return self.read_data(_length).decode(self.__decode)

        def write_string(self,_str):
            """ 向串口写入字符串 """
            if self.__ser.is_open:
                self.__ser.write(_str.encode(self.__encode))
                self.__ser.flush()
                time.sleep(0.5)


        def write_hex(self,_str):
            """ 向串口写入十六进制字符串 """
            if self.__ser.is_open:
                self.__ser.write(bytes.fromhex(_str))
                self.__ser.flush()
                time.sleep(0.5)
      
        def write_data(self,_data):
            """ 向串口写入byte数据 """
            if self.__ser.is_open:
                time.sleep(0.5)
                self.__ser.write(_data)
                # self.__ser.flush()

        def close(self):
            """ 关闭串口 """
            if self.__ser.is_open:
                self.__ser.close()


if __name__ == '__main1__':
    port_list = SerialPort.get_port_list()
    print(port_list)

    for i in port_list:
        print(SerialPort.get_port_info(i[0]))

    #com_name = 'COM-X'
    #if SerialPort.is_port_exist(com_name):
    #    print('{} is existed'.format(com_name))
    #else:
    #    print('{} not exist'.format(com_name))


    #ser = SerialPort()
    #ser.PortName = 'COM10'
    #ser.open()
    #print('DCD = {}'.format(ser.DCD))
    #print('DSR = {}'.format(ser.DSR))
    #print('RTS = {}'.format(ser.RTS))
    #print('CTS = {}'.format(ser.CTS))
    #print('DTR = {}'.format(ser.DTR))
    #print('RI = {}'.format(ser.RI))
   
