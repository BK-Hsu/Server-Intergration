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

#ifndef INC_FREEBSD_FREEBSDMEMORY_H_
#define INC_FREEBSD_FREEBSDMEMORY_H_ 

#include <naltypes.h>
#include <linuxtypes.h>

#define _NalReadPortOs8(a,p) NalReadPort8(p)
#define _NalReadPortOs16(a,p) NalReadPort16(p)
#define _NalReadPortOs32(a,p) NalReadPort32(p)
#define _NalWritePortOs8(a,p,v) NalWritePort8(p,v)
#define _NalWritePortOs16(a,p,v) NalWritePort16(p,v)
#define _NalWritePortOs32(a,p,v) NalWritePort32(p,v)
#define _NalReadRegisterOs8(a,d) NalReadRegister8(d)
#define _NalReadRegisterOs16(a,d) NalReadRegister16(d)
#define _NalReadRegisterOs32(a,d) NalReadRegister32(d)
#define _NalWriteRegisterOs8(a,d,v) NalWriteRegister8(d,v)
#define _NalWriteRegisterOs16(a,d,v) NalWriteRegister16(d,v)
#define _NalWriteRegisterOs32(a,d,v) NalWriteRegister32(d,v)

#define NalAllocateMemoryNonPagedPci(PDev,ByteCount,Alignment,PhysicalAddress) \
    _NalAllocateMemoryNonPagedPci((PDev), (ByteCount), (Alignment), (PhysicalAddress),__FILE__, __LINE__)

KVOID*
_NalAllocateMemoryNonPagedPci(
    IN KVOID* PDev,
    IN UINT32 ByteCount,
    IN UINT32 Alignment,
    OUT NAL_PHYSICAL_ADDRESS* PhysicalAddress,
    IN CHAR* NamedLocator,
    IN UINT32 LineNumber
    );

VOID
NalFreeMemoryNonPagedPci(
    IN KVOID* PDev,
    IN KVOID* Address,
    IN NAL_PHYSICAL_ADDRESS PhysicalAddress,
    IN UINT32 Size
    );

BOOLEAN
_NalOsSpecIsMappingByQvDriverPossible(
    VOID
    );

KVOID*
NalKMemset(
    IN KVOID* Dest,
    IN int Value,
    IN UINTN Size
    );

VOID*
NalKtoUMemcpy(
    IN VOID* Dest,
    IN const KVOID* Source,
    IN UINTN Size
    );

KVOID*
NalKtoKMemcpy(
    IN KVOID* Dest,
    IN const KVOID* Source,
    IN UINTN Size
    );

KVOID*
NalUtoKMemcpy(
    IN KVOID* Dest,
    IN const VOID* Source,
    IN UINTN Size
    );

BOOLEAN
_NalIsResourceExclusive(
    IN NAL_PHYSICAL_ADDRESS PhysicalAddress
    );

#endif
