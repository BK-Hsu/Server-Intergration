import random
import os

flagerror=0
randomled=random.randint(0,255)
list_led=[255]
list_led.append(randomled)
for i in range(len(list_led)):
	sum=0
	vaule=random.choice(list_led)
	os.system("DSA_LED %s"%vaule)
	for j in bin(vaule):
		if str(j) == "1":
			sum=sum+1
	num=input("please the DSALED light is:")
	if (int(num)-5) == int(sum):
		list_led.remove(vaule)
	else:
		print("The DSALED light should be:%s"%(sum+5))
		flagerror+=1
if flagerror == 0:
	exit(0)
else:
	exit(1)
		
