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

#ifndef INC_LINUX_LINUXDEFS_H_
#define INC_LINUX_LINUXDEFS_H_ 

#ifndef IFNAMSIZ
#define IFNAMSIZ 16
#elif IFNAMSIZ != 16
#error IFNAMSIZ defined different as 16 - the linuxdefs.h file should be updated
#endif
#define NAL_OS_SPEC_ETH_IOCTL 0x8946
#define NAL_OS_SPEC_WETH_IOCTL SIOCSDRVSPEC
#define NAL_OS_SPEC_MAX_PCI_DEVICES 256
#define NAL_OS_SPEC_IOCTL_BASE 2049

#define NAL_OS_SPEC_PCI_BAR_0_REGISTER_OFFSET 0x10
#define NAL_OS_SPEC_PCI_BAR_1_REGISTER_OFFSET 0x14
#define NAL_OS_SPEC_PCI_BAR_2_REGISTER_OFFSET 0x18
#define NAL_OS_SPEC_PCI_BAR_3_REGISTER_OFFSET 0x1C
#define NAL_OS_SPEC_PCI_BAR_4_REGISTER_OFFSET 0x20
#define NAL_OS_SPEC_PCI_BAR_5_REGISTER_OFFSET 0x24

#define NAL_OS_SPEC_DRIVER_MAJOR_VERSION 1
#define NAL_OS_SPEC_DRIVER_MINOR_VERSION 2
#define NAL_OS_SPEC_DRIVER_BUILD_VERSION 0
#define NAL_OS_SPEC_DRIVER_FIX_VERSION 21

#define NAL_OS_SPEC_DRIVER_FILEDESCRIPTION "Intel(R) Network Adapter Diagnostic Driver "
#define NAL_OS_SPEC_DRIVER_COMPANYNAME "Intel Corporation "
#define NAL_OS_SPEC_DRIVER_COPYRIGHT_YEARS "2002-2022 "
#define NAL_OS_SPEC_DRIVER_LEGALCOPYRIGHT "Copyright (C) " DRIVER_COPYRIGHT_YEARS DRIVER_COMPANYNAME "All Rights Reserved."

#define NAL_OS_SPEC_MAKE_VERSION_STRING_HELPER(M,N,B,F) #M "." #N "." #B "." #F
#define NAL_OS_SPEC_MAKE_VERSION_STRING(M,N,B,F) NAL_OS_SPEC_MAKE_VERSION_STRING_HELPER(M,N,B,F)
#define NAL_OS_SPEC_DRIVER_VERSION NAL_OS_SPEC_MAKE_VERSION_STRING(NAL_OS_SPEC_DRIVER_MAJOR_VERSION,NAL_OS_SPEC_DRIVER_MINOR_VERSION,NAL_OS_SPEC_DRIVER_BUILD_VERSION,NAL_OS_SPEC_DRIVER_FIX_VERSION)
#define NAL_OS_SPEC_DRIVER_DESCRIPTION NAL_OS_SPEC_DRIVER_VERSION

#define NAL_OS_SPEC_MAX_PATH_LENGTH 256
#define NAL_OS_SPEC_MAX_COMMAND_LENGTH 256
#define NAL_OS_SPEC_BASE_DRIVER_NAME_MAX_LENGTH 256
#define NAL_OS_SPEC_IOCTL_GROUP_NUMBER 0x80

#define NAL_OS_SPEC_THREADS_ACTIVE FALSE
#define NAL_OS_SPEC_PCI_DRIVERS_PATH "/sys/bus/pci/drivers"
#define NAL_OS_SPEC_NET_CLASS_PATH "/sys/class/net"
#define NAL_OS_SPEC_MEM_DRIVER_PATH "/dev/mem"
#define NAL_OS_SPEC_KMEM_DRIVER_PATH "/dev/kmem"
#define NAL_OS_SPEC_IO_DRIVER_PATH "/dev/io"
#define NAL_OS_SPEC_PCI_DRIVER_PATH "/dev/pci"
#define NAL_OS_SPEC_QV_DRIVER_NAME "nal"
#define NAL_OS_SPEC_QV_DRIVER_PATH "/dev/" NAL_OS_SPEC_QV_DRIVER_NAME
#define NAL_OS_SPEC_QV_DRIVER_MODULE_NAME "iqvlinux"
#define NAL_OS_SPEC_QV_DRIVER_FILE_NAME "iqvlinux.ko"
#define NAL_OS_SPEC_QV_DRIVER_FILE_PATH "/boot/kernel/" NAL_OS_SPEC_QV_DRIVER_FILE_NAME
#define NAL_OS_SPEC_LOG_FILE_PATH "/var/log/iqvlinux.log"
#define NAL_OS_SPEC_SDK_LOG_FILE_PATH "./qvsdk.log"

#define NAL_OS_SPEC_MAX_TIMERS 2
#define NAL_OS_SPEC_MAX_MEMORY_ALLOCATIONS 50000
#define NAL_OS_SPEC_MAX_CONTIGUOUS_MEMORY_ALLOCATION (128 * 1024)
#define NAL_OS_SPEC_MAX_NON_PAGED_MEMORY_ALLOCATIONS 50000
#define NAL_OS_SPEC_INTERRUPT_SIGNATURE 0xA5BABA5A
#define NAL_OS_SPEC_MS_DELAY_FOR_CALCULATION 100

#define NAL_OS_SPEC_I40E_IOC ((((((('E' << 4) + '1') << 4) \
                                           + 'K') << 4) + 'G') << 4)
#define NAL_OS_SPEC_I40E_NVM_ACCESS (NAL_OS_SPEC_I40E_IOC | 5)
#define NAL_OS_SPEC_I40E_STOP_DRIVER (1)
#define NAL_OS_SPEC_I40E_START_DRIVER (2)

#define NAL_OS_SPEC_BASE_DRIVER_GET_DRIVER_INFO_COMMAND (3)

#ifndef NAL_DRIVER

#define MAKE_GCC_VERSION(MAJOR,MINOR,PATCH) (MAJOR * 10000 + MINOR * 100 + PATCH)
# ifdef __GNUC__
#define GCC_VERSION MAKE_GCC_VERSION(__GNUC__,__GNUC_MINOR__,__GNUC_PATCHLEVEL__)
# else
#define GCC_VERSION 0
# endif
#define CHECK_GCC_VERSION(MAJOR,MINOR,PATCH) GCC_VERSION >= MAKE_GCC_VERSION(MAJOR,MINOR,PATCH)

#define DO_PRAGMA(X) _Pragma (#X)
# if CHECK_GCC_VERSION(4,4,0)
#define NAL_COMPILER_MESSAGE(MESSAGE) DO_PRAGMA(message(MESSAGE))
# endif
# if CHECK_GCC_VERSION(4,6,0)
#define NAL_STATIC_ASSERT(CONDITION,MESSAGE) _Static_assert( CONDITION , MESSAGE )
# endif

#define SAFE_VERSIONS_DEFINED_IN_OS 
#define USE_NAL_INSTEAD_OF_POSIX 
#define USE_AUTO_BUFFER_SIZE_DETECTION 
#define FORCE_USING_NAL_INSTEAD_OF_POSIX 
#define NalVPrintStringFormattedSafe vsnprintf

#define UNREFERENCED_PARAMETER(x) (void)x

#else

#include <linux/version.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(3,2,0)
#define NAL_IOMMU_API_PRESENT 
#endif

#endif

#endif
