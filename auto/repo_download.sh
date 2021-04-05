#!/bin/bash

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
