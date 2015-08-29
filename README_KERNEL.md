Xen Platform Hypervisor 4.2.5
====

(There is a section on Xen-4.1.2 and Xen installation below,
both of which are now obsolete, and only kept for historical reference.)

With the ability to build the Dev86 tools (new as of XLFS-7.0.6), Xen
now is able to build completely (including support for HVM guests,
though this is completely untested).  4.2.5 also introduces `xl` as
the default management tool (instead of `xm`).  I had hoped this would
remove the Python dependency in dom0, but alas, I have not tested it
and it does appear to be needed.

`bridge-utils` is still required (as well as Python2), especially
since `xl` does not do any auto networking configuration.  Fortunately,
XLFS has always done manual bridge configuration, so none is necessary
for Xen.

Also, there are no patches necessary to build Xen-4.2.5 (unlike 4.1.2);
those patches existed to allow Xen to build with the Dev86 toolchain,
and removed support for firmware tools and HVM guests.  This is no
longer the case.

*There is no longer any need for a separate Xen installation guide.*

The `lfs2` script encompasses the entire Xen build, including its
dependencies (like Python).





Configuring Xen
====

There are a few bits of configuration decided "behind-the-scenes" at the moment:

* The amount of memory allocated to dom0 (2 GiB).
* C-State Handling (or, TSC &amp; Time-keeping).
* Disable auto-ballooning.
* Disabling MSI/MSI-X.
* Disabling PCIe ASPM.

There is no dom0 (v)CPU pinning, nor any other Xen hypervisor configuration.
This is advanced Xen admin material; refer to other references if you need
this information.

