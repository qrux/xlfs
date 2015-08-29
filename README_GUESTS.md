Creating Guest VMs (Xen domUs)
====

A "guest VM" of the Xen Project Hypervisor is referred to as a 'domU' (as
opposed to the "host OS", which is referred to as 'dom0').

The domU is where all the good stuff happens.  Your web server, database server
(sometimes), SMTP MTA/MUA, IMAP server, and all the other bits of your
app deployment live.  I assume you know why you want one.  If not, here
are some links (totally uncurated, returned by a random search) to explain
why you might want such a thing:

> [Top 10 benefits of server virtualization](http://www.infoworld.com/article/2621446/server-virtualization/server-virtualization-top-10-benefits-of-server-virtualization.html)

> [10 New Reasons to Virtualize Your Infrastructure](http://www.serverwatch.com/trends/article.php/3910526/10--New-Reasons-to-Virtualize-Your-Infrastructure.htm)

> [What is virtualization?](http://www.vmware.com/virtualization/how-it-works)

> [Why choose virtualization?](http://www.techadvisory.org/2014/05/why-choose-virtualization/)

And, OTOH:

> [10 things you shouldn't virtualize](http://www.techrepublic.com/blog/10-things/10-things-you-shouldnt-virtualize/)

If the goal of XLFS is create a virtualization environment, it only makes
sense that it would facilitate the creation of Xen domUs.  Once you've booted
into the Xen system, look here:

	# cd lfs/xen

There's a file called `make-domu`.

It's based off this wonderful guide to create domUs:

> [Building a Xen Virtual Guest Filesystem on a Disk Image (Cloning Host System)](http://www.virtuatopia.com/index.php/Building_a_Xen_Virtual_Guest_Filesystem_on_a_Disk_Image_%28Cloning_Host_System%29)

While the guide is now ancient, the gist of the guide is still valuable.



The command:
----

To make a dom0:

	./make-domu \
		-f -s /lfs-snapshots/current \
		-k "ssh-ed25519 AAAA....rd4j qrux@qrux" \
		-4 YOUR.PRIMARY.IP.ADDR/NETMASK \
		-g YOUR.GATEWAY.IP.ADDR \
		-t YOUR.NTP.HOSTNAME \
		-a C \
		-z America/Los_Angeles \
		-j 6 \
		-v YOUR_VOLUME_GROUP:ext4 \
		-2 512 \
		-m 6144 \
		-d YOUR.NAMESERVER.IP.ADDRESS \
		-4 A.SECONDARY.IP.ADDR \
		YOUR.FQDN.TLD

Here's a quick breakdown:

* `-f` : The host system to clone.  This happens to be something that XLFS creates
for you during the build, anticipating the need to create domUs.

* `-k` : The SSH key you'll use to get access to the domU.

* `-4` : The first time this argument is given will be the IP assigned to eth0.

* `-g` : The default gateway for the IP you just gave it.

* `-t` : The NTP server this domU will use (this may be deprecated in the future).

* `-a` : The Locale (feel free to use something like `en_US.UTF-8` if it makes sense for you).

* `-z` : The timezone.

* `-j` : The number of (v)CPUs to allocate to the domU.

* `-v` : The volume group (see 'domU Filesystem' below).

* `-2` : The amount of storage, in GiB.

* `-m` : The amount of memory, in MiB.

* `-d` : The nameserver (this can be given multiple times).

* `-4` : The second time is eth1, etc.  I use this for an internal network the domUs share.

Finally, the `YOUR.FQDN.TLD` is the FQDN of the host you'll be bringing up.



domU Filesystem
----

One major difference between the "Cloning" guide and current Xen practices is
the allocation of the storage space (the root and other filesystems) for the
domU.  In the old days, you'd create a file in dom0, mount it via the loopback
interface, and then point the domU configuration at that file.  Today, LVM
seems to be a popular method to allocate space.  That is how `make-domu` operates.

The `-v` argument to `make-domu` specifies the LVM volume group.  There are lots
of good guides out there.  A simple example might look like this: suppose you have a
disk at /dev/sdb, which will be where the domU filesystems live.  To give LVM total
control over that disk, simply do this:

	# pvcreate /dev/sdb

This will let LVM operate without any partitioning (it's what I do).

Then, you'll need to create a volume group on that physical volume:

	# lvcreate vg0 /dev/sdb

That command creates a volume group called `vg0`, using the device /dev/sdb.
You can give it mutiple devices which have been initialized with pvcreate.
Consult your LVM2 guide.  So, in the above `make-domu` example, replace the
line containing `-v YOUR_VOLUME_GROUP:ext4` with `-v vg0:ext4`.  Obviously, the
string after the colon is simply the FS type you want to use.  Obviously,
your kernel and userspace will have to support the FS and have the tools to create
a filesystem.



Running the domU
----

Once you do this, it will create a file here:

	# cd /etc/xen/vm

To start the VM, do this:

	# xl create -c YOUR.FQDN.TLD.conf

where `YOUR.FQDN.TLD` was the FQDN you chose for this domU.

At this point, you should see the domU boot.

__To quit the console, type: CTRL-]__.

You should be able to (provided the networking configuration you specified
in the CLI arguments were correct), to SSH in to the domU (using the SSH
key you specified).

If not, you can debug your domU.



Debugging the domU
----

You can bring down the domU (without being at the machine like this):

	# xl shutdown YOUR.FQDN.TLD

This will initiate a shutdown on the machine.  Check on the status like this:

	# xl list

It should show the proper entry in a state of `S`.

Once the machine is down, you can mount the filesystem on the Host OS (see
how interesting virtualization is?):

	# cd /mnt
	# mkdir YOUR.FQDN.TLD
	# mount -o noatime /dev/vg0/YOUR.FQDN.TLD YOUR.FQDN.TLD

Voil&agrave;!

In /mnt/YOUR.FQDN.TLD, you'll find the filesystem for the domU.  Here, you can
do whatever you normally do (edit etc/passwd, blah blah blah).

__Remember not to edit /etc/passwd, but /mnt/YOUR.FQDN.TLD/etc/passwd!__

But that's just basic Unix stuff.



What now?
----

You can try creating a bunch of them.  Run the `make-domu` command as many times
as you have memory and disk space to spare!  The default XLFS configuration
allocates 2 GiB to dom0.  Yes, it needs memory, too, to do crazy stuff like
operate your actual disk drives and actual networking interfaces.

So, you have `(TOTAL_RAM - 2 GiB)` to allocate to your domUs.  Go nuts.

You can use `bonnie++` to test the filesystem performance.  The domUs also have
`iostat`.

But, the main use of your domUs will be to run application stacks (presuambly).
There are three immediately available for your pleasure:

* *LAPP* (Apache, Postgres, PHP)
* *Mail* (Postfix, Dovecot, OpenDKIM)
* *DNS* (BIND-9)

On each domU, you can create it like this:

	# su blfs
	# cd lfs
	# make lapp

Or, `make mail` or `make nameserver`.

Once you create those, you're on your own with the configuration of the services!

