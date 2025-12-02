
                           ****** README.TXT ******

        lCOM.out is a utility to test COM port in RS232, RS422 mode, 
the test is for Linux environments.

        This utility returns Linux return code for automation.


Parameter
=========

        Usage: lCOM

Description:
1. Please use Super User or root to run program.
2. Create a new ini file. Please delete old ini file and rerun lCOM.out.
3. INI file "Test Card" item input choose one: TL20, TL644, Legacy, LegacyRS422


Example
=======
1. Test:

    ./lCOM.out
       ==> Create a ini file. If ini file exist run test.

    ./lCOM.out
       ==> Run test.

2. Create a new ini file:

    ./rm lCOM.ini
    ./lCOM.out


Return Code
===========
1       Failure
0       Success


Release Package
===============
lCOM.out                Executable file to do the lCOM test.
HISTORY.TXT             The file is the utility's history.
README.TXT              This is the utility's information.


