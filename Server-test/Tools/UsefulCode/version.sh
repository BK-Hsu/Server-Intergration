#!/bin/bash

# 1.表头更新,只保留如下信息
# 2.插入函数,修改相关信息

#FileName : xxxxx.sh
#Author   : CodyQin, qiutiqin@msi.com
#----Define sub function---------------------------------------------------------------------
VersionInfo()
{
	ApVersion="xxx"
	local CreatedDate="xxx"
	local UpdatedDate="xxxx"
	local Description="xxxxxxxxxxx"
	
	echo "$@" | grep -iq "getVersion" && return 0
	
	#    Linux Functional Test Utility Suites for Enterprise Platform Server
	#  Copyright(c) Micro-Star Int'L Co.,Ltd. 2019 - 2020. All Rights Reserved.
	#           Author：CodyQin, qiutiqin@msi.com
	printf "\n\e[1m%-4s%-s\e[0m\n" "" "Linux Functional Test Utility Suites for Enterprise Platform Server"
	printf "%-1s%-s\n" "" "Copyright(c) Micro-Star Int'L Co.,Ltd. ${CreatedDate%%-*-*} - ${UpdatedDate%%-*-*}. All Rights Reserved."
	printf "%-19s%-s\n\n" "" "Author：CodyQin, qiutiqin@msi.com"
	printf "%2s%-12s%2s%-s\n" "" "File name" ": " "${ShellFile}"
	printf "%2s%-12s%2s%-s\n" "" "Version" ": " "${ApVersion}"
	printf "%2s%-12s%2s%-s\n" "" "Description" ": " "${Description}"
	printf "%2s%-12s%2s%-s\n" "" "Created" ": " "${CreatedDate}"
	printf "%2s%-12s%2s%-s\n" "" "Environment" ": " "Linux and CentOS"
	printf "%2s%-12s%2s%-s\n" "" "History" ": " ""
	# 日期,修改内容
	#printf "%16s%-s\n" "" "xx,xxxxx"
	echo
	exit 1
}


# 3.更新 Usage提示:
`basename $0` [-x lConfig.xml] [-DV]
	-V : Display version number and exit(1)
	
	
	HELP前空一行出來
	注意優化英文描述
	
	
# 4.更新参数支持和调用
#--->Get and process the parameters
while getopts :VdDx: argv	
-------------------------

		V)
			VersionInfo
			exit 1
		;;	

-------------------------
# 5.更新ShowTitle()【如果有此函数的话】
#将
	ApVersion=$(cat -v `basename $0` | grep -i "version" | head -n1 | awk '{print $3}')
#替换为：
	VersionInfo "getVersion"
# 在全局 变量新增变量
	ApVersion

# 6.把多余的代码删除
		case ${ExtCmmds[$c]} in
			uuid)printf "%10s%s\n" "" "Please install: uuid-1.6.2-42.el8.x86_64.rpm";;
		esac	
		
# 设置main函数

main
[ ${ErrorFlag} != 0 ] && exit 1
