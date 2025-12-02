@echo -off
echo "********************************************"
echo "*******   Check EDID info in UEFI    *******"
echo "********************************************"
fs1:
 ShowEDID.efi > edid_efi .log     
type  edid_efi.log 
echo "********************************************"
echo "*******   Check EDID info in UEFI    *******"
echo "*******   Check EDID info in UEFI    *******"
echo "********************************************"
echo
