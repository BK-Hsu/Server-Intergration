import os
import datetime
import requests
import time
import sys
from xml.etree.ElementTree import Element, SubElement, tostring, fromstring
from xml.dom.minidom import parseString
import chardet


def read_txt_file(file_path):
    if not os.path.exists(file_path):
        return ""
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read().strip()
        print(f"Content of {file_path}: '{content}'")  # print檔案內容
        return content


def create_xml(file_dir_ppid, file_dir_scan):
    root = Element('root')

    SubElement(root, 'TestStation').text = '505'
    SubElement(root, 'TestMachine').text = read_txt_file(os.path.join(file_dir_ppid, 'MODEL.TXT'))
    SubElement(root, 'Tester').text = read_txt_file(os.path.join(file_dir_ppid, 'OPID.TXT'))
    SubElement(root, 'BarcodeNo').text = read_txt_file(os.path.join(file_dir_ppid, 'PPID.TXT'))
    

    SubElement(root, 'TestStatus').text = 'P'

    SubElement(root, 'Customer')
    SubElement(root, 'TestTime').text = datetime.datetime.now().strftime('%Y/%m/%d %H:%M:%S')

    test_info = SubElement(root, 'TestInfo')
    # 確保只處理.txt檔案
    for key, file_name in [('BIOS_V', 'BIOSVER.TXT'), ('BMC_REV1', 'BMCVER.TXT')]:
        value = read_txt_file(os.path.join(file_dir_ppid, file_name))
        print(f"Reading {file_name}: {value}")  # 追踪檔案讀取結果
        if value and ':' in value:  # 如果存在冒號，則取其後的部分
            value = value.split(':', 1)[-1]
        value = value.strip()  # 去除領先和尾隨的空白字符
        SubElement(test_info, 'TestItem', {'Key': key}).text = value

    # 處裡MAC ADDRESS
#    mac_files = [f for f in os.listdir(file_dir_scan) if 'MAC' in f.upper() and f.endswith('.TXT')]
#    mac_files.sort()
#    for mac_file in mac_files:
#        value = read_txt_file(os.path.join(file_dir_scan, mac_file))
#        if mac_file.upper() == 'BMCMAC1.TXT':
#            key = 'BMC1'
#        elif mac_file.upper() == 'BMCMAC2.TXT':
#            key = 'BMC2'
#        else:
##            key = mac_file.rsplit('.', 1)[0].upper()  # 去掉檔案副檔名並轉換為大寫
#       SubElement(test_info, 'TestItem', {'Key': key}).text = value
#    
#    ng_info = SubElement(root, 'NgInfo')
#    SubElement(ng_info, 'Errcode')
#    SubElement(ng_info, 'Pin')
#    SubElement(ng_info, 'Location')

    # 輸出XML
    xml_str = tostring(root, encoding='utf-8')
    dom = parseString(xml_str)
    with open('upload.xml', 'w', encoding='utf-8') as xml_file:
        xml_file.write(dom.toprettyxml(indent="  "))

def Uploadxml(strings="", ulxmlfile="", args0='MBTestXml?sXML=', args1='sXML'):
    URL = 'https://sbc-la.msi.com/MES.wip.webservice/FTService.asmx/{}'.format(args0)
    if ulxmlfile != "":
        with open(ulxmlfile, 'rt') as f:
            strings = f.read()
                
    try:
        response = None
        max_retries = 3
        callwebserviceURL =URL+"/MBTest.Xml" 
        payload= {'sXML':strings}
        for retry in range(max_retries):
            response = requests.post(callwebserviceURL, data=payload)
            if response.status_code == 200:
                break

            response_encoding = chardet.detect(response.content)['encoding']
            decoded_content = response.content.decode(response_encoding)

            print(decoded_content)  # 打印正確編碼的回應內容
            print(f'Received error status code {response.status_code}, retrying in 5 seconds...')
            time.sleep(3)
        if response.status_code == 200:
            finaltest=fromstring(response.text).text
        else:
            finaltest = None
    except Exception as e:
        print("Uploadxml Exception:", e)
        finaltest = None
    return finaltest


if __name__ == "__main__":

    file_dir_ppid = r"/TestAP/PPID"
    file_dir_scan = r"/TestAP/Scan"
    create_xml(file_dir_ppid, file_dir_scan)

    response_text = Uploadxml(ulxmlfile='upload.xml')
    if response_text:
        print("Upload Success!")
        print("Response:", response_text)
    else:
        print("Upload Failed!")


