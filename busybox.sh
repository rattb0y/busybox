#!/bin/bash

KERNEL_VERSION=6.7.6
KERNEL_MAJOR=$(echo $KERNEL_VERSION | sed 's/\([0-9]*\)[^0-9].*/\1/')
BUSYBOX_VERSION=1.36.1

mkdir -p src
cd src
	# Kernel
	wget https://mirrors.edge.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR.x/linux-$KERNEL_VERSION.tar.xz
  echo 'Extracting the Kernel Tar File'
  tar -xf linux-$KERNEL_VERSION.tar.xz
	cd linux-$KERNEL_VERSION
      echo 'Building a Default config of the Linux Kernel'
	    make defconfig
	    make -j8 || exit
	cd ..
	
	# Busybox
	wget https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
  echo 'Extracting the Busybox Tar File'
	tar -xf busybox-$BUSYBOX_VERSION.tar.bz2
	cd busybox-$BUSYBOX_VERSION
      echo 'Building a Default config of Busybox'
	    make defconfig
	    sed 's/^.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/g' -i .config
	    make -j8 busybox || exit
	cd ..
cd ..

cp src/linux-$KERNEL_VERSION/arch/x86_64/boot/bzImage ./

# initrd
mkdir initrd
cd initrd
	mkdir -p bin dev proc sys
	cd bin
	   cp ../../src/busybox-$BUSYBOX_VERSION/busybox ./
	    for prog in $(./busybox --list); do
	        ln -s /bin/busybox ./$prog
	    done
	cd ..

	echo '#!/bin/sh' > init
	echo 'mount -t sysfs sysfs /sys' >> init
	echo 'mount -t proc proc /proc' >> init
	echo 'mount -t devtmpfs udev /dev' >> init
	echo 'sysctl -w kernel.printk="2 4 1 7"' >> init
	echo 'clear' >> init
	echo '/bin/sh' >> init
	echo 'poweroff -f' >> init
	chmod -R 777 .
	find . | cpio -o -H newc > ../initrd.img

cd ..

qemu-system-x86_64 -kernel bzImage -initrd initrd.img
