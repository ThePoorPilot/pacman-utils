# pacman-utils
Debian package that installs Arch Linux Pacman tools(repo-add, makepkg, etc.). This is primarily designed for integration environments. Most hosted integration environments(such as github actions) don't have an Arch Linux image, but do have a Debian package.

![](https://github.com/ThePoorPilot/pacman-utils/raw/main/Screenshot.png)

With this package installed, for example, add pkg.tar.zst files to a .db file, and upload it to a custom repository(hinting at a future project of mine).

Functionality tested:

Working: repo-add, repo-remove, repo-elephant, makepkg(requires -d flag), testpkg, makpkg-template, pacman-key, pacman-conf, pacman-db-upgrade 

Sort of works: pacman -Sdd to install packages. Not important functionality if focused on integration.

### Installing
Download your prefered .deb package here: https://github.com/ThePoorPilot/pacman-utils/releases

Note: this repo automatically rebuilds pacman-utils when a new version of pacman or glibc is released. In scripting, it would be best to manually test each new release for compatibility and then change the download link.

Install using apt or dpkg.

An example of this step in a script

<code> wget https://github.com/ThePoorPilot/pacman-utils/releases/download/5.2.2-2/pacman-utils_5.2.2-2_amd64.deb</code>

<code>sudo apt-get install ./pacman-utils_5.2.2-2_amd64.deb</code>

### Building

<code> git clone https://github.com/ThePoorPilot/pacman-utils.git </code>

You can choose to run either build.sh or build_exp.sh. build.sh builds the latest package from the arch repos. This is fine if the tools you need to use are only shell based.

build_exp.sh is currently "experimental" and in need of improvements. Compiling from source seems like the best option for compatibility, but the current version of the script needs to be more versatile.

Once you choose which script you want use, here is how you run them:

<code> sudo chmod +x ./build </code>

<code> ./build </code>
