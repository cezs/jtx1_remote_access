# Built VirtualGL, TurboVNC and libjpeg-turbo for 64-bit Linux For Tegra R24.1.
#
# Largely based on https://devtalk.nvidia.com/default/topic/828974/jetson-tk1/-howto-install-virtualgl-and-turbovnc-to-jetson-tk1/2
#

mkdir tmp
cd tmp
currentDir=$(pwd)

# DEPENDENCIES

# install necessary packages to build them.
sudo apt-get install git
sudo apt-get install autoconf
sudo apt-get install libtool
sudo apt-get install cmake
sudo apt-get install g++
sudo apt-get install libpam0g-dev
sudo apt-get install libssl-dev

# LIBJPEG-TURBO

# Build and install libjpeg-turbo
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
mkdir libjpeg-turbo-build
cd libjpeg-turbo
autoreconf -fiv
cd ../libjpeg-turbo-build
sh ../libjpeg-turbo/configure
make
# Change "DEBARCH=aarch64" to "DEBARCH=arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/makedpkg.tmpl
make deb
# sudo dpkg -i libjpeg-turbo_1.5.2_arm64.deb
cd ../

# VIRTUALGL

# Preventing link error from "libGL.so", check this:
# https://devtalk.nvidia.com/default/topic/946136/jetson-tx1/building-an-opengl-application/
cd /usr/lib/aarch64-linux-gnu
sudo rm libGL.so
sudo ln -s /usr/lib/aarch64-linux-gnu/tegra/libGL.so libGL.so

# Build and install VirtualGL
cd $currentDir
git clone https://github.com/VirtualGL/virtualgl.git
mkdir virtualgl-build
cd virtualgl-build
cmake -G "Unix Makefiles" -DTJPEG_LIBRARY="-L/opt/libjpeg-turbo/lib64/ -lturbojpeg" ../virtualgl
make
# Change "DEBARCH=aarch64" to "DEBARCH=arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/makedpkg
# Change "Architecture: aarch64" to "Architecture: arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/deb-control
make deb
# sudo dpkg -i sudo dpkg -i virtualgl_2.5.2_arm64.deb
cd ..

# TURBOVNC

# Build and install TurboVNC
git clone https://github.com/TurboVNC/turbovnc.git

mkdir turbovnc-build
cd turbovnc-build
cmake -G "Unix Makefiles" -DTVNC_BUILDJAVA=0 -DTJPEG_LIBRARY="-L/opt/libjpeg-turbo/lib64/ -lturbojpeg" ../turbovnc

# Prevent error like #error "GLYPHPADBYTES must be 4",
# edit ../turbovnc/unix/Xvnc/programs/Xserver/include/servermd.h
# and prepend before "#ifdef __avr32__"
servermd="$currentDir/turbovnc/unix/Xvnc/programs/Xserver/include/servermd.h"
line="#ifdef __avr32__"
defs="#ifdef __aarch64__\n\
# define IMAGE_BYTE_ORDER       LSBFirst\n\
# define BITMAP_BIT_ORDER       LSBFirst\n\
# define GLYPHPADBYTES          4\n\
#endif\n"
sed -i "/$line/i $defs" "$servermd"
make
# Change "DEBARCH=aarch64" to "DEBARCH=arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/makedpkg
# Change "Architecture: aarch64" to "Architecture: arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/deb-control
make deb
# sudo dpkg -i turbovnc_2.1.1_arm64.deb

# SYSTEM

# Add system-wide configurations
cd $currentDir
echo "/opt/libjpeg-turbo/lib64" > libjpeg-turbo.conf
sudo cp libjpeg-turbo.conf /etc/ld.so.conf.d/
sudo ldconfig
rm ./libjpeg-turbo.conf

# Add TurboVNC to path
if ! grep -Fq "/opt/TurboVNC/bin" "$HOME/.bashrc"; then
    echo 'export PATH=$PATH:/opt/TurboVNC/bin' >> ~/.bashrc
fi

# Add VirtualGL to path
if ! grep -Fq "/opt/VirtualGL/bin" "$HOME/.bashrc"; then
    echo 'export PATH=$PATH:/opt/VirtualGL/bin' >> ~/.bashrc
fi

# copied from https://github.com/nicksp/dotfiles/blob/master/setup.sh
answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}

print_question() {
  # Print output in yellow
  printf "\e[0;33m  [?] $1\e[0m"
}

# copied from https://github.com/nicksp/dotfiles/blob/master/setup.sh
ask_for_confirmation() {
  print_question "$1 (y/n) "
  read -n 1
  printf "\n"
}

cd ..
ask_for_confirmation "Do you want to remove leftover files?"
if answer_is_yes; then
    rm -drf tmp
fi
