Xen-4.1.2
=========

Introduction to Xen
===================

Xen is a virtualization platform, and offers a powerful, efficient, and secure feature set for virtualization of x86, x86_64, IA64, ARM, and other CPU architectures. It supports a wide range of guest operating systems including Windows®, Linux®, Solaris®, and various versions of the BSD operating systems.  The Xen hypervisor is a Type-1 hypervisor that can support Linux as a host operating system.


Package Information
-------------------

Download (HTTP): http://bits.xensource.com/oss-xen/release/4.1.2/xen-4.1.2.tar.gz<br />
Download (Format?) Signature: http://bits.xensource.com/oss-xen/release/4.1.2/xen-4.1.2.tar.gz.sig<br />
Download size: 9.9 MB<br />
Estimated disk space required: ?<br />
Estimated build time: 3 SBU<br />


Additional Downloads
--------------------

Required patches: https://github.com/qrux/xlapp/blob/master/src/xen-4.1.2-no_firmware-1.patch<br />
Additional Bootscripts: https://github.com/qrux/xlapp/blob/master/xlapp-bootscripts/xlapp-domains


Xen Dependencies
----------------
*Required* - openssl-1.0.0e, bridge-utils-1.5, Python2

*Optional* - X Window System, Dev86, 32-bit glibc, acpica.  Note that this optional dependencies list is not comprehensive.  See http://xen.org/ for a more complete list.


Xen prerequisites
=================

These directions build a "pure 64-bit" version of Xen.  That means, only 64-bit host operating system are supported, and 64-bit guest operating systems are supported.  These instructions are intended to help you build an LFS/BLFS system which acts as a Xen host, that will run LFS/BLFS systems as Xen guests.  If you have more complex needs (i.e., you want to run Windows(™) or other unmodified guest operating systems), you'll need to look into the optional dependencies to build a Xen toolchain that will support 32-bit guests or unmodified guests.

Xen 4 requires at least a Linux 3.0 kernel.  In addition, to build the Xen host OS for Linux, ACPI support needs to be enabled.  Make sure you enable ACPI support or you won't be able to compile a Linux host.


Kernel Configuration
====================

Configure kernel for domU (guest operating system)
--------------------------------------------------

Enable these core options (Processor type and features -> Paravirtualized guest support)

	CONFIG_PARAVIRT=y
	CONFIG_XEN=y
	CONFIG_PARAVIRT_GUEST=y
	CONFIG_PARAVIRT_SPINLOCKS=y

Xen pv console device support (Device Drivers -> Character devices)

	CONFIG_HVC_DRIVER=y
	CONFIG_HVC_XEN=y

Xen disk and network support (Device Drivers -> Block devices and Device Drivers -> Network device support)

	CONFIG_XEN_FBDEV_FRONTEND=y
	CONFIG_XEN_BLKDEV_FRONTEND=y
	CONFIG_XEN_NETDEV_FRONTEND=y

System drivers (Device Drivers -> Xen driver support)

	CONFIG_XEN_PCIDEV_FRONTEND=y
	CONFIG_INPUT_XEN_KBDDEV_FRONTEND=y
	CONFIG_XEN_FBDEV_FRONTEND=y
	CONFIG_XEN_XENBUS_FRONTEND=y
	CONFIG_XEN_SAVE_RESTORE=y
	CONFIG_XEN_GRANT_DEV_ALLOC=y

For tmem support:

	CONFIG_XEN_TMEM=y
	CONFIG_CLEANCACHE=y
	CONFIG_FRONTSWAP=y
	CONFIG_XEN_SELFBALLOONING=y

See an example domU configuration at: [https://github.com/qrux/xlapp/blob/master/xlapp-linux-3.1-domU.config]

Configure kernel for dom0 (host operating system)
-------------------------------------------------

In addition to the config options above, you also need to enable:

	CONFIG_X86_IO_APIC=y
	CONFIG_ACPI=y
	CONFIG_ACPI_PROCFS=y (optional)
	CONFIG_XEN_DOM0=y
	CONFIG_PCI_XEN=y
	CONFIG_XEN_DEV_EVTCHN=y
	CONFIG_XENFS=y
	CONFIG_XEN_COMPAT_XENFS=y
	CONFIG_XEN_SYS_HYPERVISOR=y
	CONFIG_XEN_GNTDEV=y
	CONFIG_XEN_BACKEND=y
	CONFIG_XEN_NETDEV_BACKEND=y
	CONFIG_XEN_BLKDEV_BACKEND=y
	CONFIG_XEN_PCIDEV_BACKEND=y
	CONFIG_XEN_PRIVILEGED_GUEST=y
	CONFIG_XEN_BALLOON=y
	CONFIG_XEN_SCRUB_PAGES=y
	CONFIG_XEN_DEV_EVTCHN=y
	CONFIG_XEN_GNTDEV=y

And, for networking configuration support:

	CONFIG_BRIDGE=y
	CONFIG_STP=y

See an example dom0 configuration at: [https://github.com/qrux/xlapp/blob/master/xlapp-linux-3.1-dom0.config]


Installation of Xen
===================

Install Xen by running the following commands:

	patch -Np1 -i ../xen-4.1.2-no_firmware-1.patch

Then, disable the checks for X11.  In tools/check, the scripts look for files named check_* and run them to detect features on the build system.  We're just going to make a subdirectory called "NOUSE", and move the script to detect X11 into that directory so it's not run.

	pushd tools/check
	mkdir NOUSE
	mv check_x11_devel NOUSE
	popd

Then, make sure that the linker cache is up-to-date (otherwise, some libs, notably OpenSSL's libcrypto, won't be found).

Now, as the *root* user:

	ldconfig -v

Then, making sure you're not executing a serial make:

	export MAKEFLAGS="-j 1"

Build Xen by running the following commands:

	make xen
	make tools

Now, as the *root* user:

	make install-xen
	make install-tools
	install -m 0754 ../xlapp-domains /etc/init.d

Configuring Xen
===============

(Not sure that this should be at this location in the book.  Maybe this should be another page, but also in the Virt section…)
