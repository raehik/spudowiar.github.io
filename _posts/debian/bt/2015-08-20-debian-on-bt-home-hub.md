--- 
title: "Debian on a BT Home Hub"
date: Mon, 20 Aug 2015 19:37:31 +0100
description: |
    A comprehensive guide on installing Debian Jessie on the BT Home Hub 2.0 
    Type B
---

This is actually the second post? But it's the first?

Anyway... This tutorial shows you how to install Debian 8 on a BT Home Hub 2.0 
Type B running OpenWRT. Access to the [netconsole](!phpBB "openwrt.ebilan.co.uk" 
"f=11&t=6") is assumed, as is experience with Debian and Linux, in general.

{% tweet 635447242711764992 %}

Why? I have a BT Home Hub, a memory stick and way too much free time!

_**NOTE:** When configuring software using `menuconfig` it may be useful to know 
that pressing `/` pulls up a search box for configuration options._

# Outcome

It works. Really? Yep.

Debian 8.1 and OpenWRT `r46693` with `SysVinit` or `systemd`

# OpenWRT

## Getting the OpenWRT source code

```sh
git clone git://git.openwrt.org/openwrt.git
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
```

## Configuring OpenWRT

Start `menuconfig` and select the target

```kconfig
CONFIG_TARGET_lantiq=y
CONFIG_TARGET_lantiq_xway=y
CONFIG_TARGET_lantiq_xway_BTHOMEHUBV2B=y
```

Load the defaults for the target

```sh
make defconfig
```

Start `menuconfig` again and configure the following options or append these to 
`.config` and re-run `make defconfig`

* For USB support

```kconfig
CONFIG_KERNEL_BLK_DEV_BSG=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
```

* Populates `/dev` during early boot and a requirement of Debian

```kconfig
CONFIG_KERNEL_DEVTMPFS=y
CONFIG_KERNEL_DEVTMPFS_MOUNT=y
```

* For `ext4` support (change accordingly)

```kconfig
CONFIG_PACKAGE_kmod-fs-ext4=y
```

* For U-Boot configuration

```kconfig
CONFIG_PACKAGE_uboot-envtools=y
CONFIG_UBOOT_ENVTOOLS_UBI=y
```

* For `systemd` support (not required if using `SysVinit`)

```kconfig
CONFIG_KERNEL_CGROUPS=y
CONFIG_KERNEL_FHANDLE=y
```

## Configuring the kernel

* From `menuconfig` disable `CONFIG_SOFT_FLOAT`
* Start `make kernel_menuconfig` and enable `CONFIG_MIPS_FPU_EMULATOR`

_**NOTE:** When using `kernel_menuconfig` you may find options selected there 
are ignored. Although `kernel_menuconfig` provides direct access to the kernel's 
config, options available in OpenWRT's config (such as those in the previous 
section) override those in the kernel's config. At the time of writing, the MIPS 
FPU emulator is not available as an OpenWRT config option._

## Building OpenWRT

```sh
make
```

## Flashing OpenWRT

The `uImage` kernel and initramfs can be found in `bin/lantiq` and the 
`ubinized` images can be found in `build_dir/target-*/linux-lantiq_xway`. Make 
sure to flash the `ubifs` image instead of the `squashfs` image as the overlay 
is not mounted early enough in the boot process.

# Debian

The simplest way to install Debian is to use `debootstrap` and 
`qemu-user-static` then copy the folder to the USB drive. The USB drive should 
be partitioned with swap and a partition of the chosen filesystem (in this case, 
`ext2`). I partitoned mine with `swap` first (`/dev/sda1`) then `rootfs` after 
(`/dev/sda2`).

To build the `rootfs`

```sh
debootstrap --arch=mips --foreign jessie debian http://ftp.uk.debian.org/debian/
cp /usr/bin/qemu-mips-static debian/usr/bin
chroot debian /debootstrap/debootstrap --second-stage
```

On a `systemd`-based host, you can enter the `rootfs` using `systemd-nspawn`

```sh
systemd-nspawn -D debian -n
```

Otherwise use `chroot` and mount the pseudo-filesystems

Once you are inside the `rootfs`, you can configure the system and install 
packages. Make sure to setup the Ethernet switch and install and configure 
`openssh-server`

```,/etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.168.1.1
    netmask 255.255.255.0
```

To ensure `systemd-udevd` can access the modules, run

```sh
ln -s ../openwrt/lib/modules /lib/
```

And enable the swap

```,/etc/fstab
# <file system>                 <mount point>   <type> <options> <dump> <pass>
/dev/sda1                       none            swap    sw       0      0
```

Also, you could downgrade to `SysVinit` (tested, working) at this stage and a 
useful trick would be to light the _Power_ LED on boot (_**NOTE**: there is a 
red one!_)

```sh
ls /sys/class/leds/
```

# Installation

Debian's `init` must be run with PID 1. The boot process of OpenWRT is simple

