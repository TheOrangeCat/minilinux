#!/bin/sh
#
# MiniLinux builder!
# It is only build core system!
# Wroten by Egor Mikhailov aka Xeneloid, Nagakamira, Protonesso.
#
# Copyright © 2016-2017 Froyo Project , Inc.
#

DISTRO_VER=1.0

# Folders
DEST=$HOME/mini/fs
SRC=$HOME/mini/src
ISO=$HOME/mini/iso
OUT=$HOME/mini/ready

# Create this folders
install -d $DEST $SRC $ISO $OUT

echo "Starting build MiniLinux $DISTRO_VER..."

LINUX_VER=4.11
GLIBC_VER=2.25
BUSYBOX_VER=1.26.2
sysd=242

XFLAGS="-Os -s -fno-stack-protector -U_FORTIFY_SOURCE"

package_example() {
    cd $SRC
	wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$LINUX_VER.tar.xz

	echo -e "Preparing sources for Linux $LINUX_VER..."
	tar -xf linux-$LINUX_VER.tar.xz
	cd linux-$LINUX_VER

    echo "Linux $LINUX_VER is installed successfully!"
}

prepare_fs() {
    cd $DEST
    install -d dev etc root home proc media mnt sys tmp usr var
    cd usr
    install -d lib local games share
    cd $DEST
    cd var
    install -d cache lib lock log games run spool
    cd $DEST
    cd media
    install -d cdrom flash usbdisk
    cd $DEST
    chmod 1777 tmp
}

package_linux() {
    cd $SRC
	wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$LINUX_VER.tar.xz
	tar -xf linux-$LINUX_VER.tar.xz
	cd linux-$LINUX_VER
	make mrproper -j9
	make defconfig -j9
	sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\"minilinux\"/" .config
	sed -i "s/.*\\(CONFIG_KERNEL_.*\\)=y/\\#\\ \\1 is not set/" .config 
	sed -i "s/.*CONFIG_KERNEL_XZ.*/CONFIG_KERNEL_XZ=y/" .config
	sed -i "s/^CONFIG_DEBUG_KERNEL.*/\\# CONFIG_DEBUG_KERNEL is not set/" .config
	sed -i "s/.*CONFIG_EFI_STUB.*/CONFIG_EFI_STUB=y/" .config
	grep -q "CONFIG_X86_32=y" .config
	if [ $? = 1 ] ; then
		echo "CONFIG_EFI_MIXED=y" >> .config
    fi
	make CFLAGS="${XFLAGS}" -j9
	echo "Installing Linux $LINUX_VER..."
	mkdir $DEST/boot
	cp arch/x86/boot/bzImage $DEST/boot/vmlinuz-$LINUX_VER-minilinux
	cp .config $DEST/boot/config-$LINUX_VER-minilinux
	cp arch/x86/boot/bzImage $ISO/bzImage
	make INSTALL_MOD_PATH=$DEST modules_install -j9
	make INSTALL_FW_PATH=$DEST/lib/firmware firmware_install -j9
	make INSTALL_HDR_PATH=$DEST/usr headers_install -j9
}

package_glibc() {
    cd $SRC
	wget -c https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VER.tar.xz
	tar -xf glibc-$GLIBC_VER.tar.xz
	cd glibc-$GLIBC_VER
    mkdir build
    cd build
    ../configure \
        --prefix= \
        --with-headers=$DEST/usr/include \
        --without-gd \
        --without-selinux \
        --disable-werror \
        CFLAGS="${XFLAGS}"
    make -j9
    make install_root=$DEST install-j9
}

package_busybox() {
	cd ${SRC}
	wget -c http://busybox.net/downloads/busybox-$BUSYBOX_VER.tar.bz2
	tar -xf busybox-$BUSYBOX_VER.tar.bz2
	cd busybox-$BUSYBOX_VER
  	make defconfig -j9
	sed -i "s/.*CONFIG_INETD.*/CONFIG_INETD=n/" .config
	make EXTRA_CFLAGS="${XFLAGS}" -j9
    make CONFIG_PREFIX=$DEST install -j9
}

package_sysd() {
	cd ${SRC}
	wget -c https://github.com/systemd/systemd/archive/v$sysd.zip
	tar -xf v$sysd.zip
	cd v$sysd
	make defconfig
	make
	make CONFIG_PREFIX=$dest install
}

prepare_fs
package_linux
package_glibc
package_busybox
package_sysd

exit 0
