
①-----------------------------------------------------------------------------------------
Usage
DumpXML
在以上函數的xml示例內加正確的errorcode代碼，示例如下：

<ErrorCode>NXF02|Check BIOS version fail</ErrorCode>

②-----------------------------------------------------------------------------------------
檢查xml無效的條件是否正確
ShowProcess 1 "Error config file: ${XmlConfigFile}"

③-----------------------------------------------------------------------------------------
在函數GetParametersFrXML后新增：把xxxxxxxx替換成對應的路徑即可，可參考GetParametersFrXML

GenerateErrorCode()
{
if [ "${#pcb}" == 0 ] ; then
	return 0
fi

local ErrorCodeFile='/TestAP/PPID/ErrorCode.TXT'
local ErrorCode=$(xmlstarlet sel -t -v "//xxxxxxxx/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
if [ "${#ErrorCode}" != 0 ] ; then
	cat ${ErrorCodeFile} 2>/dev/null | grep -wq "${ErrorCode}"
	if [ $? != 0 ] ; then
		echo "${ErrorCode}|${BaseName}.sh" >> ${ErrorCodeFile}	
	fi
else
	echo "NULL|NULL|${BaseName}.sh" >> ${ErrorCodeFile}
fi
sync;sync;sync
return 0
}

④-----------------------------------------------------------------------------------------
在echoFail（exit 1）后加函數
GenerateErrorCode


-----------------------------------------------------------------------------------------
特別情形： 類似于lan_c多線程時使用  NetCard 要修改為相應的根元素

	GenerateErrorCode()
	{
	if [ "\${#pcb}" == 0 ] ; then
		return 0
	fi

	local ErrorCodeFile='/TestAP/PPID/ErrorCode.TXT'
	local ErrorCode=\$(xmlstarlet sel -t -v "//NetCard/TestCase[ProgramName=\"${BaseName}\"]/ErrorCode" -n "${XmlConfigFile}" 2>/dev/null)
	if [ "\${#ErrorCode}" != 0 ] ; then
		cat \${ErrorCodeFile} 2>/dev/null | grep -wq "\${ErrorCode}"
		if [ \$? != 0 ] ; then
			echo "\${ErrorCode}|${BaseName}.sh" >> \${ErrorCodeFile}	
		fi
	else
		echo "NULL|NULL|${BaseName}.sh" >> \${ErrorCodeFile}
	fi
	sync;sync;sync
	return 0
	}
