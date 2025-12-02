#!/bin/bash
# Version: 1.2.3
ShowTitle()
{
	echo 
	VersionInfo "getVersion"
	if [ ${#ApVersion} != 0 ] ; then
		local Title="$@, version: ${ApVersion}"
	else
		local Title="$@"
	fi
	local BlankCnt=0
	let BlankCnt=(70-${#Title})/2
	BlankCnt=$(echo '                                         ' | cut -c 1-${BlankCnt})
	echo -e "\e[1m${BlankCnt}${Title}\e[0m"
}
ShowTitle "$@"
