#!/bin/bash

#checks for new version of glibc on ubuntu and pacman on Arch Linux

#download and extract arch repo data
./repo_download.sh

#define pacman variables
sudo apt-get install ksh
PACMAN_FILE_NAME="$(ksh -c "awk '/%FILENAME%/{getline; print}' ./core_arch/pacman-+([0-9])*-+([0-9])*/desc")"
PACMAN_VERSION="$(echo $PACMAN_FILE_NAME | sed -n -e 's/-x86_64.pkg.tar.zst//p' | sed -n -e 's/pacman-//p')"

#defining glibc variables
sudo apt-get install glibc-source
apt-cache policy glibc-source > glibc.txt
glibc_version="$(awk '/glibc-source:/{getline; print}' ./glibc.txt | sed -n -e 's/  Installed: //p' | sed -n -e 's/ubuntu*.*//p')"

#make release_notes.md
cat << EOF > ../release_notes.md
Auto-built package

Versions:
Pacman $PACMAN_VERSION
Glibc $glibc_version
EOF

rm ./*.db
rm -rf ./*_arch
rm ./glibc.txt

if [ "$glibc_version" == "2.31-0" ]
then
    echo "No new version of glibc on Ubuntu, no need to rebuild"
else
    echo "New version of glibc! Re-building pacman"
    sed -i 's/2.31-0/'"$glibc_version"'/g' ./auto.sh
    sudo apt-get install gcc-10 bash glibc-source libarchive-tools libarchive13 libarchive-dev curl asciidoc fakechroot python3 libgpgme11 libgpgme-dev openssl libssl1.1 libssl-dev libcurl4 libcurl4-openssl-dev ksh
    cd ../
    ./build.sh
    cd ./auto 
fi

if [ "$PACMAN_VERSION" == "5.2.2-2" ]
then
    echo "No new version of pacman, no need to rebuild"
else
    echo "New version of pacman! Re-building pacman"
    sed -i 's/5.2.2-2/'"$PACMAN_VERSION"'/g' ./auto.sh
    sudo apt-get install gcc-10 bash glibc-source libarchive-tools libarchive13 libarchive-dev curl asciidoc fakechroot python3 libgpgme11 libgpgme-dev openssl libssl1.1 libssl-dev libcurl4 libcurl4-openssl-dev ksh
    cd ../
    ./build.sh
    cd ./auto  
fi

#release if there is a new package
if [ -f ../*.deb ]
then
    SIZE_CHECK=$(wc -c ../*.deb | awk '{print $1}')
    if [ "$SIZE_CHECK" -gt 500000 ]
    then    
        cd ../
        gh auth login --with-token < ../token.txt
        gh release create -R github.com/ThePoorPilot/pacman-utils $PACMAN_VERSION"_"$glibc_version -d ./*.deb -F ./release_notes.md  -t "$PACMAN_VERSION for glibc $glibc_version"
        #prep for pushing updated auto.sh to repo        
        rm -rf ./building
        rm ./*.deb
        rm ./release_notes.md
        ../push.sh
    else
        echo "Built package is under 500 kb, canceling build"
    fi
else
    echo "No new release"
    rm ../release_notes.md
fi


