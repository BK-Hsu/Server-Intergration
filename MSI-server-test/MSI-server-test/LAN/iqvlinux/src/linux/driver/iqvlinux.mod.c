#include <linux/module.h>
#define INCLUDE_VERMAGIC
#include <linux/build-salt.h>
#include <linux/elfnote-lto.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

BUILD_SALT;
BUILD_LTO_INFO;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif

static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0xe49bb82b, "module_layout" },
	{ 0x6bc3fbc0, "__unregister_chrdev" },
	{ 0x85bd1608, "__request_region" },
	{ 0x3703b5ff, "kmalloc_caches" },
	{ 0xe5ac9a30, "pci_write_config_dword" },
	{ 0x3753dfce, "pci_bus_type" },
	{ 0xeb233a45, "__kmalloc" },
	{ 0x4451c68e, "pci_write_config_word" },
	{ 0x77358855, "iomem_resource" },
	{ 0xda79796f, "pci_read_config_byte" },
	{ 0xcf241651, "dma_set_mask" },
	{ 0x98b258fd, "pci_get_slot" },
	{ 0xc8621f5c, "pci_disable_device" },
	{ 0x7a7b2bd8, "__register_chrdev" },
	{ 0xccbc9d33, "pci_write_config_byte" },
	{ 0xeae3dfd6, "__const_udelay" },
	{ 0xae462575, "dma_free_attrs" },
	{ 0x3c3ff9fd, "sprintf" },
	{ 0x4f5aee3b, "pv_ops" },
	{ 0x4cba64b7, "dma_set_coherent_mask" },
	{ 0x6b10bee1, "_copy_to_user" },
	{ 0x5b8239ca, "__x86_return_thunk" },
	{ 0x3abee171, "pci_set_master" },
	{ 0xfb578fc5, "memset" },
	{ 0xdbdf6c92, "ioport_resource" },
	{ 0xde80cd09, "ioremap" },
	{ 0x4c9d28b0, "phys_base" },
	{ 0x14743fb4, "dma_alloc_attrs" },
	{ 0x3cf1df41, "pci_find_bus" },
	{ 0x7cd8d75e, "page_offset_base" },
	{ 0x87a21cb3, "__ubsan_handle_out_of_bounds" },
	{ 0xbe037e99, "iommu_present" },
	{ 0xd0da656b, "__stack_chk_fail" },
	{ 0x92997ed8, "_printk" },
	{ 0xe6edc564, "pci_read_config_dword" },
	{ 0xbdfb6dbb, "__fentry__" },
	{ 0x1035c7c2, "__release_region" },
	{ 0x60f64c0d, "kmem_cache_alloc_trace" },
	{ 0xba8fbd64, "_raw_spin_lock" },
	{ 0x37a0cba, "kfree" },
	{ 0x775480, "remap_pfn_range" },
	{ 0x69acdf38, "memcpy" },
	{ 0xedc03953, "iounmap" },
	{ 0x84f66777, "pci_dev_put" },
	{ 0x7ec807e2, "pci_enable_device" },
	{ 0x13c49cc2, "_copy_from_user" },
	{ 0x78b887ed, "vsprintf" },
	{ 0x9e7d6bd0, "__udelay" },
	{ 0x88db9f48, "__check_object_size" },
	{ 0x8a35b432, "sme_me_mask" },
};

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "36F8BFC57FEC56C8B8C4DAB");
