#!/bin/bash
# FRU Data write program for Board level ;; 2025/03/05
# MDT = "MFG Date Time:",
# BSN = "Board Serial Number:",
# BPN = "Board Product Number:",
# BAN = "Board Part Number:",
# CSN = "Chassis Serial Number:",
# CPN = "Chassis Part Number:",
# CE / CCI= "Chassis Extra:"
# PSN = "Product Serial Number:",
# PN = "Product Name:",
# PPN = "Product Part Number:",
# PV = "Product Version:",

#========== PE input ==========

# Please add configuration below
# For items not to be written, enter "NA"

_MFG_Date_Time_exp=InternalGenerate
_Board_Serial_exp=NA
_Board_Product_exp=NA
_Board_Part_Number_exp=NA
_Chassis_Serial_exp=ExternalInput
_Chassis_Part_Number_exp=NA
_Chassis_Extra_exp=NA
_Product_Serial_exp=NA
_Product_Name_exp=NA
_Product_Part_Number_exp=NA
_Product_Version_exp=NA

#========== PE input ==========

#----Define sub function---------------------------------------------------------------------------

function ShowTestResult()
{
   if [ "$_DATA_exp" == "$_DATA_act" ]; then
        echo -e " ********************************** " | tee -a FRU_Data_result.log
	echo -e "   "$_DATA_NAME" Expect value is: "$_DATA_exp"" | tee -a FRU_Data_result.log
	echo -e "   "$_DATA_NAME" Actual value is: "$_DATA_act"" | tee -a FRU_Data_result.log
	echo -e "\e[1;92m   "$_DATA_NAME" value set is Pass   \e[0m" | tee -a FRU_Data_result.log
	echo -e " ********************************** " | tee -a FRU_Data_result.log
   else
	echo -e " ********************************** " | tee -a FRU_Data_result.log
	echo -e "   "$_DATA_NAME" Expect value is: "$_DATA_exp"" | tee -a FRU_Data_result.log
	echo -e "   "$_DATA_NAME" Actual value is: "$_DATA_act"" | tee -a FRU_Data_result.log
	echo -e "\e[1;91m   "$_DATA_NAME" value set is Fail \e[0m" | tee -a FRU_Data_result.log
	echo -e " ********************************** " | tee -a FRU_Data_result.log
        ipmitool fru print 0 | tee -a FRU_Data_result.log
	exit 1
   fi
}

