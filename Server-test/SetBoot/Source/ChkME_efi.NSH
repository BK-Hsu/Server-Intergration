@echo -off
echo "********************************************"
echo "*******   Check ME version in UEFI   *******"
echo "********************************************"
fs1:
 spsInfo.efi > ChkME_efi.log     
type  ChkME_efi.log 
echo "********************************************"
echo "*******    Check ME version in UEFI  *******"
echo "*******    Check ME version in UEFI  *******"
echo "********************************************"
echo "Test finish,reset and Set CMOS as Legacy...."
echo
