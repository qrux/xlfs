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
that's current enough to build LFS-7.0.  I choose openSUSE-11.4, because
it's free, readily available, and I'm familiar with its installation
process.  Plus, I think choosing an installed LFS-host is the most flexible
way that allows you to fall back to a commercial distro if something goes
wrong.  Which was, quite frankly, impossible to live without while I was
creating X/LAPP.

Part 2: Installing openSUSE-11.4
--------------------------------

[todo]

