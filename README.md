What is XLAPP?
==

XLAPP is a set of scripts that creates a virtualization-capable Linux system using Xen.

It's not a distro, per se, in that the goal is to minimize bloat.  Most bloat comes from X11 and the huge array of packages and services envisioned for huge enterprises (Gnome, KDE, LDAP, Kerberos/OpenDirectory, etc).

It stands for "Xen LFS APP".  The "APP" can mean anything you want.  Maybe "application".  Or "appliance".  It was, at the start, meant to be a take on "LAPP", but since XLAPP now supports multiple server types that have nothing to do with a traditional web stack, it just didn't make sense to tie it to any particular use.

Well, LFS itself stands for "Linux From Scratch".  It's a project intended to teach people how Linux works, and is a book intended to guide a user through the entire process of compiling Linux from source.  XLAPP, then, is a way to compile the entire OS, the virtualization stack (hypervisor, kernel, and tools), plus a
few application stacks entirely from source code.

How does it work?
--

Since XLAPP is a compiled-from-source system, you first have to start with a system that has a working compiler and set of tools that are used to build XLAPP.  Refer to the requirements here:

	http://www.linuxfromscratch.org/lfs/view/7.0/prologue/hostreqs.html

I use openSUSE-11.4.  It meets all the requirements to build LFS-7.0, the base system.  That's all I'm looking for.  Plus, I put the ISO image on a thumb drive, and it means my servers don't need CD drives.  It also means my installs go much faster.  Since you can't find version 11.4 anywhere (now that 12+ is out), I'll be hosting a copy myself soon.  No, don't use version 12+ (or later).  I've already tried it, and while all the prerequisite packages are newer, they are "too new."  They cause LFS-7.0 not to build properly (a lot of the regression tests fails, due to some recent changes).  There are some details below.

TL;DR
--

* Install the host system (e.g., openSUSE-11.4).
** Create 3 partitions: /boot, /, and /mnt/lfs partitions.
** Give /boot at least 256 MB.  I use 2 GB myself.
** Give / no more than 8 GB.  Give /mnt/lfs at least 8.  If you use less, you're on your own.
* When install is finished, give yourself SSH access from the machine you intend to work from (say, your laptop).
* SSH in.

	cd /
	tar xf xlapp-984985.tar.gz # (or whatever version your tarball is)
	cd ~
	ln -s /lfs lfs
	cd lfs/src
	wget -nc -i wget-list
	cd ..
	./lfs

Then, just answer the questions (paying particular attention to the root password and the SSH key; that's how you'll gain access to the new system).

About 3 hours later, (on an 1st-gen i5), you'll have a bootable XLAPP-Phase-1 system (with SSH access).  When it's finished (assuming it finishes without error), it will have modified the entries in /boot/grub/menu.lst to boot your new XLAPP system by default.

Before rebooting, make sure you're ready to do these new few steps.  Having 2 windows open helps.  Right after rebooting, you'll have 30 seconds to log in and stop the watchdog timer.  During the development process, sometimes mistakes would creep into the bootscripts (or other touchy initialization steps).  Allows the system to reboot itself back into the host was a nice feature that prevented having to log in at the console of the target computer.

So, you'll be doing this:

* Reboot
* Log in (SSH or console)

If you can't get in, it will reboot into the host system in 30 seconds.  If you *can* get in, do this immediately:

	# cd /etc/init.d
	# ./xlapp-watchdog stop

If that works, you can uninstall the watchdog for the next reboot:

	# ./xlapp-watchdog uninstall

Now you can move on to stage 2:

	cd /lfs
	./lfs2

When this finishes, you'll have built the a dom0-capable kernel.  The system adds the GRUB entries you'll need (again)--though this time without a watchdog (if you uninstalled it).  Then, go ahead and reboot.  When this happens, you'll have a finished XLAPP system, running on top of the Xen hypervisor.

*You're ready to make domU guest systems!*


Why?
----

Prior to this, I've run RedHat and SuSE in production systems. It's frustrating to see more and more bloat go into these distributions, especially when it was always my intention to run them as servers.

For example, in the last two versions of openSUSE, in order to install the Xen system, you had to install the X11 libraries.  That's a ridiculous amount of bloat to accommodate a hypervisor.  In addition, you had to install Python (which, itself, required X11).  It seemed like there was no easy way to get rid of X11.

Running a Xen cluster should place as few dependencies on Domain 0 (the priviledged Host OS in Xen) as possible; that way, the machine runs leaner and is easier to secure.  Requiring Dom0 to install X11 libraries, sound libraries, OpenGL libraries, and dozens of userland packages that never get used makes for a bloated system.

In production systems, bloat makes backups take up more space and take longer to complete.  Bloat can also be a source of security issues (the more code running, the more code exposed).  It can also mean more bugs.  Plus, if this bloat comes through a commercial packaging system, it can also mean more dependencies in the future, and difficulty separating updating specific packages (e.g., OpenSSL) if the vendor has not updated them through their online-update system.

