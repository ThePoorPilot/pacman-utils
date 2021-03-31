#!/bin/bash

#dependencies: ksh
#cleanup
rm -r ./*_arch
rm -r ./pacman-utils*
rm ./*.pkg.tar.zst
rm ./*.db


PACMAN_FILE_URL="https://archive.archlinux.org/packages/p/pacman/pacman-5.2.1-4-x86_64.pkg.tar.zst"
PACMAN_FILE_NAME="pacman-5.2.1-4-x86_64.pkg.tar.zst"
PACMAN_VERSION="5.2.1-4"

echo "Downloading latest pacman package"
wget -q "$PACMAN_FILE_URL"

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
 
