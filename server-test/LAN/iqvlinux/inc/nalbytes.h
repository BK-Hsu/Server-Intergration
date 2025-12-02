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

/*
 *
 * Module Name:
 *   nalbytes.h
 *
 * Abstract:
 *   This file contains macros for operations on primitive types like
 *   words, dwords and qwords.
 *
 */

#ifndef INC_NALBYTES_H_
#define INC_NALBYTES_H_ 

#ifndef HIBYTE
    #define HIBYTE(_x) (UINT8)(((_x)>>8)&0xFF)
#endif

#ifndef LOBYTE
    #define LOBYTE(_x) (UINT8)((_x)&0xFF)
#endif

#ifndef HIWORD
    #define HIWORD(_x) ((UINT16)(((_x)>>16)&0xFFFF))
#endif

#ifndef LOWORD
    #define LOWORD(_x) ((UINT16)((_x)&0xFFFF))
#endif

#ifndef HIDWORD
    #define HIDWORD(_x) ((UINT32)(((_x)>>32)&0xFFFFFFFF))
#endif

#ifndef LODWORD
    #define LODWORD(_x) ((UINT32)((_x)&0xFFFFFFFF))
#endif

#ifndef LOW_BYTE
    #define LOW_BYTE(word) LOBYTE(word)
#endif

#ifndef HIGH_BYTE
    #define HIGH_BYTE(word) HIBYTE(word)
#endif

#ifndef LOW_WORD
    #define LOW_WORD(dword) LOWORD(dword)
#endif

#ifndef HIGH_WORD
    #define HIGH_WORD(dword) HIWORD(dword)
#endif

#ifndef MAKE_WORD
    #define MAKE_WORD(hi, low) ((UINT16) ((((UINT16)(hi)) << 8) | (low)))
#endif

#ifndef MAKE_DWORD
    #define MAKE_DWORD(hi, low) ((UINT32) ((((UINT32)(hi)) << 16) | (low)))
#endif

#ifndef MAKE_QWORD
    #define MAKE_QWORD(hi, low) ((UINT64) ((((UINT64)(hi)) << 32) | (low)))
#endif

#ifndef WORD_SWAP_BYTE_ARRAY
#define WORD_SWAP_BYTE_ARRAY(word) (UINT16)( (((UINT16)(word) & 0x00ff) << 8) | \
                                                (((UINT16)(word) & 0xff00) >> 8) )
#endif

#ifndef DWORD_SWAP_BYTE_ARRAY
#define DWORD_SWAP_BYTE_ARRAY(dword) (UINT32)( (((UINT32)(dword) & 0x000000ff) << 24) | \
                                                (((UINT32)(dword) & 0x0000ff00) << 8) | \
                                                (((UINT32)(dword) & 0x00ff0000) >> 8) | \
                                                (((UINT32)(dword) & 0xff000000) >> 24) )
#endif

#if defined NAL_BIG_ENDIAN

#ifndef BYTE_SWAP_WORD
    #define BYTE_SWAP_WORD(value) (UINT16)( (((UINT16)(value) & 0x00ff)) | \
                                                (((UINT16)(value) & 0xff00)) )
#endif

#ifndef BYTE_SWAP_DWORD
    #define BYTE_SWAP_DWORD(dword) (UINT32)( (((UINT32)(dword) & 0x000000ff) << 24) | \
                                                (((UINT32)(dword) & 0x0000ff00) << 8) | \
                                                (((UINT32)(dword) & 0x00ff0000) >> 8) | \
                                                (((UINT32)(dword) & 0xff000000) >> 24) )
#endif

#ifndef WORD_SWAP_DWORD
    #define WORD_SWAP_DWORD(value) (UINT32)( (((UINT32)(value) & 0x0000FFFF) << 16) | \
                                                (((UINT32)(value) & 0xFFFF0000) >> 16) )
#endif

