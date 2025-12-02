/*
 * Intel QV Linux kernel driver
 * Copyright (c) 1999 - 2022, Intel Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

/*
 *
 * Module Name:
 *   linuxnaldriver.c
 *
 * Abstract:
 *   This contains the functions necessary for the Linux Driver
 *   component of NAL to function as a driver. This includes the
 *   driver entry point and all Linux specific ring 0 functions.
 *
 *
 */


#include <linux/slab.h>
#include <linux/module.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/pci_ids.h>
#include <linux/errno.h>
#include <linux/fs.h>
#include <linux/mm.h>
#include <linux/version.h>
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,12,0)
#include <linux/uaccess.h>
#else
#include <asm/uaccess.h>
#endif
#include "naltypes.h"
#include "nalioctl.h"
#include "linuxnaldriver.h"

int
init_module(void);
void
cleanup_module(void);

extern spinlock_t Global_AtomicTestSetSpinLock;
static char Global_NalDeviceName[] = NAL_OS_SPEC_QV_DRIVER_NAME;
static int Global_NalMajor = 0;
NAL_OS_SPEC_ADAPTER_IN_USE_TABLE Global_AdapterInUse[NAL_OS_SPEC_MAX_PCI_DEVICES];
UINT32 Global_DriverReferenceCount = 0;

static struct file_operations Global_NalFops =
{
    owner: THIS_MODULE,

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,36)
    ioctl: NalDeviceControl,
#endif
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,10)

    unlocked_ioctl: NalDeviceControlUnlockedIoctl,
#endif
    open: NalOpen,
    release: NalRelease,
    mmap: NalMmap
};

MODULE_AUTHOR(NAL_OS_SPEC_DRIVER_COMPANYNAME);
MODULE_DESCRIPTION(NAL_OS_SPEC_DRIVER_DESCRIPTION);
MODULE_LICENSE("GPL");
MODULE_VERSION(NAL_OS_SPEC_DRIVER_VERSION);

int
init_module(void)
{
    int Result = 0;
    UINT32 i = 0;

    printk(KERN_DEBUG "Intel Pro Diagnostic Driver loading (v. %s)\n", NAL_OS_SPEC_DRIVER_VERSION);
    Result = register_chrdev(0, Global_NalDeviceName, &Global_NalFops);
    if(Result < 0)
    {
        Result = -ENODEV;
    }
    else
    {
        Global_NalMajor = Result;
        Result = 0;
    }

    for(i=0; i<NAL_OS_SPEC_MAX_PCI_DEVICES; i++)
    {
        memset(&Global_AdapterInUse[i], 0, sizeof(NAL_OS_SPEC_ADAPTER_IN_USE_TABLE));
    }

    spin_lock_init(&Global_AtomicTestSetSpinLock);

    return Result;
}

void
cleanup_module(void)
{
    printk(KERN_DEBUG "Intel Pro Diagnostic Driver exiting\n");
    unregister_chrdev(Global_NalMajor, Global_NalDeviceName);
}

long
NalDeviceControlUnlockedIoctl(
    struct file* File,
    unsigned int Cmd,
    unsigned long Arg
    )

{
    return NalDeviceControl(NULL, File, Cmd, Arg);
}

int
NalDeviceControl(
    struct inode* Inode,
    struct file* File,
    unsigned int Cmd,
    unsigned long Arg
    )
{
    NAL_IOCTL_INPUT_DATA* NalIoctlInputData =
        (NAL_IOCTL_INPUT_DATA*)kmalloc(sizeof(NAL_IOCTL_INPUT_DATA), GFP_KERNEL);
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
    mm_segment_t old_fs;
#endif
    UINT32 IoctlNumber = 0;
    int Result = 0;

    do
    {
        if(NalIoctlInputData == NULL)
        {
            Result = ENOMEM;
            break;
        }

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
        old_fs = get_fs();
        set_fs(get_ds());
        Result = copy_from_user(NalIoctlInputData, (void*)Arg, sizeof(NAL_IOCTL_INPUT_DATA));
        set_fs(old_fs);
#else
        Result = copy_from_user(NalIoctlInputData, (void*)Arg, sizeof(NAL_IOCTL_INPUT_DATA));
#endif
        if(Result != 0)
        {
            break;
        }

        IoctlNumber = Cmd;

        switch (IoctlNumber)
        {
        case IOCTL_NAL_OSI:
            NalResolveOsiIoctl(NalIoctlInputData);
            break;

        case IOCTL_NAL_HW_BUS:
            NalResolveHwBusIoctl(NalIoctlInputData);
            break;

        case IOCTL_NAL_NDI:
            NalResolveNdiIoctl(NalIoctlInputData);
            break;

        case IOCTL_NAL_OS_SPECIFIC:
            NalResolveOsSpecificIoctl(NalIoctlInputData);
            break;

        default:

            Result = EINVAL;
            break;
        }

        if(Result != 0)
        {
            break;
        }

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
        old_fs = get_fs();
        set_fs(get_ds());
        Result = copy_to_user((void*)Arg, NalIoctlInputData, sizeof(NAL_IOCTL_INPUT_DATA));
        set_fs(old_fs);
#else
        Result = copy_to_user((void*)Arg, NalIoctlInputData, sizeof(NAL_IOCTL_INPUT_DATA));
#endif
    } while(0);

    if(NalIoctlInputData != NULL)
    {
        kfree(NalIoctlInputData);
    }

    return Result;
}

int
NalOpen(
    struct inode* Inode,
    struct file* File
    )
{
    return 0;
}

int
NalRelease(
    struct inode* Inode,
    struct file* File
    )
{
    return 0;
}

int
NalMmap(
    struct file* File,
    struct vm_area_struct* Vma
    )
{
    if(io_remap_pfn_range(Vma,
                          Vma->vm_start,
                          Vma->vm_pgoff,
                          Vma->vm_end - Vma->vm_start,
                          Vma->vm_page_prot))
    {
        return -EAGAIN;
    }

    return 0;
}

UINT32
_NalDriverGetReferenceCount(
 VOID
 )
{
    return Global_DriverReferenceCount;
}

VOID
_NalDriverIncrementReferenceCount(
    VOID
    )
{

    spin_lock(&Global_AtomicTestSetSpinLock);
    Global_DriverReferenceCount++;
    spin_unlock(&Global_AtomicTestSetSpinLock);
}

VOID
_NalDriverDecrementReferenceCount(
    VOID
    )
{

    spin_lock(&Global_AtomicTestSetSpinLock);
    if(Global_DriverReferenceCount > 0)
    {
        Global_DriverReferenceCount--;
    }
    spin_unlock(&Global_AtomicTestSetSpinLock);
}

VOID
_NalDriverGetVersion(
 OUT CHAR* Version
 )
{
    sprintf(Version, "%d.%d.%d.%d",
                                   NAL_OS_SPEC_DRIVER_MAJOR_VERSION ,
                                   NAL_OS_SPEC_DRIVER_MINOR_VERSION ,
                                   NAL_OS_SPEC_DRIVER_BUILD_VERSION ,
                                   NAL_OS_SPEC_DRIVER_FIX_VERSION );
}
