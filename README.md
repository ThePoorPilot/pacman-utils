# pacman-utils
Debian package that installs Arch Linux Pacman tools(repo-add, makepkg, etc.). This is primarily designed for integration environments. Most hosted integration environments don't have an Arch Linux image, but do have a Debian package.

With this package installed, for example, add pkg.tar.zst files to a .db file, and upload it to a custom repository(hinting at a future project of mine).

I have not tested all functionaly of this package yet, it may still need tuning.

Functionality tested:

repo-add works

makepkg works, but only with "-d" flag to skip dependency checks.

## Building

<code> git clone https://github.com/ThePoorPilot/pacman-utils.git </code>

You can choose to run either build.sh or build_compatibility.sh. Build.sh builds the latest package from the arch repos. This is fine if the tools you need to use are only shell based. 

If you need to use a c-based tool(vercmp, testpkg, pacman-conf) you are restricted by the latest version of glibc on Debian/Ubuntu. At this moment the latest on Ubuntu is 2.31 while the latest on Arch is 2.33. 2.31 was released on 02/01/2020. The last pacman package released before that date is 5.2.1-4. build_compatibility.sh builds this version for compatibility with c binaries. 

Alternatively, you could try building the newer verson of glibc, but I did not have much success with this approach. I also tried building pacman from source on Ubuntu, but it seems GCC also presents incompatibilities. This solution seems good enough if only used for integration, but those other avenues could perhaps be ironed out in the future.

Anyways, once you choose which script you want use, here is how you run them:

<code> sudo chmod +x ./build </code>

<code> ./build </code>