#ifndef BYTE_SWAP_QWORD
    #define BYTE_SWAP_QWORD(_dest, _src) \
        { \
        ((UINT8*)_dest)[0] = ((UINT8*)_src)[7]; \
        ((UINT8*)_dest)[1] = ((UINT8*)_src)[6]; \
        ((UINT8*)_dest)[2] = ((UINT8*)_src)[5]; \
        ((UINT8*)_dest)[3] = ((UINT8*)_src)[4]; \
        ((UINT8*)_dest)[4] = ((UINT8*)_src)[3]; \
        ((UINT8*)_dest)[5] = ((UINT8*)_src)[2]; \
        ((UINT8*)_dest)[6] = ((UINT8*)_src)[1]; \
        ((UINT8*)_dest)[7] = ((UINT8*)_src)[0]; \
        }
#endif

#ifndef WORD_SWAP
    #define WORD_SWAP(dword) WORD_SWAP_DWORD(dword)
#endif

#ifndef BYTE_SWAP
    #define BYTE_SWAP(word) BYTE_SWAP_WORD(word)
#endif

#else

#ifndef BYTE_SWAP_WORD
    #define BYTE_SWAP_WORD(value) (UINT16)( (((UINT16)(value) & 0x00ff) << 8) | \
                                                (((UINT16)(value) & 0xff00) >> 8) )
#endif

#ifndef BYTE_SWAP_DWORD
    #define BYTE_SWAP_DWORD(dword) (UINT32)( (((UINT32)(dword) & 0x000000ff) << 24) | \
                                                (((UINT32)(dword) & 0x0000ff00) << 8) | \
                                                (((UINT32)(dword) & 0x00ff0000) >> 8) | \
                                                (((UINT32)(dword) & 0xff000000) >> 24) )
#endif

#ifndef WORD_SWAP_DWORD
    #define WORD_SWAP_DWORD(value) (UINT32)( (((UINT32)(value) & 0x0000FFFF) << 16) | \
                                                (((UINT32)(value) & 0xFFFF0000) >> 16) )
#endif

#ifndef BYTE_SWAP_QWORD
    #define BYTE_SWAP_QWORD(_dest, _src) \
        { \
        ((UINT8*)_dest)[0] = ((UINT8*)_src)[7]; \
        ((UINT8*)_dest)[1] = ((UINT8*)_src)[6]; \
        ((UINT8*)_dest)[2] = ((UINT8*)_src)[5]; \
        ((UINT8*)_dest)[3] = ((UINT8*)_src)[4]; \
        ((UINT8*)_dest)[4] = ((UINT8*)_src)[3]; \
        ((UINT8*)_dest)[5] = ((UINT8*)_src)[2]; \
        ((UINT8*)_dest)[6] = ((UINT8*)_src)[1]; \
        ((UINT8*)_dest)[7] = ((UINT8*)_src)[0]; \
        }
#endif

#ifndef WORD_SWAP
    #define WORD_SWAP(dword) WORD_SWAP_DWORD(dword)
#endif

#ifndef BYTE_SWAP
    #define BYTE_SWAP(word) BYTE_SWAP_WORD(word)
#endif

#endif

#define MAKE_DATA_WORD_TCP_CHECKSUM(hi,low) \
    ((UINT16) ((((UINT16)(hi)) << 8) | (low)))

#define MAKE_DATA_WORD_UDP_CHECKSUM(hi,low) \
    ((UINT16) ((((UINT16)(hi)) << 8) | (low)))

#ifndef ARE_ALL_FLAGS_SET
    #define ARE_ALL_FLAGS_SET(VALUE,FLAGS) ( ((VALUE) & (FLAGS) ) == (FLAGS) )
#endif

#ifndef ARE_ALL_FLAGS_CLEAR
    #define ARE_ALL_FLAGS_CLEAR(VALUE,FLAGS) ( ((VALUE) & ~(FLAGS) ) == 0 )
#endif

#ifndef IS_AT_LEAST_ONE_FLAG_SET
    #define IS_AT_LEAST_ONE_FLAG_SET(VALUE,FLAGS) ( ((VALUE) & (FLAGS)) != 0 )
#endif

#ifndef IS_AT_LEAST_ONE_FLAG_CLEAR
    #define IS_AT_LEAST_ONE_FLAG_CLEAR(VALUE,FLAGS) ( ((VALUE) & ~(FLAGS)) != 0 )
#endif

#define ROUNDUP(i,size) ((i) = (((i) + (size) - 1) & ~((size) - 1)))

#endif
