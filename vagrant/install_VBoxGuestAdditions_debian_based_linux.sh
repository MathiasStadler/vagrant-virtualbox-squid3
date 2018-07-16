#!/bin/bash
set -e

# get filename
readonly FILENAME=$(basename "$0")

# for info if cache dir mounted before script running
echo "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" >"/tmp/mount_$FILENAME.txt"
# blank line
echo "mounts before run this script" >>"/tmp/mount_$FILENAME.txt"
mount >>/tmp/mount_"$FILENAME".txt

# from here
# https://gist.github.com/hollodotme/9388876996845ed7397d

# we provide the VirtualBox host version with a vagrant file provision
# config.vm.provision "file", source: "/tmp/VirtualBoxHostVersion.txt", destination: "/home/vagrant/VirtualBoxHostVersion.txt"

VERSION=$(cat /home/vagrant/VirtualBoxHostVersion.txt)

# variables
CACHE_DIRECTORY="/var/cache/apt/archives"
VBOX_GUEST_ADDITIONS="VBoxGuestAdditions_$VERSION.iso"
LOOP_MOUNT_POINT="/media/VBoxGuestAdditions"

# uninstall old dep packages if available
if dpkg --list | grep virtualbox-guest; then

	apt-get -y -q purge virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
else
	echo "No DEP packages for virtualbox installed"
fi

sudo apt-get update
sudo apt-get install -y linux-headers-"$(uname -r)" curl build-essential dkms

# move to cache directory
cd $CACHE_DIRECTORY

# used available file is there save network bandwidth
if [ ! -f "$VBOX_GUEST_ADDITIONS" ]; then
	sudo curl -O "http://download.virtualbox.org/virtualbox/$VERSION/$VBOX_GUEST_ADDITIONS"
else echo "File already there"; fi
sudo mkdir -p $LOOP_MOUNT_POINT

# umount iso is mount for rerun w/o reboot
if mount | grep $LOOP_MOUNT_POINT >/dev/null; then
	sudo umount $LOOP_MOUNT_POINT
fi
# mount iso
sudo mount -o loop,ro "$CACHE_DIRECTORY/VBoxGuestAdditions_$VERSION.iso" $LOOP_MOUNT_POINT

# from here
# https://github.com/dotless-de/vagrant-vbguest/issues/252
# disable exit on error for this error
# Could not find the X.Org or XFree86 Window System, skipping
# start sub shell
(env LOOP_MOUNT_POINT=$LOOP_MOUNT_POINT sh -c $LOOP_MOUNT_POINT/VBoxLinuxAdditions.run --nox11 -- --force >/tmp/VBoxLinuxAdditions.out) &

wait # Don't execute the next command until sub shells finish.

sudo umount $LOOP_MOUNT_POINT
# we used cache directory not delete for the next vm sudo rm -rf "VBoxGuestAdditions_$VERSION.iso"
sudo rmdir $LOOP_MOUNT_POINT

echo "VBox Linux Addition info"
/sbin/modinfo vboxsf
/sbin/modinfo vboxvideo
