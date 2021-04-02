#!/bin/bash

#dependencies: ksh
#cleanup
rm -rf ./glibc_build
rm ./*.deb

#make directory for building to keep things clean
mkdir ./glibc_build
cd ./glibc_build

ARCH_REPO_STATUS="$(curl -s -I https://mirrors.rit.edu/archlinux/ | grep -c '200')" 
if [ "$ARCH_REPO_STATUS" == "1" ]
then
    echo "Arch Linux RIT mirror is up!"
    ARCH_REPO="https://mirrors.rit.edu/archlinux/"
else
    echo "Arch Linux RIT mirror not up, choosing another mirror"
    wget -O mirrorlist "https://archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
    ARCH_REPO="$(awk '/## United States/{getline; print}' ./mirrorlist | head -1 | sed -n -e 's/#Server = //p' | sed -n -e's:$repo/os/$arch::p')"
fi

echo "Downloading core.db"
wget -q "$ARCH_REPO""/core/os/x86_64/core.db"
echo "Extracting core.db"
mkdir ./core_arch
{
tar -zxf ./core.db -C ./core_arch
} > /dev/null

glibc_FILE_NAME="$(ksh -c "awk '/%FILENAME%/{getline; print}' ./core_arch/glibc-+([0-9])*-+([0-9])*/desc")"
glibc_VERSION="$(echo $glibc_FILE_NAME | sed -n -e 's/-x86_64.pkg.tar.zst//p' | sed -n -e 's/glibc-//p')"
glibc_SHA256SUM="$(ksh -c "awk '/%SHA256SUM%/{getline; print}' ./core_arch/glibc-+([0-9])*-+([0-9])*/desc")"
# for use in automatic bulding

#if [ "$glibc_FILE_NAME" == "latest_file_name" ]
#then
#    echo "No new version of the glibc package, exiting"
#    exit
#else
#    echo "New version of glibc found!"
#    :
#fi

echo "Downloading latest glibc package"
wget -q "$ARCH_REPO""core/os/x86_64/""$glibc_FILE_NAME"
echo "Checking SHA256"
SHA256SUM_CHECK="$(echo "$glibc_SHA256SUM  $glibc_FILE_NAME" | sha256sum --check | grep -c 'OK' )"
if [ "$SHA256SUM_CHECK" == "1" ]
then
    echo "SHA256SUM matches!"
else
    echo "SHA256SUM does not match, try again!"
    exit
fi

builtfiles="glibc-source_"$glibc_VERSION"_amd64"
echo "Extracting..."
{
mkdir ./$builtfiles
mkdir ./$builtfiles/DEBIAN
tar -I zstd -xvf ./$glibc_FILE_NAME -C ./$builtfiles
} > /dev/null


rm ./$builtfiles/.PKGINFO
rm ./$builtfiles/.MTREE
rm ./$builtfiles/.BUILDINFO

SIZE="$(du -s -B1 --apparent-size ./$builtfiles | sed -n -e s:./$builtfiles::p)"
INSTALLED_SIZE="$(expr $SIZE / 1024)"
echo "Creating control file"
cat << EOF > ./$builtfiles/DEBIAN/control
Package: glibc-source
Version: $glibc_VERSION
License: GNU
Architecture: amd64
Maintainer: Michael Monaco <thepoorpilot@gmail.com>
Installed-Size: $INSTALLED_SIZE
Depends: xz-utils
Section: devel
Priority: optional
Description: glibc built from Arch Linux Package. This is designed to be used in conjuction with pacman-utils https://github.com/ThePoorPilot/pacman-utils
EOF

echo "Building package..."
dpkg --build ./$builtfiles/
mv ./$builtfiles.deb ../