LFS meets the criteria for the "smallest usable" toolchain.  In addition, its members seem knowledgeable, and support for the core project is strong.  BLFS is a slightly different matter...But for those people looking to run a XLAPP cluster, this guide should serve as a value-add for BLFS to get you started.

Goals
-----

I want to run a Xen cluster using an LFS-based Dom0 and LFS-based paravirtualized DomU's.  In fact, I plan to just clone the Dom0 system and use file-based disk images for Dom0.  I want to have a pure 64-bit system (i.e., no multilib gcc/glibc, no 32-bit toolchains, no 32-bit libs in /lib vs 64-bit libs in /lib64).  I want to install as little as possible in Dom0 and each of the DomU's.  That's roughly the same goal, since the DomU's will just be clones of Dom0.

Originally, I narrowed my focus to just being able to install the web-stack on the DomU's.  It turns out, a variety of things could be done with the DomU stack, including serving as a testbed for new LFS builds.  A significant amount of effort was expended trying to keep the hardware abstracted away from the build scripts.  This was done by having a configuration script at the beginning which prompted for good values.  It turns out that with a bit more scripting, the entire XLAPP build could be bootstrapped this way, and set to be easily deployable against a DomU once the Dom0 is built.  This would go a long way toward verification-testing of the DomU--especially running test-heavy packages like BerkeleyDB (not to mention the web-stack itself).

In addition, I want to be able to deploy stripped-down DomU's that only run a DNS server or SMTP/IMAP server; this makes new domains easy to deploy in a colo server.

On with it!  (Or, "Installation")
=================================

Part 1: Choosing an LFS-host
----------------------------

So, to begin, we need a running Linux system to build LFS.  Since LFS is compiled from source, (hence the "From Scratch"), we need to have a host OS which has enough of a toolchain to compile the bootstrap portion of LFS.  Then, after that point, we simple bootstrap the rest of the LFS build.

I'm going to call this host the *"LFS-host"*, to avoid confusion with other things called "the host" (like the Xen-host).

There are lots of way to do this.  Some people suggest a LiveCD.  Some suggest free distros.  Other suggest commercial distros.  I'm choosing a free, commercial distro that is readily available, and has a toolschain that's current enough to build LFS-7.0.  I used openSUSE-11.4, because it was free, readily available, and I'm familiar with its installation process.  Plus, I think choosing an installed LFS-host is the most flexible way that allows you to fall back to a commercial distro if something goes wrong.  Which was, quite frankly, impossible to live without while I was creating XLAPP.

I also chose openSUSE because I know that Xen is functional on this platform, and if necessary, I can refer to it.  Fortunately, that was never the case, but it's nice to have it there, in case I needed it.

	Interestingly openSUSE-12.1 was released in November of last year.

Sadly, I have tried it, and the results are not encouraging, so for now, my instructions apply to openSUSE-11.4.  Specifically, test-readlink tends to fail in several test suites, which is either a glibc/kernel regression (not likely) or openSUSE hoping that all other software has been updated to use updated test-code (much more likely).  Here's a reference:

	http://osdir.com/ml/bug-m4-gnu/2011-07/msg00002.html

So, I'm sticking to 11.4 for now.


Part 2: Installing openSUSE
---------------------------

I did a custom install of openSUSE: custom disk partitioning and the software choices.  Feel free to deviate from the software choices.  Keep in mind that I needed to tools to help debug these scripts I wrote.  So, start by getting the openSUSE ISO:

	I'm not sure where to get 11.4 now that 12.1 is released; I'll post a copy once xlapp.org is up.

My advice: run the ISO off of a USB flash drive: it's quieter and faster.  Then, run memtest off that install image.  Once you're done with the memtest, run the install.  Once you get to disk partitioning, pause.  I'll give you my config, and explain why I did it the way I did.  I'll also try to give a reasonable alternative if you're doing things the way I did.  Beyond that, I sort of expect that if you're tackling XLAPP, you are...not exactly a nubsicle, so you should have a good idea of what you want to do--and how to achieve it with disk partitioning.

I decided to use 3 partitions with an MBR-style disk.  I like being able to use fdisk.  I created one primary partition, one extended partition that took up the remaining space.  In general, I feel that approach is reasonable because most people want a /boot partition that's below 1024 cylinders.  Plus, it will make life easier when we bootstrap.  Then, in extended partition, I created two logical partitions to hold data and also to serve as the target partition where LFS was going to get installed.

* /dev/sda1 - /
* /dev/sda5 - /mnt/lfs - Partition for XLAPP
* /dev/sda6 - /home

