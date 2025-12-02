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

#ifndef SDK_NAL_INC_LINUX_LINUXNALIOCTL_H_
#define SDK_NAL_INC_LINUX_LINUXNALIOCTL_H_ 

#include <linuxdefs.h>
#include <naltypes.h>
#include <linuxtypes.h>

#ifndef NAL_DRIVER
#include <sys/ioctl.h>
#include <device_t.h>
#endif

#define NAL_MAKE_IOCTL(IoCtlNumber) (NAL_OS_SPEC_IOCTL_BASE + IoCtlNumber)

#ifndef NAL_DRIVER

#define NAL_SEND_IOCTL(NalIoctlNumber,InputBuffer,InputBufferSize,OutputBuffer,OutputBufferSize) \
    { \
        if(Global_OsVariables.NalFileDescriptor != -1) \
        { \
            ioctl(Global_OsVariables.NalFileDescriptor, NalIoctlNumber, InputBuffer); \
            UNREFERENCED_PARAMETER(InputBufferSize); \
            UNREFERENCED_PARAMETER(OutputBuffer); \
            UNREFERENCED_PARAMETER(OutputBufferSize); \
        } \
    }

KVOID*
_NalAllocateMemoryNonPagedPciIoctl(
    IN KVOID* PDev,
    IN UINT32 ByteCount,
    IN UINT32 Alignment,
    OUT NAL_PHYSICAL_ADDRESS* PhysicalAddress OPTIONAL,
    IN CHAR* NamedLocator,
    IN UINT32 LineNumber
    );

VOID
_NalFreeMemoryNonPagedPciIoctl(
    IN KVOID* PDev,
    IN KVOID* Address,
    IN NAL_PHYSICAL_ADDRESS PhyAddr,
    IN UINT32 MemSize
    );

NAL_STATUS
_NalFillDeviceResourceIoctl(
    IN NAL_OS_SPEC_DEVICE_CONTEXT* DeviceContext,
    IN NAL_DEVICE_LOCATION PciLocation,
    IN OUT NAL_DEVICE* Device
    );

NAL_STATUS
_NalDeviceResourceIoctl(
    IN UINT64 FunctionId,
    IN NAL_OS_SPEC_DEVICE_CONTEXT* DeviceContext,
    IN NAL_DEVICE_LOCATION PciLocation,
    IN OUT NAL_DEVICE* Device
    );

NAL_STATUS
_NalRequestDeviceResourceIoctl(
    IN NAL_OS_SPEC_DEVICE_CONTEXT* DeviceContext,
    IN NAL_DEVICE_LOCATION PciLocation,
    IN OUT NAL_DEVICE* Device
    );

NAL_STATUS
_NalReleaseDeviceResourceIoctl(
    IN NAL_OS_SPEC_DEVICE_CONTEXT* DeviceContext,
    IN NAL_DEVICE_LOCATION PciLocation
    );

NAL_STATUS
_NalOsSpecReadPciExByteIoctl(
    IN NAL_DEVICE_LOCATION DeviceLocation,
    IN UINT32 ByteIndex,
    OUT UINT8* Value
    );

NAL_STATUS
_NalOsWritePciExByteIoctl(
    IN NAL_DEVICE_LOCATION DeviceLocation,
    IN UINT32 ByteIndex,
    IN UINT8 Value
    );

#else

#endif

#endif
