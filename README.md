What is X/LAPP?
===============

X/LAPP is take on "LAPP".  It stands for "Xen/LFS Apache Postgres PHP".


I thought the 'L' in "LAPP" stood for Linux.  What's this 'LFS'?
----------------------------------------------------------------

Well, LFS itself stands for "Linux From Scratch".  It's a project
intended to teach people how Linux works, and is a book intended to
guide a user through the entire process of compiling Linux from
source.  X/LAPP, then, is a way to compile the entire OS, plus a web
stack (composed of...duh...Apache, Postgres, and PHP), entirely
from source code.

Why? (Or, "Motivations")
------------------------

Prior to this, I've run RedHat and SuSE in production systems.
It's frustrating to see more and more bloat go into these system,
especially when it was always my intention to run them as servers.

For example, in the last two versions of openSUSE, in order to install
the Xen system, you had to install the X11 libraries.  That's a
ridiculous amount of bloat to accommodate a hypervisor.  In addition,
you had to install Python (which, itself, required X11).  It seemed
like there was no easy way to get rid of X11.

Running a Xen cluster should place as few dependencies on Domain 0
(the priviledged Host OS in Xen) as possible; that way, the machine
runs leaner and is easier to secure.  Requiring Dom0 to install X11
libraries, sound libraries, OpenGL libraries, and dozens of userland
packages that never get used makes for a bloated system.

In production systems, bloat makes backups take up more space and take
longer to complete.  Bloat can also be a source of security issues
(the more code running, the more code exposed).  It can also mean
more bugs.  Plus, if this bloat comes through a commercial packaging
system, it can also mean more dependencies in the future, and
difficulty separating updating specific packages (e.g., OpenSSL) if
the vendor has not updated them through their online-update system.

LFS meets the criteria for the "smallest usable" toolchain.  In
addition, its members seem knowledgeable, and support for the core
project is strong.  BLFS is a slightly different matter...But for
those people looking to run a X/LAPP cluster, this guide should serve
as a value-add for BLFS to get you started.

Goals
-----

I want to run a Xen cluster using an LFS-based Dom0 and LFS-based paravirtualized
DomU's.  In fact, I plan to just clone the Dom0 system and use file-based
disk images for Dom0.  I want to have a pure 64-bit system (i.e., no
multilib gcc/glibc, no 32-bit toolchains, no 32-bit libs in /lib vs
64-bit libs in /lib64).  I want to install as little as possible in Dom0
and each of the DomU's.  That's roughly the same goal, since the DomU's
will just be clones of Dom0.

Then, in the DomU's, I want to be able to install my web-stack for my
production applications.  I also want various DomU's available to act as
private DNS servers or SMTP/IMAP servers.


On with it!  (Or, "Installation")
=================================

Part 1: Choosing an LFS-host
----------------------------

So, to begin, we need a running Linux system to build LFS.  Since LFS
is compiled from source, (hence the "From Scratch"), we need to have a
host OS which has enough of a toolchain to compile the bootstrap portion
of LFS.  Then, after that point, we simple bootstrap the rest of the LFS
build.

I'm going to call this host the *"LFS-host"*, to avoid confusion with other
things called "the host" (like the Xen-host).

There are lots of way to do this.  Some people suggest a LiveCD.  Some
suggest free distros.  Other suggest commercial distros.  I'm choosing
a free, commercial distro that is readily available, and has a toolschain
that's current enough to build LFS-7.0.  I used openSUSE-11.4, because
it was free, readily available, and I'm familiar with its installation
process.  Plus, I think choosing an installed LFS-host is the most flexible
way that allows you to fall back to a commercial distro if something goes
wrong.  Which was, quite frankly, impossible to live without while I was
creating X/LAPP.

I also chose openSUSE because I know that Xen is functional on this
platform, and if necessary, I can refer to it.  Fortunately, that was never
the case, but it's nice to have it there, in case I needed it.

*[Interestingly openSUSE-12.1 was released in November of last year. I
may try it and then update these docs, but for now, my instructions apply
to openSUSE-11.4.]*

Part 2: Installing openSUSE
---------------------------

I performed a custom install of openSUSE.  The two custom aspects were
the disk partitioning (and, everyone is going to have to live with this)
and the software choices.  Feel free to deviate from the software choices.
Keep in mind that my needs are probably different from yours, since I had
to debug these scripts I wrote.  Hopefully, you won't have to do the same.
So, since you'll only boot the LFS-host to build your Dom0 (and never
again after that), as long as disk space isn't at a premium for you then
go ahead and install all the stuff to make your life easier.  At the end
of the day, the stuff I installed fits in less than 2.5 GB of space.
If you're doing an embedded build, I would steer clear of X/LAPP, since
it's about running a Xen cluster...If you've got the hangers to try
that, feel free to tell me how it went.

