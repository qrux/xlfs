Part 1: Creating the LFS-host
==

Boot OpenSuSE-11.4

Create 3 partitions on a NEW MSDOS-dos (MBR) partitioned disk:

primary: /boot		2 GB, ext2 <-- Don''t need journaling here
primary: /		16 GB, ext4
extended:		(remaining space)
extended: /mnt/lfs	32 GB, ext4

/dev/sda1:	/boot
/dev/sda2:	/
/dev/sda5:	/mnt/lfs

Since /mnt/lfs will become the new root partition for dom0, we
keep it pretty tight.  Ignore the leftover space for now; consider
using it for /srv or /var (or something else) once the dom0 is up.

Disregard swap warning.

Skip "Create New User" screen--you''ll be prompted for a root
password next (don''t need anything other than root user for
building XFS.

On prep screen, disable firewall (in "Firewall and SSH...").


Part 2: Configuring the LFS-host software.
==

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

If all okay, install SuSE; otherwise, redo.  SuSE will reboot when it''s
finished, and start the configuration process.



Part 3: Configuring SuSE.
==

Disable IPv6.

Configure networking card(s) as needed.

(Remember to set a gateway and DNS if using static IPs.)

Ignore other settings (unless you have some complex setup; you''re on your
own if that''s the case).

(Sadly, SuSE wants to connect to the internet anyway for updates...)

Let it do that.  If it''s not working, you probably screwed up your
network config.  Alt-S to "Skip" the errors, then "Back" to the network
config screen.  Double-check that DHCP is working (or, if doing static
IPs, that you have properly added a Gateway and Router--the UI is a bit
confusing).  The timeouts are kinda lame (esp. on "Back"; give it time;
it will return control to you.  DO NOT go crazy pressing <Enter>...


SKIP updates!!!!!!

"Local" auth is fine.

Skip creating local user.

Do this by going to "User Management" (Alt-M), and "Next" from the
"User and Group Administration" screen.  This will bypass creating a
non-root user.

Almost done with config.  At the next screen, "Release Notes", just
say "Next" (nothing there should matter to an XFS build).

Skip printer configuration.

Next screen is last screen: "Installation Completed".

Finish (Alt-F) to finish.





Part 4: Preparing for XFS build.
==

For me, the screen resolution (yes, even in text mode) is fucked.
Log in with root (you don''t need to see anything to make that work.
type 'yast' at the promt.  Should start the SuSE curses config (which
appears not to suck at screen dimensions, unlike the console).

System -> System Services (Runlevel)

Expert Mode (Alt-X)

Scroll down to sshd.  Enable now and for runlevels 3 and 5:

	Alt-T -> Start Now...
	Alt-3
	Alt-5

Save changes to runlevels.  Quit yast.

At this point (for me), the console APPEARS totally jacked.  It isn''t.
It''s just that the cursor is below the point of visibility.  Test it by
pressing <Enter> a few times until the prompt appears "above the fold."

Doesn''t matter anyway.  At this point, you should be able to SSH into
the SuSE host system.  That was the whole point.

I enable NTP at this point.  Makes the build process more sane to have a
sane clock.

I also make myself more comfortable with a reasonable shell config.
Feel free to use mine at:

	http://xlapp.org/ubuntu/scripts/etc-profile

It''s optimized for a dark-background console.

Add your SSH key to make things more convenient.

Also, you can add these boot options to /boot/grub/menu.lst:

	nofb nomodeset video=vesafb:off vga=normal pcie_aspm=off

Your boot entry will start with 'kernel', and you can just append
that entire string to the end of the line.  Chances are good that
"vga=normal" will already be there; it''s not a problem.  This will
boot your hihg-res monitor into an insanely low-res mode (80x24), but
since this is a server deployment (and I use low-res monitors in that
context and also to install these machines), it''s fine.  Better to
have a usable console than a broken one.



Part 5: Building XFS.
==

Now, back on your working machine (the one you''re SSH''ing from),
copy the XFS source to a directory.  I use this script:

====
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
	~/local/xlapp root@${HOST}:
====


Of course, I assume that the XFS sources are installed in ~/local/xlapp.

On the XFS machine, log in as root.  Create a symlink and make a dir:

# ln -s xlapp lfs
# mkdir src

Now you''re ready for the build!

The build command blocks the console until it''s finished.  You can suspend
it and restart it after you see the message "Building XLAPP (Phase 1)" using
Ctrl-z and then "%1 &" or some such.  I don''t know what SIGHUP will do.  I
would recommend not logging out.

On my HOST, I *CAN* log out without having to do something like nohup %1 &.
However, I will not see completion or failure messages this way, and will have
to infer success or failure.

Anyway, to build, I use a command like this:

./lfs \
	-s ~/src \
	-l /dev/sda5 \
	-p /dev/sda2 \
	-b /dev/sda1:ext2 \
	-k "ssh-rsa AAAA...== qrux@qrux" \
	-4 192.168.1.250/24 \
	-g 192.168.1.1 \
	-d 192.168.1.1 \
	-t ntp1.xlapp.org \
	-a C -z America/Los_Angeles \
	-j 4 \
	-n \
	metal.site /mnt/lfs

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



Part 7: The next phase.
==

Once this finishes, reboot into the "LFS (bare metal)" option.

This will boot the system into the newly compiled LFS build.

Next, you''ll have to build Phase 2 for the Xen dom0.

# cd lfs
# ./lfs2

That''s it.  When it finished, reboot into the option that
looks like this:

"X/LAPP Xen                  (LFS-7.0, Linux-3.1, Xen-4.2.5)"

That''s it.  You''re up on Xen now.

To make sure, try this:

# cat /proc/xen/capabilities

If that file exists, then you''re good.



Part 8: The future.
==

I''m trying to figure out how to make an install disk so that I can directly
install LFS-bare-metal onto a drive, and from there issue ./lfs2 and just
build the Xen bits.

If anyone wants to build an installer for me, that would be amazeballs.
