#1. 新增參數
	P:
# 多線程

		P)
			printf "%-s\n" "ParallelTest,Multithreading"
			exit 1
		;;
				
# 單線程

		P)
			printf "%-s\n" "SerialTest,xxxxx"
			exit 1
		;;		

#2. 確認V參數有加上
xxxxxx是以下內容
""            	#eeprom_w.sh,eeprom flash
""            	#Clrbmcmac.sh,Clear bmc mac
""            	#eeprom_c.sh,eeprom version check
""            	#lan_w.sh,lan mac flash
""            	#lan_c.sh,lan mac compare
""         #lan_int_t.sh,lan port internal loopback test
""         #lan_ext_t.sh,lan port external loopback test
""         #ChkBmcVer.sh or chkfw.sh,BMC FW version
"IpmbTest"            	#ipmb_bus.sh,ipmb bus function test
""            	#NCSItest.sh,NCSI test
""            #BMCMAC_w.sh,bmc mac flash
""            #BMCMAC_c.sh,bmc mac compare
""            	#chkbmc_ip.sh,Get BMC IP address
""            #CmosTime.sh,Ping server and set time,Compare Date and Time
""            	#mpsrw_w.sh,check MP2955 FW
""            	#mpsrw_c.sh,flash MP2955 FW
""           #Srlnum_w.sh,External S/N compare
""           #Srlnum_c.sh,External S/N flash
""            	#Shutdown





