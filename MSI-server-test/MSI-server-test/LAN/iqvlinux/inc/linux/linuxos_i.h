/*

  This file is provided under a dual BSD/GPLv2 license.  When using or
  redistributing this file, you may do so under either license.

  GPL LICENSE SUMMARY

  Copyright(c) 1999 - 2022 Intel Corporation. All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the terms of version 2 of the GNU General Public License as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
  The full GNU General Public License is included in this distribution
  in the file called COPYING.

  Contact Information:
  Intel Corporation, 5200 N.E. Elam Young Parkway, Hillsboro, OR 97124-6497

  BSD LICENSE

  Copyright(c) 1999 - 2022 Intel Corporation. All rights reserved.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name of Intel Corporation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#ifndef SDK_NAL_INC_LINUX_LINUXOS_I_H_
#define SDK_NAL_INC_LINUX_LINUXOS_I_H_ 

#ifndef NAL_DRIVER
#include <sys/time.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <nalbytes.h>
#include <sys/errno.h>
#include <sys/stat.h>
#endif

#include <linuxdefs.h>
#include <linuxtypes.h>
#include <naltypes.h>
#include <hwbus_t.h>

#ifndef NAL_DRIVER

#include <pthread.h>
#include <linuxnallibrary.h>

NAL_STATUS
_NalOsSpecIoctlResultToNalErrorCode(
    IN INT32 IoctlResultCode,
    IN NAL_STATUS OperationFailSatus
    );

NAL_STATUS
_NalConnectToIoDriver(
    VOID
    );

NAL_STATUS
_NalConnectToMemDriver(
    VOID
    );

NAL_STATUS
_NalConnectToPciDriver(
    VOID
    );

NAL_STATUS
_NalDisconnectFromIoDriver(
    VOID
    );

NAL_STATUS
_NalDisconnectFromMemDriver(
    VOID
    );

NAL_STATUS
_NalDisconnectFromPciDriver(
    VOID
    );

CHAR *
_NalGetCurrentShell(
    VOID
    );

NAL_PHYSICAL_ADDRESS
_NalFindEfiRsdPtrStructureTable(
    VOID
    );

NAL_STATUS
_NalSilentCommand(
    IN CHAR * Command ,
    IN NAL_STATUS CommandFailStatus
    );

NAL_STATUS
_NalScanResponseOfCommand(
      IN CHAR* Command ,
      IN NAL_STATUS FailedStatus ,
      IN CHAR* Format ,
      ...
      );

extern NAL_OS_SPEC_GLOBAL_VARIABLES Global_OsVariables;
#else

NAL_OS_RUN_DOMAIN
_NalGetOsRunDomain(
    VOID
    );
#endif

#endif
