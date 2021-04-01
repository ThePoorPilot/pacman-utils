# pacman-utils
Debian package that installs Arch Linux Pacman tools(repo-add, makepkg, etc.). This is primarily designed for integration environments. Most hosted integration environments don't have an Arch Linux image, but do have a Debian package.

With this package installed, for example, add pkg.tar.zst files to a .db file, and upload it to a custom repository(hinting at a future project of mine).

I have not tested all functionaly of this package yet, it may still need tuning.

Functionality tested:

repo-add works

makepkg works, but requires "-d" flag to skip dependency checks.

pacman -S works, but I've only been able to install cmatrix. Most apps don't install correctly, but that's not the point.

## Building

<code> git clone https://github.com/ThePoorPilot/pacman-utils.git </code>

You can choose to run either build.sh or build_exp.sh. build.sh builds the latest package from the arch repos. This is fine if the tools you need to use are only shell based.

build_exp.sh is currently "experimental" and in need of improvements. Compiling from source seems like the best option for compatibility, but the current version of the script needs to be more versatile.

Once you choose which script you want use, here is how you run them:

<code> sudo chmod +x ./build </code>

<code> ./build </code>

## Installing
Download your prefered .deb package here: https://github.com/ThePoorPilot/pacman-utils/releases

Install using apt or dpkg.

An example of this step in a script

<code> wget https://github.com/ThePoorPilot/pacman-utils/releases/download/5.2.2-2/pacman-utils_5.2.2-2_amd64.deb</code>

<code>sudo apt install ./pacman-utils_5.2.2-2_amd64.deb</code>
