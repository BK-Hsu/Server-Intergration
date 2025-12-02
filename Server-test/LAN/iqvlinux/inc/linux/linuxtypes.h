/*

  This file is provided under a dual BSD/GPLv2 license.  When using or
  redistributing this file, you may do so under either license.

  GPL LICENSE SUMMARY

  Copyright(c) 2016 - 2022 Intel Corporation. All rights reserved.

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


#ifndef INC_FREEBSD_FREEBSDTYPES_H_
#define INC_FREEBSD_FREEBSDTYPES_H_ 

#include <naltypes.h>
#include <linuxdefs.h>
#include <hwbus_t.h>

#ifdef NAL_DRIVER
#else
#include <net/if.h>
#include <pthread.h>
#include <sys/time.h>
#endif

typedef UINTN NAL_OS_SPECIFIC_DEVICE;

typedef struct _NAL_OS_SPEC_DEVICE_CONTEXT
{
    BOOLEAN MarkedInUse;
    KVOID* KernelModeContext;
    KVOID* PciDevPtr;
    CHAR InterfaceName[IFNAMSIZ];
    CHAR BaseDriverName[NAL_OS_SPEC_BASE_DRIVER_NAME_MAX_LENGTH];
    BOOLEAN MemoryAllocatedByQvDriver;
} NAL_OS_SPEC_DEVICE_CONTEXT;

typedef struct _NAL_OS_SPEC_ISR_DEVICE
{
    UINT32 Signature;
    BOOLEAN DeviceInterrupted;
    KVOID* HardwareVirtualAddress;
    UINT32 Irq;
    UINT32 MacType;
} NAL_OS_SPEC_ISR_DEVICE;

#ifdef NAL_DRIVER
typedef struct _NAL_OS_SPEC_ADAPTER_IN_USE_TABLE
{
    NAL_DEVICE_LOCATION DeviceLocation;
    BOOLEAN InUse;
} NAL_OS_SPEC_ADAPTER_IN_USE_TABLE;

#else

typedef struct _NAL_OS_SPEC_TIMER_OBJECT
{
    NAL_TIMER_CALLBACK Callback;
    UINT32 ThreadId;
    struct itimerval TimerVal;
    VOID* Context;
} NAL_OS_SPEC_TIMER_OBJECT;

typedef struct _NAL_OS_SPEC_MEMORY_MAP_TABLE
{
    INT32 ReferenceCount;
    VOID* VirtualAddress;
    VOID* AlignedVirtualAddress;
    NAL_PHYSICAL_ADDRESS AlignedPhysicalAddress;
    UINT32 Alignment;
    UINT32 BytesAllocated;
} NAL_OS_SPEC_MEMORY_MAP_TABLE;

typedef struct NAL_OS_SPEC_NONPAGED_MEMORY_TABLE
{
    UINT32 ReferenceCount;
    KVOID* VirtualAddress;
    VOID* MappedVirtualAddress;
} NAL_OS_SPEC_NONPAGED_MEMORY_TABLE;

#endif

typedef struct _NAL_OS_SPEC_DMA_PCI_MEMORY_TABLE
{
    UINT32 ReferenceCount;
    KVOID* VirtualAddress;
    KVOID* KernelAddress;
    NAL_PHYSICAL_ADDRESS PhysicalAddress;
    UINT32 Size;
} NAL_OS_SPEC_DMA_PCI_MEMORY_TABLE;

#ifndef NAL_DRIVER

typedef struct _NAL_OS_SPEC_THREAD_CONTEXT
{
        pthread_t Thread;
        VOID* Context;
        NAL_THREAD_FUNC ThreadFunction;
        BOOLEAN ThreadRunning;
} NAL_OS_SPEC_THREAD_CONTEXT;

typedef struct _NAL_OS_SPEC_DRIVER_INFO {
    UINT32 Command;
    char Driver[32];
    char Version[32];
    char FirmwareVersion[32];
    char BusInfo[32];
    char Reserved1[48];
    char Reserved2[16];
    UINT32 NetStats;
    UINT32 TestInfoLength;
    UINT32 EepromDumpLength;
    UINT32 RegisterDumpLength;
} NAL_OS_SPEC_DRIVER_INFO;

typedef NAL_OS_SPEC_THREAD_CONTEXT NAL_THREAD_ID;

typedef struct _NAL_OS_SPEC_GLOBAL_VARIABLES
{
    BOOLEAN MemMappingWithQvDriverPossible;
    BOOLEAN QvDriverMode;
    BOOLEAN MemMappingToUserSpaceDisabled;
    int NalFileDescriptor;
    int IoFileDescriptor;
    int MemFileDescriptor;
    int PciFileDescriptor;
    NAL_OS_SPEC_MEMORY_MAP_TABLE MemoryMapTable[NAL_OS_SPEC_MAX_MEMORY_ALLOCATIONS];
    NAL_OS_SPEC_TIMER_OBJECT TimerObjects[NAL_OS_SPEC_MAX_TIMERS];
    NAL_OS_SPEC_NONPAGED_MEMORY_TABLE NonPagedMapTable[NAL_OS_SPEC_MAX_MEMORY_ALLOCATIONS];
    NAL_OS_SPEC_DMA_PCI_MEMORY_TABLE DmaPciMemoryTable[NAL_OS_SPEC_MAX_MEMORY_ALLOCATIONS];
} NAL_OS_SPEC_GLOBAL_VARIABLES;

#endif

#endif