I intended to installed LFS to /dev/sda5.  And, I used /dev/sda6 to be /home.  Why put /home in a separate directory?  Simple: I needed a place where I could put files that wouldn't get clobbered if I needed to wipe the LFS target partition clean (I like clean slates, I cannot lie) or if I needed to wipe the openSUSE install (even cleaner).  Since I knew I would be writing tons of scripts and downloading lots of packages--and I didn't want all that disappearing when I "cleaned house", I made it a separate partition where I kept a backup.  Yes, I reinstalled openSUSE-as-LFS-host. Several times.  Once because of a mistake in a script that wasn't run in a chroot-jail properly.  Other times because...I was afraid something wasn't right, and I prefer to be paranoid rather than spend needless hours on a wild goose chase.

One note…I don't use swap on this kind of build, because my test machine has 16 GB of ram, which is more than I need to build LFS.  Adjust as necessary for your situation.  I would advise using up to 3 primary partitions, and then saving the fourth for the one big extended partition.  You could use /dev/sda1 for /boot, /dev/sda2 for swap, /dev/sda3 for the openSUSE root, then /dev/sda4 for the remainder (extended partition), and then still use /dev/sda5 for the LFS target partition.

	I'm going to assume that you used /dev/sda5 for your LFS target.  If not, you keep that in mind, and adjust the directions accordingly.  Either way, specify the mount point for /dev/sda5 as ( /mnt/lfs ).

Moving on...Get to where you choose your software packages.  Select "Other" (as opposed to KDE or GNOME or all that other crap), and then choose Minimal Text.  Once there, use the "Pattern" filter, and choose the following meta-packages:

* Kernel Dev
* C/C++ Dev
* Xen

Then, change to "Search" mode (i.e. no longer "Pattern"), and search for these packages to make your life possible/easier.  Replace 'vim' with whatever editor you're comfortable with.  But, I install 'vim' again for XLAPP.  If you'd rather have something else, do your own investigations.

* vim
* expect
* man
* man-pages
* man-pages-posix

Now, enable SSH, and turn off the firewall.  Why SSH?  Because I connected to this machine from my laptop to write/run the scripts.  if you want to work at the console, that's up to you.

Finish your install, and customize your networking however you need to allow yourself to work at a more comfortable computer (say, one that has access to a browser).  If you're doing this at the console...How the hell are you reading this?

Part 3: Preparing your LFS install
----------------------------------

So, you've got your openSUSE system installed and booted.  Now, login as root.

	Double-check that the LFS target partition is indeed /dev/sda5, and that you've mounted it at /mnt/lfs.

Seriously.  Double-check this.  Or, triple-check this.  This is important.

	Grab a copy of this project and put it in /home/software/lfs.

Grab the tarball from GitHub (using your laptop?) and then scp it over to your LFS-host.  Unpack it in /home/software.  Rename that silly directory (qrux-xlapp-9837487whateverblahblahblah) to 'lfs'.  No, I don't care that you don't call it 'xlapp'.  I know 'lfs' is shorter and easier to type.  That's what I did.

Inside, you should see a crapload of files, almost all bash-like scripts, and some of them are even executable.  Yes, you're root.  Feel free to look through everything.  There are no executables.  Just source.  I ask for a root password for your new LFS system one time, so I can put it into /etc/shadow.  Feel free to look at the the shadow script, and examine passhash.c.  There should be no shenanigans there.  Or anywhere.

Now, we get to the "meat" of the LFS install.  Here, you need to do the heartwrenching task of choosing IP addresses and--ZOMG--a hostname for your new machine.  You can call it whatever you want.  Including the name it currently has.  Remember, the newly-built LFS system will *REPLACE* the LFS-host (openSUSE); they are meant to never both be booted at the same time.  Don't worry about a collision.

Once you've mentally settled on what these values are, take a quick peek at machine.config.in.  There, you'll you see the parameters laid out.  But, don't start editing this file.  Run the script.  It's nice, and it will write the values in.  Trust me--you don't want to try to calculate the SHA-512 hash of your password by hand.  You can't, anyway, unless you modify passhash.c to do some really crazy shiz.  That's why I call crypt().

You're ready to configure your LFS system.  And, keep in mind that the XLAPP build system is...impatient.  As soon as you've finished answering the quick questionnaire, the XLAPP build system will start to build LFS for you.  At this point, you best find something else to do.  On a quad-core Intel i5-760, the build takes about 3 hours.

	I'm running your build with MAKEFLAGS="-j 4" when it's safe to do so.

When it's not safe to do it, I set MAKEFLAGS="-j 1" and force a serial make.

When it's done, you'll see a message like this:

	################################################################
	################################################################
	#
	# [ /boot/vmlinuz-3.1-lfs-7.0-20120125_165649 ] installed to /boot
	#   /boot/vmlinuz-3.1-lfs-7.0 - Updated.
	#
	#   LFS - BUILD FINISHED.  Adjust host system to boot LFS build.
	#
	################################################################
	################################################################

Now you have to "adjust the host system to boot the LFS build."

Part 4. Adjusting the LFS-host to Boot the LFS Build
----------------------------------------------------
[todo]


Part 5. Issues
--------------
