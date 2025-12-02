FindAndInstallCommand()
{
# Usage: FindAndInstallCommand Command Backage
local Command=$1
local Backage=$2
while :
do
	which ${Command} >/dev/null 2>&1
	if [ $? != 0 ] ; then
		echo_fail "No such command: ${Command}"
		ls "${Backage}" >/dev/null 2>&1
		if [ $? == 0 ] ; then
			echo "Begin install ${Backage}"
			rpm -Uvh --force --nodeps  "${Backage}" 2>/dev/null
			if [ $? != 0 ] ; then
				echo_fail "Install ${Backage}"
			else
				echo_pass "Install ${Backage}"
				continue
			fi
		fi
		exit 2
	else
		break
	fi
done

# other setting
service acpid start
chkconfig acpid on
}