function BoardSerial()
{
   if [ "$_Board_Serial_exp" != "NA" ]; then
        #value input
        read -p "Please Input Board Serial: " _Board_Serial_exp 
        #string length check
        
        if [ ${#_Board_Serial_exp} -ne 18 ]; then
             echo "Input Error! Board Serial length must be 18"
             exit 1
        fi
    
        #./FRUSH_local BSN "$_Board_Serial_exp"
        ipmitool fru edit 0 field b 2 "$_Board_Serial_exp"

        _DATA_NAME="Board Serial"
        _DATA_exp=$_Board_Serial_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult

   fi
}

function MFGDateTime()
{
   if [ "$_MFG_Date_Time_exp" != "NA" ]; then
   cd /TestAP/FRU_Write_Check
        ./lFru_date.out FRUSH_0425
        sleep 3 
        #Date format transfer ;; Example "03" to "3"
        date_temp=`expr $(date '+%d') + 2 - 2`
        _DATA_NAME="MFG Date Time"
        #_DATA_exp1=$(date '+%a %b %d 08:00:00 %Y')
        _DATA_exp1=$(date '+%a %b' && echo "$date_temp" && echo "08:00:00" && date '+%Y')
        echo $_DATA_exp1 > data_exp.txt
        read _DATA_exp < data_exp.txt
        _DATA_act1=$(ipmitool fru print 0 | grep -i 'Board Mfg Date' | awk '{print $5, $6, $7, $8, $9}')
        echo $_DATA_act1 > data_act.txt
        read _DATA_act < data_act.txt

        if [ -e data_exp.txt ]; then
             rm -f data_exp.txt
        fi

        if [ -e data_act.txt ]; then
             rm -f data_act.txt
        fi
        ShowTestResult
   fi
}

function BoardProduct()
{
   if [ "$_Board_Product_exp" != "NA" ]; then
        #./FRUSH_local BPN "$_Board_Product_exp" 
        ipmitool fru edit 0 field b 1 "$_Board_Product_exp"
        _DATA_NAME="Board Product"
        _DATA_exp=$_Board_Product_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function BoardPartNumber()
{
   if [ "$_Board_Part_Number_exp" != "NA" ]; then
        #./FRUSH_local BAN "$_Board_Part_Number_exp" 
        ipmitool fru edit 0 field b 3 "$_Board_Part_Number_exp"
        _DATA_NAME="Board Part Number"
        _DATA_exp=$_Board_Part_Number_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function ChassisSerial()
{
   if [ "$_Chassis_Serial_exp" != "NA" ]; then
        #value input
        read -p "Please Input Chassis Serial: " _Chassis_Serial_exp 
        #string length check

        if [ ${#_Chassis_Serial_exp} -ne 18 ]; then
             echo "Input Error! Chassis Serial length must be 18"
             exit 1
        fi

        #./FRUSH_local CSN "$_Chassis_Serial_exp"
        ipmitool fru edit 0 field c 1 "$_Chassis_Serial_exp"

        _DATA_NAME="Chassis Serial"
        _DATA_exp=$_Chassis_Serial_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function ProductSerial()
{
   if [ "$_Product_Serial_exp" != "NA" ]; then
        #value input
        read -p "Please Input Product Serial: " _Product_Serial_exp
        #string length check

        if [ ${#_Product_Serial_exp} -ne 10 ]; then
             echo "Input Error! Product Serial length must be 10"
             exit 1
        fi

        #./FRUSH_local PSN "$_Product_Serial_exp"
        ipmitool fru edit 0 field p 4 "$_Product_Serial_exp"

        _DATA_NAME="Product Serial"
        _DATA_exp=$_Product_Serial_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function ChassisPartNumber()
{
   if [ "$_Chassis_Part_Number_exp" != "NA" ]; then
        #./FRUSH_local CPN "$_Chassis_Part_Number_exp" 
        ipmitool fru edit 0 field c 0 "$_Chassis_Part_Number_exp"

        _DATA_NAME="Chassis Part Number"
        _DATA_exp=$_Chassis_Part_Number_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function ChassisExtra()
{
   if [ "$_Chassis_Extra_exp" != "NA" ]; then
        #./FRUSH_local CCE "$_Chassis_Extra_exp" 
        ipmitool fru edit 0 field c 2 "$_Chassis_Extra_exp"

        _DATA_NAME="Chassis Extra"
        _DATA_exp=$_Chassis_Extra_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function ProductName()
{
   if [ "$_Product_Name_exp" != "NA" ]; then
        #./FRUSH_local PN "$_Product_Name_exp" 
        ipmitool fru edit 0 field p 1 "$_Product_Name_exp"

        _DATA_NAME="Product Name"
        _DATA_exp=$_Product_Name_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}

function ProductPartNumber()
{
   if [ "$_Product_Part_Number_exp" != "NA" ]; then
        #./FRUSH_local PPN "$_Product_Part_Number_exp" 
        ipmitool fru edit 0 field p 2 "$_Product_Part_Number_exp"

        _DATA_NAME="Product Part Number"
        _DATA_exp=$_Product_Part_Number_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}


function ProductVersion()
{
   if [ "$_Product_Version_exp" != "NA" ]; then
        #./FRUSH_local PPN "$_Product_Version_exp" 
        ipmitool fru edit 0 field p 3 "$_Product_Version_exp"

        _DATA_NAME="Product Version"
        _DATA_exp=$_Product_Version_exp
        _DATA_act=$(ipmitool fru print 0 | grep -i "$_DATA_NAME" | awk '{print $NF}')
        ShowTestResult
   fi
}


#----Main function---------------------------------------------------------------------------------
#Set Log file
if [ -e FRU_Data_result.log ]; then
    rm -f FRU_Data_result.log
fi

echo "***** FRU Date Write Start *****" | tee FRU_Board_result.log
#ipmitool fru write 0 MS-S4051_0N.bin //write default value

BoardSerial
ChassisSerial
ProductSerial
MFGDateTime
BoardProduct
BoardPartNumber
ChassisPartNumber
ChassisExtra
ProductName
ProductPartNumber
ProductVersion

ipmitool fru print 0 | tee -a FRU_Data_result.log
exit 0
