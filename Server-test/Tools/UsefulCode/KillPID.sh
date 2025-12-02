
KillPID()
{
	ps ax | awk '/cat \/dev\//{print $1}' | while read PID
	do
			kill -9 "${PID}" >& /dev/null
	done
}