#!/bin/bash

#Dependencies: sudo apt-get install gcc-10 bash glibc-source libarchive-tools libarchive13 libarchive-dev curl asciidoc fakechroot python3 libgpgme11 libgpgme-dev openssl libssl1.1 libssl-dev libcurl4 libcurl4-openssl-dev ksh

#cleanup in main directory
rm -rf ./building
rm ./*.deb

#make building directory so that main directory doesn't get all messy
mkdir ./building
cd ./building

#make sure all needed online services are up
ARCH_REPO_STATUS="$(curl -s -I https://mirrors.rit.edu/archlinux/ | grep -c '200')"
GITHUB_STATUS="$(curl -s -I https://github.com | head -1 | grep -c '200')"
ARCH_SOURCES_STATUS="$(curl -s -I https://sources.archlinux.org/other/ | grep -c '200')"
 
if [ "$ARCH_REPO_STATUS" == "1" ]
then
    echo "Arch Linux RIT mirror is up!"
    ARCH_REPO="https://mirrors.rit.edu/archlinux/"
else
    echo "Arch Linux RIT mirror not up, choosing another mirror"
    wget -O mirrorlist "https://archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
    ARCH_REPO="$(awk '/## United States/{getline; print}' ./mirrorlist | head -1 | sed -n -e 's/#Server = //p' | sed -n -e's:$repo/os/$arch::p')"
fi

if [ "$ARCH_SOURCES_STATUS" == "1" ]
then
    echo "Arch pkg Sources are up!"
else
    echo "Arch pkg sources are down! quitting..."
    exit
fi

if [ "$GITHUB_STATUS" == "1" ]
then
    echo "Github is up!"
else
    echo "Github is down! quitting..."
    exit
fi

#actually start building
echo "Downloading core.db"
wget -q "$ARCH_REPO""/core/os/x86_64/core.db"
echo "Extracting core.db"
mkdir ./core_arch
{
tar -zxf ./core.db -C ./core_arch
} > /dev/null


PACMAN_FILE_NAME="$(ksh -c "awk '/%FILENAME%/{getline; print}' ./core_arch/pacman-+([0-9])*-+([0-9])*/desc")"
PACMAN_VERSION="$(echo $PACMAN_FILE_NAME | sed -n -e 's/-x86_64.pkg.tar.zst//p' | sed -n -e 's/pacman-//p')"

pkgname=pacman
pkgrel="$(echo $PACMAN_VERSION | sed 's/^.*-//')"
pkgver="$(echo $PACMAN_VERSION | sed -n -e s/-$pkgrel//p)"
builtfiles="pacman-utils_$pkgver-$pkgrel"_amd64""
mkdir ./$builtfiles
curdir="$(pwd)"
pkgdir="$curdir/$builtfiles"

#download files
wget https://sources.archlinux.org/other/pacman/$pkgname-$pkgver.tar.gz

wget -O mirrorlist https://github.com/archlinux/svntogit-packages/raw/packages/pacman-mirrorlist/repos/core-any/mirrorlist
wget -O makepkg.conf https://github.com/archlinux/svntogit-packages/raw/packages/pacman/repos/core-x86_64/makepkg.conf
wget -O pacman.conf https://github.com/archlinux/svntogit-packages/raw/packages/pacman/repos/core-x86_64/pacman.conf

tar -xf ./$pkgname-$pkgver.tar.gz
mkdir ./$pkgname-$pkgver/build

#prepare
cd "$pkgname-$pkgver"
#this should be good enough for now. Patches seems relatively rare/insignificant in pacman. Future patches require human intervention
if [ "$pkgver" == "5.2.2" ]
then
    wget -O ./pacman-5.2.2-fix-strip-messing-up-file-attributes.patch https://git.archlinux.org/pacman.git/patch/?id=88d054093c1c99a697d95b26bd9aad5bc4d8e170
    patch -Np1 < ./pacman-5.2.2-fix-strip-messing-up-file-attributes.patch
    wget -O ./pacman-5.2.2-fix-debug-packages-with-gcc11.patch https://git.archlinux.org/pacman.git/patch/?id=bdf6aa3fb757a2363a4e708174b7d23a4997763d
    patch -Np1 < ./pacman-5.2.2-fix-debug-packages-with-gcc11.patch
else
    :
fi

#build
./configure --prefix=/usr --sysconfdir=/etc \
--localstatedir=/var --enable-doc \
--with-scriptlet-shell=/usr/bin/bash \
--with-ldconfig=/usr/bin/ldconfig
make V=1

#install
make DESTDIR="$pkgdir" install

#copy .conf files
cd ../
chmod 755 ./$builtfiles/etc
rm ./$builtfiles/etc/makepkg.conf
rm ./$builtfiles/etc/pacman.conf
cp makepkg.conf ./$builtfiles/etc
cp pacman.conf ./$builtfiles/etc

#fix pacman package error
rm ./$builtfiles/usr/share/bash-completion/completions/makepkg

#mirrorlist
mkdir ./$builtfiles/etc/pacman.d
cp ./mirrorlist ./$builtfiles/etc/pacman.d

#build archlinux-keyring
KEY_FILE_NAME="$(ksh -c "awk '/%FILENAME%/{getline; print}' ./core_arch/archlinux-keyring-+([0-9])*-+([0-9])*/desc")"
KEY_VERSION="$(echo $KEY_FILE_NAME | sed -n -e 's/-any.pkg.tar.zst//p' | sed -n -e 's/archlinux-keyring-//p')"

key_pkgname=archlinux-keyring
key_pkgrel="$(echo $KEY_VERSION | sed 's/^.*-//')"
key_pkgver="$(echo $KEY_VERSION | sed -n -e s/-$key_pkgrel//p)"

mkdir ./keyfiles
keydir="$curdir/keyfiles"
#download files
wget https://sources.archlinux.org/other/$key_pkgname/${key_pkgname}-${key_pkgver}.tar.gz
tar -xf ./${key_pkgname}-${key_pkgver}.tar.gz

#build keyring
cd ./${key_pkgname}-${key_pkgver}
make PREFIX=/usr DESTDIR="$keydir" install
cd ../
cp -r ./keyfiles/* ./$builtfiles

#make everything into a Debian package
SIZE="$(du -s -B1 --apparent-size ./$builtfiles | sed -n -e s:./$builtfiles::p)"
INSTALLED_SIZE="$(expr $SIZE / 1024)"

mkdir ./$builtfiles/DEBIAN
echo "Creating control file"
cat << EOF > ./$builtfiles/DEBIAN/control
Package: pacman-utils
Version: $PACMAN_VERSION
License: GNU
Architecture: amd64
Maintainer: Michael Monaco <thepoorpilot@gmail.com>
Installed-Size: $INSTALLED_SIZE
Depends: libarchive-tools, libarchive13, colorize, curl, python3, glibc-source, bash, libgpgme11, fakechroot, zstd, tar
Section: devel
Priority: optional
Description: Arch Linux development tools for Debian(makepkg, repo-add, etc.) Primarily for use in integration environments.
EOF

echo "Building package..."
dpkg --build ./$builtfiles/
mv ./$builtfiles.deb ../
