# Built VirtualGL, TurboVNC and libjpeg-turbo for 64-bit Linux For Tegra R24.1.
#
# Based on https://devtalk.nvidia.com/default/topic/828974/jetson-tk1/-howto-install-virtualgl-and-turbovnc-to-jetson-tk1/2
#

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

# Configure VirtualGL
# See https://cdn.rawgit.com/VirtualGL/virtualgl/2.5/doc/index.html#hd006
echo -e "Configuring VirtualGL..." 
sudo /opt/VirtualGL/bin/vglserver_config
sudo usermod -a -G vglusers ubuntu
echo -e "\n" 

# Install xfce4
echo -e "Configuring window manager...\n" 
ask_for_confirmation "Do you want to install xfce4 window manager? (There might be problems with running default unity on TurboVNC)."
if answer_is_yes; then
    xstartup="$HOME/.vnc/xstartup.turbovnc"
    line="unset DBUS_SESSION_BUS_ADDRESS"
    startline="# enable copy and paste from remote system\n\
vncconfig -nowin &\n\
export XKL_XMODMAP_DISABLE=1\n\
autocutsel -fork\n\
# start xfce4\n\
startxfce4 &"
    sudo apt-get install xfce4 gnome-icon-theme-full xfce4-terminal
    if ! grep -Fq "startxfce4" $xstartup; then
        sed -i "/$line/a $startline" $xstartup
    fi
fi