So, start by getting the openSUSE ISO:

	[ I'm not sure where to get 11.4 now that 12.1 is released... ]

Then, run the memory test.  Yes, I'm not kidding.  If you haven't run the
memory test, you're opening yourself up to a sh*tstorm of weird errors.  Do it.
Don't complain.  If you did this when you built/received your system, then
give yourself a pat on the back, and move on to the next step.

Once you're done with the memtest, run the install.  And, cowboy-up.  Do it
in Text Mode.  (F3, scroll up).  Why?  Because RealMen(TM) don't use a
graphical install.  Actually, I don't care.  Do it however you want.

Once you get to disk partitioning, pause.  I'll give you my config, and
explain why I did it the way I did.  I'll also try to give a reasonable
alternative if you're doing things the way I did.  Beyond that, I sort of
expect that if you're tackling X/LAPP, you are...not exactly a nubsicle, so
you should have a good idea of what you want to do--and how to achieve it
with disk partioning.

I decided to use 3 partitions on an MSDOS disklabel.  I like being able to use
fdisk.  I created one primary partition (/dev/sda1).  Then, one extended
partition (/dev/sda2) that took up the remaining space.  In general, I feel
that approach is reasonable because most people want a /boot partition that's
below 1024 cylinders.  Plus, it will make life easier when we bootstrap.

Then, in the remaining space, I created two other partitions (/dev/sda5 and /dev/sda6)
to hold data and also to serve as the target partition where LFS was going
to get installed.

I intended to installed LFS to /dev/sda5.  And, I used /dev/sda6 to be /home.
Why put /home in a separate directory?  Simple: I needed a place where I
could put files that wouldn't get clobbered if
I needed to wipe the LFS target partition clean (I like clean slates, I
cannot lie) or if I needed to wipe the LFS host OS (even cleaner).  Since I
knew I would be writing tons of scripts--and I didn't want them disappearing
when I "cleaned house", I made it a separate partition--and made sure not to
reformat it when I reinstalled openSUSE.  Yes, I reinstalled the LFS-host OS.
Several times.  Once because of a mistake in a script that wasn't run in a
chroot-jail properly.  Other times because...I was afraid something wasn't
right, and I prefer to be paranoid rather than spend needless hours on a
wild goose chase.

Also, I don't use swap.  My test machine has 16 GB of ram, which is more than
I need to build LFS.  Adjust as necessary for your situation.  I would advise
using up to 3 primary partitions, and then saving the fourth for the one big
extended partition.  You could use /dev/sda1 for /boot, /dev/sda2 for swap,
/dev/sda3 for who-knows-what, then /dev/sda4 for the remainder (extended
partition), and then still use /dev/sda5 for the LFS target partition.

	I'm going to assume that you used /dev/sda5 for your LFS target.  If not,
you keep that in mind, and adjust the directions accordingly.  Either way,
specify the mount point for /dev/sda5 as [ /mnt/lfs ].

Moving on...Get to where you choose your software packages.  Select "Other"
(as opposed to KDE or GNOME or all that other crap), and then choose Minimal
Text.  Once there, use the "Pattern" filter, and choose the following meta-packages:

	* Kernel Dev
	* C/C++ Dev
	* Xen

Then, change to "Search" mode (i.e. no longer "Pattern"), and search for these
packages to make your life possible/easier.  Replace 'vim' with whatever editor
you're comfortable with.  But, I install 'vim' again for X/LAPP.  If you'd
rather have something else, do your own investigations.

	* vim
	* expect
	* man
	* man-pages
	* man-pages-posix
	* sysstat

Now, enable SSH, and turn off the firewall.  Why SSH?  Because I connected to this
machine from my laptop to write/run the scripts.  if you want to work at the console,
that's up to you.

Finish your install, and customize your networking however you need to allow
yourself to work at a more comfortable computer (say, one that has access to a
browser).  If you're doing this at the console...How the hell are you reading this?

Part 3: Preparing your LFS install
----------------------------------

So, you've got your openSUSE system installed and booted.  Now, login as root.

	Double-check that the LFS target partition is indeed /dev/sda5, and that
you've mounted it at /mnt/lfs.  Seriously.  Double-check this.  Or, triple-check
this.  This is important.

Grab a copy of this project and put it in /home/software/lfs.

	Grab the tarball from GitHub (using your laptop?) and then scp it over to your
LFS-host.  Unpack it in /home/software.  Rename that silly directory
(qrux-xlapp-9837487whateverblahblahblah) to 'lfs'.  No, I don't care that you
don't call it 'xlapp'.  I know 'lfs' is shorter and easier to type.  That's what I did.

Inside, you should see a crapload of files, almost all bash-like scripts, and some of
them are even executable.  Yes, you're root.  Feel free to look through everything.
There are no executables.  Just source.  I ask for a root password for your new LFS
system one time, so I can put it into /etc/shadow.  Feel free to look at the the shadow
script, and examine passhash.c.  There should be no shenanigans there.  Or anywhere.

Now, we get to the "meat" of the LFS install.  Here, you need to do the heartwrenching
task of choosing IP addresses and--ZOMG--a hostname for your new machine.  You can call
it whatever you want.  Including the name it currently has.  Remember, the newly-built
LFS system will *REPLACE* the LFS-host (openSUSE); they are meant to never both be
booted at the same time.  Don't worry about a collision.

Once you've mentally settled on what these values are, take a quick peek at machine.config.in.
There, you'll you see the parameters laid out.  But, don't start editing this file.
Run the script.  It's nice, and it will write the values in.  Trust me--you don't want to
try to calculate the SHA-512 hash of your password by hand.  You can't, anyway, unless you
modify passhash.c to do some really crazy shiz.  That's why I call crypt().

You're ready to configure your LFS system.  And, keep in mind that the X/LAPP build system
is...impatient.  As soon as you've finished answering the quick questionnaire, the X/LAPP
build system will start to build LFS for you.  At this point, you best find something else
to do.  On a quad-core Intel i5-760, the build takes about 3 hours.

	I'm running your build with MAKEFLAGS="-j 4" when it's safe to do so; when
it's not safe to do it, I set MAKEFLAGS="-j 1" and force a serial make.

When it's done, you'll see a message like this:

<code>
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
</code>

Now you have to "adjust the host system to boot the LFS build."

4. Adjusting the LFS-host to Boot the LFS Build
-----------------------------------------------
[todo]
