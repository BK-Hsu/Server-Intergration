echo -off

for %s run (1 9) 
	if exist fs%s:\startup.nsh  then
		fs%s:
		goto start
	endif
endfor

:Error
echo no found such file: startup.nsh
goto Fail


:start
cd \
cls

ver
:Title
echo " "
echo "**********************************************************************"
echo "            MS-S258 UEFI Shell Test Program            Rev. 1.0       "
echo "                                                                      "
echo "                                                                      "
echo "      1) Get ME Version                         "
echo "      2) Get EDID of VGA                              "
echo "                                                                      "
echo " Below files are necessary :                                          "
echo "  \spsInfo.efi                                                       "
echo "  \ShowEDID.efi                                                   "
echo "  \ChkME_efi.NSH                                                   "
echo "                          EPS/IPS Application engineering course      "
echo "**********************************************************************"


:ChkFile
set ErrorFlag 0
for %f in spsInfo.efi ShowEDID.efi ChkME_efi.NSH 
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
for %s in ChkME_efi edid_efi
	%s.nsh  
	if not %SubErrorFlag% == 0 then
		set ErrorFlag 1
		echo "Fail to execute the program: \%s"
		stall 4000000 > nul
	else
		echo "Succeed to execute the program: \%s"
	endif
endfor

:Go2Where
if not %ErrorFlag% == 0 then
	goto FAIL
else
	goto PASS
endif

:FAIL
echo "MS-S258 UEFI Shell Test Fail"
goto END

:PASS
echo "MS-S258 UEFI Shell Test PASS"
echo "MS-S258 UEFI Shell Test PASS" > \efiTest.log
echo ""
echo "**********************************************************************"
echo "     Begin to go to Linux                                        "
echo "**********************************************************************"
stall 3000000 > nul 
fs0:\EFI\centos\grubx64.efi
#reset -s
pause -q
goto END

:END

