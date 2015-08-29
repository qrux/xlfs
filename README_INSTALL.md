Building XLFS
====

Part 1: Creating the LFS-host
----

Install OpenSuSE-11.4.  If you don't have it:

> [http://xenfromscratch.org/software/build-host/openSUSE-11.4-x86_64.iso](http://xenfromscratch.org/software/build-host/openSUSE-11.4-x86_64.iso)

Remember, newer versions won't compile this version of LFS and have all
the tests pass.

Create 4 partitions on a NEW MSDOS-dos (MBR) partitioned disk:

> * /boot
> * /
> * (swap)
> * /mnt/lfs

Looks something like this:

	primary:  /boot          2 GB, ext2 <-- Don't need journaling here
	primary:  (n/a)         16 GB, (possibly swap)
	primary:  /             16 GB, ext4
	extended:                      (remaining space)
	extended: /mnt/lfs      32 GB, ext4

	/dev/sda1:      /boot
	/dev/sda2:      (possibly swap)
	/dev/sda3:      /
	/dev/sda5:      /mnt/lfs

Disregard swap warning if you have more than 8GB of RAM.  If not,
use /dev/sda2 as swap.  If you have more than 8 GB of RAM, feel
free to use /dev/sda2 or something else.  Or, use /dev/sda2 as the
mount point for the root filesystem.

Since /mnt/lfs will become the new root partition for dom0, we
keep it pretty tight.  Ignore the leftover space for now; consider
using it for /srv or /var (or something else) once the dom0 is up.

Skip "Create New User" screen--you'll be prompted for a root
password next (don't need anything other than root user for
building XFS.

On prep screen, enable SSH (which requires keeping the firewall on).



Part 2: Configuring the LFS-host software.
----

Patterns (whole groups of packages):

* Base Development
* Linux Kernel Development

Search (individual packages):

* vim
* expect
* man
* man-pages
* man-pages-posix

Accept automatic changes (dependencies).

Review on "Installation Settings" screen.

If all okay, install SuSE; otherwise, redo.  SuSE will reboot when it's
finished, and start the configuration process.



Part 3: Configuring SuSE, 1
----

Disable IPv6.

Configure networking card(s) as needed.

(Remember to set a gateway and DNS if using static IPs.)

Ignore other settings.  If you have some complex setup (like ISDN or
some kind of dial-up or custom networking) then you're on your own.  I
wouldn't mind hearing about your experience, though.

(Sadly, SuSE wants to connect to the internet anyway for updates...)

Let it do that.  If it's not working, you probably screwed up your
network config.  Alt-S to "Skip" the errors, then "Back" to the network
config screen.  Double-check that DHCP is working (or, if doing static
IPs, that you have properly added a Gateway and Router--the UI is a bit
confusing).  The timeouts are kinda lame (esp. on "Back"; give it time;
it will return control to you.

DO NOT go crazy pressing &lt;Enter&gt;.

At this stage, it's trying to get access to your network.  It's a pain
if you don't get it right on the first shot, but the best thing to do
is to let it timeout.  Trust me.  If you don't, it will probably cache
your keystrokes and take you down a rabbit hole involving updates...

> __SKIP updates.__

You don't need a SINGLE update to complete the XLFS build.  Plus, this
sends you down a death spiral of selecting packages for update, none of
which you need.


Part 4: Configuring SuSE, 2
----

"Local" auth is fine.

Skip creating local user.

> Do this by going to "User Management" (Alt-M), and "Next" from the
> "User and Group Administration" screen.  This will bypass creating a
> non-root user.

Almost done with config.  At the next screen, "Release Notes", just
say "Next" (nothing there should matter to an XFS build).

Skip printer configuration.

Next screen is last screen: "Installation Completed".

Finish (Alt-F) to finish.


Part 5: Preparing for XFS build.
----

Or: __"What's going on with my console?!"__

Depending on your video card, at this point, you may not be able to see
your console.  In my case, I wasn't able to see the bottom.  This sucks.
The solution is to SSH in.

> At this point (for me), the console APPEARS totally jacked.  It isn't.
> I believe that in my case the screen mode is incorrectly set.
> It's just that the cursor is below the point of visibility.  Test it by
> pressing <Enter> a few times until the prompt appears "above the fold."

> Doesn't matter anyway.  At this point, you should be able to SSH into
> the SuSE host system.  That was the whole point.

If, per chance, you did *not* turn on SSH (or decided to disable the
firewall, which I do now), you'll need to enable SSH manually.

> Log in with root (you don't need to see anything to make that work.
> Type 'yast' at the prompt:

	# yast

> Should start the SuSE curses config (which
> appears not to suck at screen dimensions, unlike the console).

> System -> System Services (Runlevel)

> Expert Mode (Alt-X)

> Scroll down to sshd.  Enable now and for runlevels 3 and 5:

* Alt-T -> Start Now...
* Alt-3
* Alt-5

> Save changes to runlevels.  Quit yast.

I enable NTP at this point.  Makes the build process more sane to have a
sane clock.

I also make myself more comfortable with a "luxury" shell config.
Feel free to use mine at:

> [http://xenfromscratch.org/ubuntu/scripts/etc-profile](http://xenfromscratch.org/ubuntu/scripts/etc-profile)

It's optimized for a dark-background console.

Add your SSH key to make things more convenient.

Also, you can add the following boot options to /boot/grub/menu.lst
so your machine boots up into an archaic 80x25 console.  Again, you can
see my choices are about staying colo-friendly (and not about optimizing
for 27" 1080p monitors):

	nofb nomodeset video=vesafb:off vga=normal

My philosophy is that it's better to have a usable console than a broken one,
even when you switch monitors.  I have 2 30"s on my desk; I still prefer them
to boot 80x25.  Just sayin'.  Your boot entry will start with 'kernel', and you
can just append that entire string to the end of the line.  It will start out
looking like this:

	###Don't change this comment - YaST2 identifier: Original name: linux###
	title Desktop -- openSUSE 11.4 - 2.6.37.1-1.2
		root (hd0,0)
		kernel /vmlinuz-2.6.37.1-1.2-desktop root=/dev/disk/by-id/ata-YOUR_DISK_MODEL-part3 splash=silent quiet showopts
		initrd /initrd-2.6.37.1-1.2-desktop

Chances are good that "vga=normal" will already be there; that's not a
problem.  Edit this entry (specifically, the "`kernel`" line) to look like this:

	kernel /vmlinuz-2.6.37.1-1.2-desktop root=/dev/disk/by-id/ata-YOUR_DISK_MODEL-part3 splash=silent quiet showopts nofb nomodeset video=vesafb:off vga=normal


*Reboot.*

I like to reboot here so that:

* I get a usable console (not that I need it).
* I get a system that booted with the correct time.
* I'm testing the new install for sanity.
* I get that warm fuzzy OCD feeling.

Now you're ready to build XLFS.



Part 6: Building XFS.
----

Now, back on your working machine (the one you're SSH'ing from),
copy the XFS source to a directory.  I use this script:

	#! /bin/bash
	
	HOST=$1
	
	if [ -z $HOST ] ; then
		echo
		echo "  Usage: $0 host"
		echo
		exit
	fi
	
	rsync -e ssh -av \
		--exclude NOUSE --exclude .gitignore --exclude .idea --exclude .git \
		~/proj/xlfs root@${HOST}:


Of course, I assume that the XFS sources are installed in ~/proj/xlfs.

On the XFS machine, log in as root.  Create a symlink and make a dir:

	# ln -s xlfs lfs
	# mkdir src

Now you're ready for the build!

The build command blocks the console until it's finished.  You can suspend
it and restart it after you see the message "Building XLAPP (Phase 1)" using
Ctrl-z and then "%1 &" or some such.  I don't know what SIGHUP will do.  I
would recommend not logging out.

On my HOST, I can log out without having to do something like nohup %1 &.
However, I will not see completion or failure messages this way, and will have
to infer success or failure.

Anyway, to build, I use a command like this:

	./lfs \
		-A core2 \
		-s ~/src \
		-l /dev/sda5 \
		-p /dev/sda2 \
		-b /dev/sda1:ext2 \
		-k "ssh-ed25519 AAAA....rd4j qrux@qrux" \
		-4 192.168.1.250/24 \
		-g 192.168.1.1 \
		-d 192.168.1.1 \
		-t NTP-SERVER.YOUR_ISP.TLD \
		-a C -z America/Los_Angeles \
		-j 4 \
		-n \
		YOUR-HOSTNAME.YOUR-DOMAIN.TLD /mnt/lfs

To see all the build options:

	./lfs -h

The 'u' and 'y' options MUST NOT BE USED at this point.  'r' is totally
broken and experimental.

	IMPORTANT: To create a VERIFIED build, use '-j 1' and OMIT the 'n' option.
	--------------------------------------------------------------------------
	
    	#  [ b1.90 - XLAPP_BOOT_WATCHDOG ] run successfully
    	#  [ b1.94 - SNAPSHOT ] run successfully
	Total time spent building LFS: 66.5m

This is what the results look like for a quad-core Q6600 (OC to 2.89 GHz).



Part 6b: Rebooting after successful build.
----

Once this finishes, reboot into the "LFS (bare metal)" GRUB entry.

This will boot the system into the newly compiled LFS build.

<div id="watchdog-info"></div>

__Read this next part before you reboot:__

*IMMEDIATELY upon rebooting the system, log into the newly built XLFS system.
There, a 60-second watchdog timer is running.  Disable it like so:*

	# cd /etc/init.d
	# ./xlapp-boot-watchdog stop

Then, if you're confident that the system will boot (you might want to wait
until after Part 7), uninstall the watchdog completely:

	# ./xlapp-boot-watchdog uninstall

Why does this happen?  One of the original goals of XLFS was to be robust
enough so it would fail in one of two recoverable states: either it failed in
the build process--and would leave you in the build host (in this example
case, SuSE), or it would build completely, allow you to reboot, but would
detect you could not log in, and would reboot __back__ to the
build host (again, SuSE).

In summary:

> *Reboot.*
> 
> *Turn off the watchdog...*
> 
> __...Quickly!  You only have 60 seconds!__



Part 7: The next phase.
----

Next, you'll have to build Phase 2 for the Xen dom0.

	# cd lfs
	# ./lfs2

That's it.  When it finished, reboot into the option that
looks like this:

	"X/LAPP Xen                  (LFS-7.0, Linux-3.1, Xen-4.2.5)"

Remember:

> *Reboot.*
> 
> *Turn off the watchdog...*
> 
> __...Quickly!  You only have 60 seconds!__

Why?  See here: [watchdog](#watchdog-info).

That's it.  You're running Xen now!

To make sure, try this:

	# cat /proc/xen/capabilities

If that file exists, then you're good.


Next Steps...
----

You might have to experiment with kernel options.

Look at [kernel info](?page=kernel) for some XLFS-related details.

> I've compiled most (nearly all) of the drivers into the kernel.  This is good for
> some and VERY BAD for others.

> Notable exceptions are the 3ware (RAID controller) drivers and the e1000/e1000e
> networking drivers.  I omitted the former because of boot issues (this is an
> initramfs issue, and XLFS does not boot with a ram disk, though it can, and
> that's something I hope to return to).

> Would love to have it for booting `by-disk-id`, rather than `/dev/sd*` devices.

I'm trying to figure out how to make an install disk so that I can directly
install LFS-bare-metal onto a drive, and from there run `./lfs2` and just
build the Xen bits.

If anyone wants to build an installer for me, that would be amazeballs.

__How do I make VMs?!__

I assume you're here because you wanted to bring up a Xen host to...you know...host
Xen guest VMs.  As root, look in `lfs/xen`.

There's a script there called `make-domu`.

Look at [Make Guest VMs](?page=guests) for info on making domUs.
