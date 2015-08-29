What is XLFS?
====

XLFS stands for "Xen &amp; Linux from Scratch".  It's a collection of shell scripts which builds an
entire virtualization-capable OS from scratch, including the virtualization stack (hypervisor, host OS,
host tools, and VMs) and a few application stacks.

> *Yep, the whole OS is built entirely from source code.*

It produces a Xen Project Hypervisor 4.2.5 running on bare metal
with Linux systems used as the virtualization Host OS and also the Guest VM OSes.  The Linux systems
are based primarily on <a href="#attrib-lfs">LFS</a> and <a href="#attrib-blfs">BLFS</a>, and use a 3.1
kernel with a typical GNU/Linux userspace.  XLFS source is hosted on GitHub:

> [http://github.com/qrux/xlapp](http://github.com/qrux/xlapp/)

"LFS" stands for "Linux from Scratch".  It's a good base on which to build Xen, because the system isn't large.
It's also fully comprehensible, because it's relatively small and comes with a fantastically good blueprint.

> You know how your iPhone doesn't come with a manual?<br/>
> Yeah.  This is the polar opposite of that.

That's because LFS itself is a project intended to teach people how Linux works, and takes the form of a book which
provides an incredibly detailed guide for a person wishing to compile an entire GNU/Linux operating from source. BLFS
is similar, giving directions to build and install packages not in the base LFS system (which can be considered
somewhat "minimal").  Find LFS here:

> [http://www.linuxfromscratch.org/](http://www.linuxfromscratch.org/)

The Xen Project Hypervisor is the leading open source virtualization platform powering some of the largest clouds in
production today. Amazon Web Services, Rackspace Public Cloud and Verizon Cloud and many hosting services use Xen
Project software.

Xen is a virtualization platform, and offers a powerful, efficient, and secure feature
set for virtualization of `x86`, `x86_64`, `IA64`, `ARM`, and other CPU architectures.
It supports a wide range of guest operating systems including Windows®, Linux®, Solaris®,
and various versions of the BSD operating systems.  The Xen hypervisor is a Type-1
hypervisor that can support Linux as a host operating system.  Find the Xen Project here:

> [http://xenproject.org/](http://xenproject.org/)

Finally, the XLFS project homepage (if you're coming from a search engine or GitHub):

> [http://xenfromscratch.org/](http://xenfromscratch.org/)



Goals
----

The goal is to minimize Linux- and Xen-related bloat in a virtualization platform. In the guests, my goal is to run
various templatized installs, for instance, a LAPP server or a SMTP/IMAP server, which are also kept somehwat minimal.
An important part of this goal is to be able to run headless with, at most, a text console (80x25), a colo-friendly
capability.

A secondary goal is to create a system which has a relatively small security footprint. Eliminating bloat helps
accomplish this. Installing packages by hand--in the LFS/BLFS style--also makes packages easier to upgrade. On the
downside, there is no simple packaging system or package manager (e.g., RPM, apt). On the upside, CMMI works
tremendously well, especially when coupled with BLFS. Many of the XLFS scripts are based directly from the LFS/BLFS
builds.



Motivation
----

For years, I've run RedHat, SuSE, and Ubuntu systems in production. Commercial distros have the benefit of
sophisticated packaging and configuration systems. RPM, Yast, and `apt` are a higher level of use and abstraction from
CMMI and vi. However, while configuration systems can be learned, the packaging systems are hard to work around when
they bundle unwanted dependencies.

The last straw was working with Xen on SuSE. SuSE requires Python for Xen, which I suppose is not totally
unreasonable. But, the fact that SuSE's Python requires X11, and that's a huge amount of bloat to accommodate a
baremetal hypervisor.

It seems quite plausible that most installation of Xen are 1) deployed on headless servers, and 2) running headless
guests.  Consider that Netflix, the generator of the most traffic on the Internet, uses AWS, which uses Xen as its
virtualization infrastructure.  In those cases, tainted graphics drivers, X11, desktop libraries (ALSA, etc) are
unnecessary.  And, it's quite possible that enterprise features like Kerberos and LDAP should be unnecessary in the host.

Running a Xen cluster should place as few dependencies on Domain 0 (the priviledged Host OS in Xen) as possible;
that way, the machine runs leaner, uses less disk space, and has a smaller attackable footprint. It's unreasonable
to install dozens of userland packages that never get used in the virtualization Host OS.



Overview
----

XLFS is an entire OS compiled from source system. It needs to be bootstrapped from a system that has a working
compiler and set of tools that are used to build XLFS. Refer to the requirements here:

> [http://www.linuxfromscratch.org/lfs/view/7.0/prologue/hostreqs.html](http://www.linuxfromscratch.org/lfs/view/7.0/prologue/hostreqs.html)

I chose LFS as the base system for XLFS (the name came after the choice, in case you thought that was rhetorical),
because it meets the criteria for the "smallest usable" toolchain for Xen and Linux.

While the project itself makes it quite clear that it doesn't consider itself to be a "minimal system", for my
purposes it meets the criteria for the "smallest usable" toolchain. Additionally, its editors and contributors are
knowledgeable, and support for the core project is strong. This makes it possible to further minimize the LFS core.

LFS itself requires a "host" system (this is *NOT* the same as a virtualization "host") from which
to be bootstrapped. The obvious choice seemed to be an easy-to-install commercial distro. Finally, a good use for
those SuSE images! I chose OpenSuSE-11.4, because 1) I'm familiar with it, and 2) it meets the host requirements,
allowing XLFS to compile "out-of-the-box".

Newer versions of SuSE don't compile LFS-7.0 out-of-the-box.  See here:

> [http://osdir.com/ml/bug-m4-gnu/2011-07/msg00002.html](http://osdir.com/ml/bug-m4-gnu/2011-07/msg00002.html)

After installing the host build system according to the guide (with accommodations for building XLFS), the XLFS
scripts should be put into a directory in root's home directory. From there, the build can be started, which should
compile an entire LFS build. This is referred to as *Phase 1*.

After Phase 1, the system can be booted into the freshly-compiled bare metal LFS system. From there, the scripts
(which can be found again in root's home directory) can be run to compile and install the Xen Project hypervisor.
This is referred to as *Phase 2*.

After Phase 2, you can create VMs.



Next
----

Go on to [Build](?page=build).