The lines in question are in `/boot/grub/menu.lst` (and you'll find a symlink
to it in root's home dir; see--I want to make your life more pleasant):

	# [3] X/LAPP Xen
	title [3] X/LAPP Xen                  (LFS-7.0, Linux-3.1, Xen-4.2.5)
        	root(hd0,0)
        	kernel /xen-4.2.5.gz dom0_mem=2048M max_cstate=0 msi=false
        	module /vmlinuz-3.1-lfs-7.0 root=/dev/sda5 raid=noautodetect console=tty0 earlyprintk=xen nomodeset vga=normal nofb video=vesafb:off pcie_aspm=off

And, everything is in the last two lines.  The first affects the hypervisor;
the seconds affects dom0, the virtualization Host OS.



dom0 Memory Allocation
----

The amount of memory allocated to dom0 can be easily changed:

	# cd /boot/grub
	# vi menu.lst

Look for a line like this:

	kernel /xen-4.2.5.gz dom0_mem=2048M max_cstate=0 msi=false

And change the parameter `dom0_mem=2048M` to something like `dom0_mem=1024M`
if you want to change from 2 GiB to 1 GiB.  After the edit that same line
will look like this:

	kernel /xen-4.2.5.gz dom0_mem=1024M max_cstate=0 msi=false



C-State Handling
----

Also, the `max_cstate=0` is a bit of a red herring; The minimum value of
`max_cstate` is 1 (one).  That line simple says that we intend for the value
to be 0 (zero), but are not allowed.

`max_cstate` is itself an advanced issue.  I disable deep(er) C-states for
2 reasons:

* Reduce latency when coming out of C-states (should make the server more responsive).
* Ensures that the TSC doesn't 'warp'.



TSC & Time-keeping
----

This issue is a huge rabbit hole.  The gist is that even on platforms that advertise
`invariant_tsc` and `nonstop_tsc`, Xen may not be able to use the TSC as the platform
timer because deep C-states will cause the TSC to become unsynchronized between cores.
As a result, domU (and dom0) time can become very inaccurate.  For database applications,
this is pretty unacceptable.  So, I disable them.  For more information on timekeeping
in Xen, refer to this README (which is part of the Xen Project Hypervisor distribution):

[TSC`_`MODE HOW-TO (by Dan Magenheimer)](http://xenfromscratch.org/xen-timekeeping/tscmode.txt)

My (empirical but amateur) advice on the matter:

> Run NTP in dom0.  Figure how to run your system so that Xen can use the TSC.  Do not
> run NTP in domUs.  Allow domUs to use `rdtsc` (if your system is safe, or hope that it
> supports `rdtscp`).  Cross fingers.

> Follow mailing-lists devoted to this.

> Look up time-nuts on the interwebs.

Keep your garlic and rabbit-ears and other good-luck charms handy.



Disabling auto-ballooning
----

This is considered a best practice.  Manually allocate memory to dom0 and your domUs, and
you won't need this.  This is imoprtant for dom0, because if it loses too much memory, it
will not be able to operate the disks and networks.  This is probably VeryBad&trade;.



Disabling MSI/MSI-X
----

Wikipedia tells us that MSI/MSI-X is an OOB interrupt service, which seems like a really
nice-to-have.  However, some boards have a broken MSI subsystem.  So, I disable it.  If you know
your board has a working MSI subsystem, go ahead &amp; enable it.  You're on your own.

Searching around for this reveals that it might have some impacts on HPET broadcasts...

I can't say how this will affect your particular system.



Disabling PCIe ASPM
----

ASPM: Active State Power Management.  In theory, it enables PCIe devices to be put into
lower power modes to decrease power use.  I disable it because it appears to cause some
problems with Intel NICs.  See here:

> [e1000e Reset adapter unexpectedly / Detected Hardware Unit Hang](http://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang)

> [Linux e1000e (Intel networking driver) problems galore, where do I start?](http://serverfault.com/questions/193114/linux-e1000e-intel-networking-driver-problems-galore-where-do-i-start)

So, I disable it.  Also, ASPM causes latency.  So, it's an added bonus.  I'm not sure
how often this affects RAID cards (since they're probably always busy), but it's nice
to know that they're always ready to go with `pcie_aspm=off`.





Kernel Configuration
====

Configure kernel for domU (guest operating system)
----

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

See an example domU configuration at: [https://github.com/qrux/xlfs/blob/master/xlapp-linux-3.1-domU.config]

Configure kernel for dom0 (host operating system)
----

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

See an example dom0 configuration at: [https://github.com/qrux/xlfs/blob/master/xlapp-linux-3.1-dom0.config]



__Parts below are obsolete.__



Xen-4.1.2 __(obsolete)__
====

Introduction to Xen
----

Xen is a virtualization platform, and offers a powerful, efficient, and secure feature
set for virtualization of `x86`, `x86_64`, `IA64`, `ARM`, and other CPU architectures.
It supports a wide range of guest operating systems including Windows®, Linux®, Solaris®,
and various versions of the BSD operating systems.  The Xen hypervisor is a Type-1
hypervisor that can support Linux as a host operating system.


Package Information
----

Download (HTTP): http://bits.xensource.com/oss-xen/release/4.1.2/xen-4.1.2.tar.gz<br />
Download (Format?) Signature: http://bits.xensource.com/oss-xen/release/4.1.2/xen-4.1.2.tar.gz.sig<br />
Download size: 9.9 MB<br />
Estimated disk space required: ?<br />
Estimated build time: 3 SBU<br />


Additional Downloads
----

Required patches: [https://github.com/qrux/xlfs/blob/master/src/xen-4.1.2-no_firmware-1.patch](https://github.com/qrux/xlfs/blob/master/src/xen-4.1.2-no_firmware-1.patch)

*(Update 2015: This patch no longer exists.)*

Additional Bootscripts: [https://github.com/qrux/xlfs/blob/master/xlapp-bootscripts/xlapp-domains](https://github.com/qrux/xlfs/blob/master/xlapp-bootscripts/xlapp-domains)


Xen Dependencies
----
*Required* - openssl-1.0.0e, bridge-utils-1.5, Python2

*Optional* - X Window System, Dev86, 32-bit glibc, acpica.  Note that this optional dependencies list is not comprehensive.  See http://xen.org/ for a more complete list.


Xen prerequisites
----

These directions build a "pure 64-bit" version of Xen.  That means, only 64-bit host operating system are supported, and 64-bit guest operating systems are supported.  These instructions are intended to help you build an LFS/BLFS system which acts as a Xen host, that will run LFS/BLFS systems as Xen guests.  If you have more complex needs (i.e., you want to run Windows(™) or other unmodified guest operating systems), you'll need to look into the optional dependencies to build a Xen toolchain that will support 32-bit guests or unmodified guests.

Xen 4 requires at least a Linux 3.0 kernel.  In addition, to build the Xen host OS for Linux, ACPI support needs to be enabled.  Make sure you enable ACPI support or you won't be able to compile a Linux host.



Installation of Xen __(obsolete)__
====

Install Xen by running the following commands:

	patch -Np1 -i ../xen-4.1.2-no_firmware-1.patch

Then, disable the checks for X11.  In tools/check, the scripts look for files named
`check_*` and run them to detect features on the build system.  We're just going to
make a subdirectory called "NOUSE", and move the script to detect X11 into that
directory so it's not run.

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





Known Issues __(obsolete)__
====

* []()http://wiki.xen.org/xenwiki/Xen4.0)

> "Some Xen 4.0 users have had problems with interrupts getting frozen
> on Intel Xeon platforms, causing raid adapters to freeze and disk IO
> to stall. This is due to hpet broadcast (hpet timer migration) issues.
> The quick fix is to add `cpuidle=off` or `max_cstate=1` cmdline
> parameters for xen.gz in grub.conf. See these emails for more information:

> [[Xen-devel] Instability with Xen, interrupt routing frozen, HPET broadca](http://lists.xensource.com/archives/html/xen-devel/2010-09/msg00556.html)

> [RE: [Xen-devel] Instability with Xen, interrupt routing frozen, HPET bro](http://lists.xensource.com/archives/html/xen-devel/2010-09/msg01749.html)

*(Update 2015: This probably has to do with MSI/MSI-X interrupts, too.)*
