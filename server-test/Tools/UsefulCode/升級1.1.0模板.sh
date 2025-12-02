ConfigFile

#=====================================================
printf "%-10s%-60s\n" "" 

2019-07-05
`basename $0` -x ConfigFile.xml
	eg.: `basename $0` -x S165102S.xml
	eg.: `basename $0` -D
	
	-D : Dump the xml config file
	
echo_pass --> echoPass
echo_fail --> echoFail
GetParametersInConfig --> GetParametersFrXML

declare XmlConfigFile
declare BaseName=$(echo `basename $0` | awk -F'\\.sh' '{print $1}' | sed 's/.\///g')

		D)
			DumpXML
			break
		;;

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
xmlstarlet val "${XmlConfigFile}" | grep -iwq "invalid"
if [ $? == 0 ] ; then
	xmlstarlet fo ${XmlConfigFile}
	ShowProcess 1 "Invalid XML file: ${XmlConfigFile}"
	exit 3
fi 

# Get the information from the config file(*.xml)
Length=$(xmlstarlet sel -t -v "//xxxx/TestCase[ProgramName=\"${BaseName}\"]/Port" -n "${XmlConfigFile}" 2>/dev/null)
SavePath=$(xmlstarlet sel -t -v "//xxxx/TestCase[ProgramName=\"${BaseName}\"]/SavePath" -n "${XmlConfigFile}" 2>/dev/null)

if [ ${#BiosFile} == 0 ] ; then
	ShowProcess 1 "Error config file: ${XmlConfigFile}"
	exit 3
fi
return 0
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DumpXML()
{
cat <<-Sample | xmlstarlet fo | tee ${BaseName}.xml
<Scan>
	<ScanCode>
		<ProgramName>ScanOPID</ProgramName>
		
		<!-- ScanOPID.sh: Length=0表示no limited -->
		<Length>8</Length>
		<SavePath>/TestAP/PPID/</SavePath>
	</ScanCode>
</Scan>
Sample
sync;sync;sync

xmlstarlet val "${BaseName}.xml" | grep -iwq "invalid"
if [ $? == 0 ] ; then
	ShowProcess 1 "Invalid XML file: ${BaseName}.xml"
	xmlstarlet fo ${BaseName}.xml
	exit 3
else
	ShowProcess 0 "Created the XML file: ${BaseName}.xml"
	exit 0
fi
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echoPass()
 { 	local String=$@ 
	echo -en "\e[1;32m ${String}\e[0m"
	[ ${#String} -gt 60 ] && pnt=70 || pnt=60
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;32m  PASS  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;32m${str// /-}\e[0m"
 }
 
echoFail()
 { 	local String=$@ 
	echo -en "\e[1;31m $String\e[0m"
	[ ${#String} -gt 60 ] && pnt=70 || pnt=60
	let PNT=${pnt}+10 
	echo -e "\e[${pnt}G [\e[1;31m  FAIL  \e[0;39m]"
	str=$(printf "%-${PNT}s" "-") 
	echo  -e "\e[1;31m${str// /-}\e[0m"
	BeepRemind 1 2>/dev/null
 }

ShowProcess()
{ 	
 local Status=$1
 local String="$2"
 case $Status in
	0)
		#[  OK  ]  Download the S1151030.tar.gz 
		printf "%-3s\e[1;32m%-2s\e[0m%-5s%-60s\n" "[  " "OK" "  ]  " "${String}"
	;;
	
	*)
		#[  NG  ]  Download the S1151030.tar.gz 
		printf "%-3s\e[1;31m%-2s\e[0m%-5s%-60s\n" "[  " "NG" "  ]  " "${String}"
		BeepRemind 1 2>/dev/null
		return 1
	;;
	esac
}

BeepRemind()
{
#Usage: BeepRemind Arg1
local Status=$1
Status=${Status:-"0"}

# load pc speaker driver
lsmod | grep -iq "pcspkr" || modprobe pcspkr

which beep > /dev/null 2>&1
if [ $? != 0 ] ; then
	return 0
fi

case ${Status} in
	0)
		#Pass/Remind
		beep -f 1800 > /dev/null 2>&1
	;;
	
	*)
		#Fail
		beep -f 800 -l 800 > /dev/null 2>&1
	;;
	esac
}
