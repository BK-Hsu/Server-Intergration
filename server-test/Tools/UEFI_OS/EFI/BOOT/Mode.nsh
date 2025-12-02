echo -off
fs1:
cd \
cls

ver
:Title
echo " "
echo "**********************************************************************"
echo "            MS-S2561 UEFI Shell Test Program            Rev. 1.0      "
echo "                                                                      "
echo "                                                                      "
echo "      1) Flash the serial number of baseboard                         "
echo "      2) Flash the revision of baseboard                              "
echo "      3) Flash the LAN MAC address                                    "
echo "                                                                      "
echo " Below files are necessary :                                          "
echo "  \20190212.bin                                                       "
echo "  \AMIDEEFIx64.EFI                                                    "
echo "  \eeupdate64e.efi                                                    "
echo "  \FRU_w.nsh                                                          "
echo "  \LAN_w.nsh                                                          "
echo "  \S2561.DMS                                                          "
echo "                          EPS/IPS Application engineering course      "
echo "**********************************************************************"


:ChkFile
set ErrorFlag 0
for %f in 20190212.bin AMIDEEFIx64.EFI eeupdate64e.efi FRU_w.nsh LAN_w.nsh S2561.DMS
	if not exist \%f  then
		echo "No such file or shell: \%f"
		stall 1000000 > nul
		set ErrorFlag 1 
	endif 
endfor

if not %ErrorFlag% == 0 then
	goto Fail
endif

:RunShell
set SubErrorFlag 0
for %s in FRU_w LAN_w
	%s.nsh > %s.log 
	type %s.log 
	if not %SubErrorFlag% == 0 then
		set ErrorFlag 1
		echo "Fail to execute the program: \%s"
		stall 4000000 > nul
	else
		echo "Succeed to execute the program: \%s"
	endif
endfor

:DelShell
for %s in FRU_w LAN_w
	rm %s.nsh > nul
endfor

:Go2Where
if not %ErrorFlag% == 0 then
	goto FAIL
else
	goto PASS
endif

:FAIL
echo "MS-S2561 UEFI Shell Test Fail"
goto END

:PASS
echo "MS-S2561 UEFI Shell Test PASS"
echo "MS-S2561 UEFI Shell Test PASS" > efiTest.log
echo ""
echo "**********************************************************************"
echo "     After 2s auto to shutdown                                        "
echo "     After shutdown then turn off the AC power more than 10s          "
echo "**********************************************************************"
stall 3000000 > nul 
reset -s
pause -q
goto END

:END

