#!/bin/bash

#only executed if a neew .deb package is built and found in auto.sh
#operates from home directory

PASSWORD="insert_password_here"

echo "Pushing revised auto.sh to GitHub..."
git config --global user.name "ThePoorPilot"
git config --global user.email "ios8jailbreakpangu@gmail.com"
git add .
git commit -m 'changed version number in build checking'
git push https://ThePoorPilot:"$PASSWORD"@github.com/ThePoorPilot/pacman-utils.git 
