#!/bin/bash

#Setup script to configure vmware-view client in ltsp-chroot
DIR=$1
ARCH=i386
CHROOT="/opt/ltsp/$DIR"

if [ -z $ARCH ]; then
	echo usage : ./setupvmview.sh ltsparch_path
	exit 1;
fi

if [ ! -d $CHROOT ]; then
	echo /opt/ltsp/$DIR is not a valid path
	echo Please first build default ltsp client with "ltsp-build-client --chroot $DIR --arch $ARCH --dist precise"
	exit 1;
fi

CLIENT_BUNDLE=`ls VMware-Horizon-Client*.bundle 2> /dev/null`

if [ -z $CLIENT_BUNDLE ]; then
	echo "VMware-Horizon-Client bundle file not Found";
	echo "please visit http://www.vmware.com/go/viewclients and download last release for Linux";
	exit 1;
fi


if [ ! -f  $CHROOT/root/$CLIENT_BUNDLE ]; then
	echo "Found $CLIENT_BUNDLE try to install it"
	cp $CLIENT_BUNDLE $CHROOT/root/
	chmod a+x $CHROOT/root/$CLIENT_BUNDLE
	ltsp-chroot --arch $DIR  /root/$CLIENT_BUNDLE
else
	echo "$CLIENT_BUNDLE already present in chroot"
	echo "Continue"
fi

#REquired packages for vmware-view
for i in libxss1 openssl x11vnc hsetroot openbox
do
	echo install package $i
	ltsp-chroot --arch $DIR apt-get install $i
done

echo "link libraries"
ltsp-chroot  --arch $DIR ln -s /usr/lib/vmware/view/usb/libssl.so.1.0.1 /lib/$ARCH-linux-gnu/libssl.so.1.0.1
ltsp-chroot  --arch $DIR ln -s /usr/lib/vmware/view/usb/libcrypto.so.1.0.1 /lib/$ARCH-linux-gnu/libcrypto.so.1.0.1
ltsp-chroot  --arch $DIR ln -s /lib/i386-linux-gnu/libudev.so.1 /lib/$ARCH-linux-gnu/libudev.so.0


echo "copy root profile"
cp -rv root $CHROOT/

echo "copy ltsp scripts"
cp -rv xinitrc.d $CHROOT/usr/share/ltsp/
cp -rv screen.d $CHROOT/usr/share/ltsp/

echo "change kernel generator config"
if [ ! -d $CHROOT/etc/ltsp ]; then
	mkdir $CHROOT/etc/ltsp
fi
if [ -f etc/ltsp/ltsp-update-kernel.conf ]; then
	cp etc/ltsp/ltsp-update-kernel.conf $CHROOT/etc/ltsp/
	ltsp-chroot --arch $DIR /usr/share/ltsp/update-kernels
fi

#Needed to include root home dir into squashfs image (unbuntu Trusty)
if [ -f /etc/ltsp/ltsp-update-images.excludes ]; then
	echo "change update-image exlcudes"
	cp /etc/ltsp/ltsp-update-image.excludes /etc/ltsp/update-image.excludes.bak
	cp etc/ltsp/ltsp-update-image.excludes /etc/ltsp/
fi
