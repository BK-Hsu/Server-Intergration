import random
import os

def ALL_LED_ON():
	os.system("ipmitool i2c bus=6 0x40 0x00 0x06 0x00 0x00 >/dev/nul")
	os.system("ipmitool i2c bus=6 0x46 0x00 0x06 0x00 0x00 >/dev/nul")
def ALL_LED_OFF():
	os.system("ipmitool i2c bus=6 0x40 0x00 0x06 0xff 0xff >/dev/nul")
	os.system("ipmitool i2c bus=6 0x46 0x00 0x06 0xff 0xff >/dev/nul")
def RANDOM_LED_OFF(data):
	#print("ipmitool i2c bus=6 {0} 0x00 0x06 {1} {2}".format(data[0],data[1][0],data[1][1]))
	os.system("ipmitool i2c bus=6 {0} 0x00 0x06 {1} {2} >/dev/nul".format(data[0],data[1][0],data[1][1]))
	#print("ipmitool i2c bus=6 {0} 0x00 0x06 {1} {2}".format(data[0],data[1][0],data[1][1]))
def check_led(chk_times):
	if int(chk_times) == 0:
		ALL_LED_ON()
		input_num=input("please input the numbers of off led:")
		if int(input_num) == 0:
			ALL_LED_OFF()
			return(0)
		else:
			ALL_LED_OFF()
			return(1)
	elif int(chk_times) == 1:
		sum=0
		ALL_LED_ON()
		RANDOM_LED_OFF(data)		
		for i in bin(num):
			if i ==	"1":
				sum+=1
		input_num=input("please input the numbers of off led:")
		if int(input_num) == sum:
			ALL_LED_OFF()
			return(0)
		else:
			ALL_LED_OFF()
			print("should be: %s"%sum)
			return(1)
	elif int(chk_times) == 2:
		sum=0
		ALL_LED_ON()
		RANDOM_LED_OFF(data)		
		for i in bin(num):
			if i ==	"1":
				sum+=1
		input_num=input("please input the numbers of off led:")
		if int(input_num) == sum:
			ALL_LED_OFF()
			return(0)
		else:
			ALL_LED_OFF()
			print("should be: %s"%sum)
			return(1)
	
flagerror=0

DIMMConsole_list=[0x40,0x46]

DIMM_SELECT_CONSOLE=random.choice(DIMMConsole_list)
checktimes=[0,1,2]
for i in range(len(checktimes)):
	num=random.randint(0,255)
	OFF_NUM_list=[num,0]
	random.shuffle(OFF_NUM_list)
	chk_times=random.choice(checktimes)
	data=[DIMM_SELECT_CONSOLE,OFF_NUM_list]
	ch=check_led(chk_times)
	if int(ch) == 1:
		flagerror+=1
	checktimes.remove(chk_times)
print(flagerror)
if flagerror == 0:
	exit(0)
else:
	exit(1)
