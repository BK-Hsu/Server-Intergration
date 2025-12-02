#!/usr/bin/env python3
# coding:utf-8
import random
import os
import time


cmdo='VROC_Check 1'
cmdc='VROC_Check 0'
num_list=[121,122,211,212]
anw=str(random.choice(num_list))
error=0
for i in anw:
	if int(i) == 1:
		os.system(cmdc)
		in_aw=int(input("please input the number of light:"))
		if in_aw != 1:
			error += 1
	elif int(i) ==2:
		os.system(cmdo)
		in_aw=int(input("please input the number of light:"))
		if in_aw != 2:
			error += 1
if error == 0 :
	exit(0)
else:
	exit(1)
