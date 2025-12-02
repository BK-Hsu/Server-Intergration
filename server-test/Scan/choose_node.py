#!/usr/bin/env python3
# coding:utf-8
"""
# -----------------------------------------------------------------------------------
# File Name: choose_node.py
# Author   : Kingsley
# mail     : kingsleywang@msi.com Ext:2250
# Created  : 2024-12-23
# Update   : 2024-12-23
# Version  : 1.0.0
# Description:
# 1.Tkinter 窗口提示人员确认目前所选择Node 的位置，并储存在指定路径当中
# Change list:
# 2024-12-23: First Release
# 2024-12-23：增加Node 检测及板子过站时间检测,来检查板子是否进维修或者测试后重工返回上一站后重新流线
# -----------------------------------------------------------------------------------
"""
import tkinter as tk
from supports import *

AP_version = "1.0.0"


def fail_action(msg):
    promptr(msg)
    beepremind(1)
    error_code = "NXS47|choose_node_fail"
    # try:
    #     error_code = config["ErrorCode"]
    # except KeyError:
    #     error_code = "NULL|NULL"
    raise AutoTestFail(error_code, __file__, msg)


def on_button_click(number):
    with open("/TestAP/PPID/Node_ID.TXT", 'w', encoding='utf-8') as f:
        f.write(number)
    print(number)
    root.destroy()


if __name__ == '__main__':
    node_sum = 4
    root = tk.Tk()
    root.title("请选择对应Node目前的插槽位置，点击对应按钮确认!!")
    root.geometry("600x400+400+100")
    Node1_dict = {"Node_name": "Node0", 'position_x': 1, 'position_y': 0}
    Node2_dict = {"Node_name": "Node1", 'position_x': 0, 'position_y': 0}
    Node3_dict = {"Node_name": "Node2", 'position_x': 1, 'position_y': 1}
    Node4_dict = {"Node_name": "Node3", 'position_x': 0, 'position_y': 1}
    if node_sum == 2:
        Node_list = [Node1_dict, Node3_dict]
    elif node_sum == 4:
        Node_list = [Node1_dict, Node2_dict, Node3_dict, Node4_dict]
    else:
        fail_action("node_num 设置错误，请根据实际数量扫描对应的数量")
    for button_number in Node_list:
        button = tk.Button(root, text=f"{button_number['Node_name']}", command=lambda node_num=button_number['Node_name']: on_button_click(node_num))
        button.config(width=15, height=5)
        button.config(bg='dark green', fg='white')
        button.config(font=('helvetica', 15, 'italic'))
        button.grid(row=button_number['position_x'], column=button_number['position_y'], padx=50, pady=20)
    root.mainloop()