1. _(device-specific stuff happens)_
2. `/etc/preinit` is launched with PID 1
3. `/etc/preinit` `exec`s `/sbin/init`
4. `/sbin/init` `exec`s `/sbin/procd` --- [OpenWRT's new all-singing all-dancing 
everything-replacement init system](http://wiki.openwrt.org/doc/techref/procd)
5. _(stuff happens)_
6. `/etc/preinit` launched as a child of `procd`
7. _(stuff happens)_

The idea is to rewire the boot process to

1. _(device-specific stuff happens)_
2. `/etc/preinit` is launched with PID 1
3. `/etc/preinit` `exec`s Debian's init **OR** continues boot

We only modify `/etc/preinit` slightly (it `source`s `/etc/debian_boot` and 
redirects the output to a debugging log on the NAND). We need to keep PID 1 but 
don't want to `exec` to `/etc/debian_boot` in case, for some reason, we can't 
boot Debian. Instead we `source` it so it runs in the same shell.

The anatomy of `/etc/debian_boot` is also very simple

* mount `/proc`, `/sys` (`/dev` will be mounted by `CONFIG_DEVTMPFS_MOUNT`)
* wait for USB drive
* if found, mount and `exec` Debian's init
* else, do nothing (so we return to and continue `/etc/preinit`)

To inject our code into `/etc/preinit` we must find the line which corresponds 
to step 3 in the OpenWRT boot process (shown above, in the first one)

```sh,/etc/preinit
[ -z "$PREINIT" ] && exec /sbin/init
```

This line should be the first line. Above this line we insert

```sh,/etc/preinit
[ $$ -eq 1 ] && . /etc/debian_boot >>/debian.log 2>&1
```

This means it only runs the first time (when PID is 1) and logs `stderr` and 
`stdout` to `/debian.log` on the NAND

```sh,/etc/debian_boot
#!/bin/sh
USB="/dev/sda2"
WAIT=5

echo "===================="
date
mount -t proc proc /proc
mount -t sysfs sys /sys
echo "Kernel filesystems mounted."

for module in ehci-hcd ehci-platform ltq_hcd_danube scsi_mod sd_mod usb-storage jbd2 ext4; do
    echo "Loading $module"
    modprobe $module
done
echo "Modules loaded."

mkdir -p /debian
for i in $(seq 0 $WAIT); do
    echo "Waiting $i seconds."
    mount -o rw,sync,noatime "$USB" /debian && break
    sleep 1
done

if [ -e /debian/sbin/init -o -L /debian/sbin/init ]; then
    echo "Linux installation found."
    echo 255 > "/sys/class/leds/soc:orange:upgrading/brightness"
    cd /debian
    mkdir -p openwrt
    pivot_root . openwrt
    echo "Starting /sbin/init."
    exec /sbin/init
fi

umount /debian
umount /sys
umount /proc
echo "Falling back to OpenWRT."
```

When reading this script, remember that the output is logged (e.g. `date` is for 
logging purposes only and won't affect the bootup, ditto for the `echo`s). This 
script  mounts `/proc` and `/sys`, loads required modules (`jdb2` is a 
dependency of `ext4`), waits on the USB for 5 seconds. If it is mounted and has 
`/sbin/init`, the orange  _Upgrading_ LED is lit and it is `pivot`ed into and 
`/sbin/init` is `exec`ed. Otherwise, we `umount` our mountpoints (to ensure the 
environment is as expected for OpenWRT) and fallthrough. Remember to change 
`$USB` to your requirements.

I would prefer to use `[ -x /debian/sbin/init ]` but that won't work in the case 
of `systemd` when it is a symlink to `/lib/systemd/systemd`, a file that is 
non-existent until we `pivot_root`. Sad face.

The script needn't be marked executable and, to avoid mistakes, perhaps 
shouldn't. Also, some of the modules may be unnecessary (I'm looking at you,
`ehci-hcd` and `ehci-platform`) as there is a Lantiq-specific `ltq_hcd_danube`. 
Can't hurt, eh?

Before booting, check that you can mount the USB drive from OpenWRT.

# Booting

This is the hardest part yet.

```sh
reboot
```

# Troubleshooting --- aka RTFL (the last one stands for logs)

If it boots into OpenWRT, then it couldn't find the memory stick or `/sbin/init` 
on it. Check you got `$USB` right, add some debugging into `/etc/debian_boot` 
(such as `ls /dev` or `df` or `mount` --- be creative!) For really slow memory 
sticks, if the _Upgrading_ LED fails to light, increase `$WAIT` to 10 or 15 then 
hop on to Amazon and buy yourself a new one :wink:

If you followed this tutorial you have many many logs for you to read. Where? 
Firstly there is `/debian.log` on the NAND if the _Power_ LED fails to light 
(after a **REASONABLE** amount of time --- don't be impatient!). Before unplugging 
the USB drive, try `ping`ing the router, it may be still booting!

If that doesn't tell you anything, howsa about some of them Debian logs? You can 
find them in `/var/log` and, if using `systemd`, you can find stuff in the 
journal.

Finally, check if you got the configuration options correct for OpenWRT and the 
kernel. Easy mistake to make!

:smile:
