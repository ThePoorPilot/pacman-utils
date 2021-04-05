#!/bin/bash

#dependencies: ksh
#cleanup
rm -r ./*_arch
rm -r ./pacman-utils*
rm ./*.pkg.tar.zst
rm ./*.db

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

PACMAN_FILE_NAME="$(ksh -c "awk '/%FILENAME%/{getline; print}' ./core_arch/pacman-+([0-9])*-+([0-9])*/desc")"
PACMAN_VERSION="$(echo $PACMAN_FILE_NAME | sed -n -e 's/-x86_64.pkg.tar.zst//p' | sed -n -e 's/pacman-//p')"
PACMAN_SHA256SUM="$(ksh -c "awk '/%SHA256SUM%/{getline; print}' ./core_arch/pacman-+([0-9])*-+([0-9])*/desc")"
# for use in automatic bulding

#if [ "$PACMAN_FILE_NAME" == "latest_file_name" ]
#then
#    echo "No new version of the pacman package, exiting"
#    exit
#else
#    echo "New version of pacman found!"
#    :
#fi

echo "Downloading latest pacman package"
wget -q "$ARCH_REPO""core/os/x86_64/""$PACMAN_FILE_NAME"
echo "Checking SHA256"
SHA256SUM_CHECK="$(echo "$PACMAN_SHA256SUM  $PACMAN_FILE_NAME" | sha256sum --check | grep -c 'OK' )"
if [ "$SHA256SUM_CHECK" == "1" ]
then
    echo "SHA256SUM matches!"
else
    echo "SHA256SUM does not match, try again!"
    exit
fi

echo "Extracting..."
{
mkdir ./pacman-utils_"$PACMAN_VERSION"_amd64
mkdir ./pacman-utils_"$PACMAN_VERSION"_amd64/DEBIAN
tar -I zstd -xvf ./$PACMAN_FILE_NAME -C ./pacman-utils_"$PACMAN_VERSION"_amd64
} > /dev/null


rm ./pacman-utils_"$PACMAN_VERSION"_amd64/.PKGINFO
rm ./pacman-utils_"$PACMAN_VERSION"_amd64/.MTREE
rm ./pacman-utils_"$PACMAN_VERSION"_amd64/.BUILDINFO
#fixes issue with install, looks like this file already exists, but for slackware makepkg. Doesn't seem too important
rm ./pacman-utils_"$PACMAN_VERSION"_amd64/usr/share/bash-completion/completions/makepkg

SIZE="$(du -s -B1 --apparent-size ./pacman-utils_"$PACMAN_VERSION"_amd64 | sed -n -e s:./pacman-utils_"$PACMAN_VERSION"_amd64::p)"
INSTALLED_SIZE="$(expr $SIZE / 1024)"
echo "Creating control file"
cat << EOF > ./pacman-utils_"$PACMAN_VERSION"_amd64/DEBIAN/control
Package: pacman-utils
Version: $PACMAN_VERSION
License: GNU v2+
Architecture: amd64
Maintainer: Michael Monaco <thepoorpilot@gmail.com>
Installed-Size: $INSTALLED_SIZE
Depends: libarchive-tools, colorize, curl, python3, glibc-source, bash, libgpgme11, fakechroot, zstd, tar
Section: devel
Priority: optional
Description: Arch Linux development tools for Debian(makepkg, repo-add, etc.) Primarily for use in integration environments.
EOF

echo "Building package..."
dpkg --build ./pacman-utils_"$PACMAN_VERSION"_amd64/
