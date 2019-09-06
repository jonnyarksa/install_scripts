#!/bin/bash

NEW_USER=$(cat /etc/passwd | grep "/home" |cut -d: -f1 |head -1)
DISTRO_NAME=""

do_check_internet_connection(){
    ping -c 1 8.8.8.8 >& /dev/null   # ping Google's address
}

do_arch_news_latest_headline(){
    # gets the latest Arch news headline for 'kalu' config file news.conf
    local info=$(mktemp)
    wget -q -T 10 -O $info https://www.archlinux.org/ && \
        { grep 'title="View full article:' $info | sed -e 's|&gt;|>|g' -e 's|^.*">[ ]*||' -e 's|</a>$||' | head -n 1 ; }
    rm -f $info
}

do_config_for_app(){
    # handle configs for apps here; called from distro specific function

    local app="$1"    # name of the app

    case "$app" in
        kalu)
            mkdir -p /etc/skel/.config/kalu
            #mkdir -p /home/$NEW_USER/.config/kalu
            # add "Last=<latest-headline>" to news.conf, but don't overwrite the file
            printf "Last=" >> /etc/skel/.config/kalu/news.conf
            do_arch_news_latest_headline >> /etc/skel/.config/kalu/news.conf
            #cat /etc/skel/.config/kalu/news.conf >> /home/$NEW_USER/.config/kalu/news.conf
            #chown --recursive $NEW_USER:$NEW_USER /home/$NEW_USER/.config        # what if group name is not the same as user name?
            ;;
        update-mirrorlist)
            test -x /usr/bin/$app && {
                /usr/bin/$app
            }
            ;;
        # add other apps here!
        *)
            ;;
    esac
}

do_common_systemd(){

# Fix NetworkManager
systemctl enable NetworkManager -f 2>>/tmp/.errlog
systemctl disable multi-user.target 2>>/dev/null
systemctl enable vboxservice 2>>/dev/null
systemctl enable org.cups.cupsd.service 2>>/dev/null
systemctl enable avahi-daemon.service 2>>/dev/null
systemctl disable pacman-init.service choose-mirror.service

# Journal
sed -i 's/volatile/auto/g' /etc/systemd/journald.conf 2>>/tmp/.errlog

# Login manager should be set specifically

}

do_clean_archiso(){

# clean out archiso files from install 
rm -f /etc/sudoers.d/g_wheel 2>>/tmp/.errlog
rm -f /var/lib/NetworkManager/NetworkManager.state 2>>/tmp/.errlog
sed -i 's/.*pam_wheel\.so/#&/' /etc/pam.d/su 2>>/tmp/.errlog
find /usr/lib/initcpio -name archiso* -type f -exec rm '{}' \;
rm -Rf /etc/systemd/system/{choose-mirror.service,pacman-init.service,etc-pacman.d-gnupg.mount,getty@tty1.service.d}
rm -Rf /etc/systemd/scripts/choose-mirror
rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
rm -f /root/{.automated_script.sh,.zlogin}
rm -f /etc/mkinitcpio-archiso.conf
rm -Rf /etc/initcpio
rm -Rf /etc/udev/rules.d/81-dhcpcd.rules

}

do_vbox(){

# Detects if running in vbox
local xx

lspci | grep -i "virtualbox" >/dev/null
if [[ $? == 0 ]]
    then
        :      
        # Depends on which vbox package we're installing  
        #systemctl enable vboxservice
        #pacman -Rnsdd virtualbox-host-dkms --noconfirm
    else
        for xx in virtualbox-guest-utils virtualbox-guest-modules-arch virtualbox-guest-dkms ; do
            test -n "$(pacman -Q $xx 2>/dev/null)" && pacman -Rnsdd $xx --noconfirm
        done
        rm -f /usr/lib/modules-load.d/virtualbox-guest-dkms.conf
fi

}

do_display_manager(){
# no problem if any of them fails
systemctl -f enable gdm
systemctl -f enable lightdm
systemctl -f enable sddm
pacman -R gnome-software --noconfirm
pacman -Rsc gnome-boxes --noconfirm

}

do_clean_offline_installer(){

# cli installer
rm -rf /vomi 2>>/tmp/.errlog
#rm -rf ${BYPASS} 2>>/tmp/.errlog
rm -rf /source 2>>/tmp/.errlog
rm -rf /src 2>>/tmp/.errlog
rmdir /bypass 2>>/tmp/.errlog
rmdir /src 2>>/tmp/.errlog
rmdir /source 2>>/tmp/.errlog
rm -rf /offline_installer

# calamares installer
# not ready yet
pacman -Rns calamares_offline --noconfirm
}

do_endeavouros(){

# for some reason installed system uses bash
#chsh -s /usr/bin/zsh
rm -rf /home/$NEW_USER/.config/qt5ct
rm -rf /home/$NEW_USER/{.xinitrc,.xsession} 2>>/tmp/.errlog
rm -rf /root/{.xinitrc,.xsession} 2>>/tmp/.errlog
rm -rf /etc/skel/{.xinitrc,.xsession} 2>>/tmp/.errlog
sed -i "/if/,/fi/"'s/^/#/' /home/$NEW_USER/.bash_profile
sed -i "/if/,/fi/"'s/^/#/' /home/$NEW_USER/.zprofile
sed -i "/if/,/fi/"'s/^/#/' /root/.bash_profile
sed -i "/if/,/fi/"'s/^/#/' /root/.zprofile

do_display_manager

do_check_internet_connection && {
    #do_config_for_app update-mirrorlist
    do_config_for_app kalu
}

# keeping the code for now commented, to be purged in the future
# the new config folder is injected at customize_airootfs which makes this unecessary
#rm -rf /home/$NEW_USER/.config/xfce4/panel/launcher-17
#rm -rf /root/.config/xfce4/panel/launcher-17

rm -rf /usr/bin/calamares_switcher

systemctl enable lightdm 2>>/dev/null

}

########################################
########## SCRIPT STARTS HERE ##########
########################################

do_common_systemd
do_clean_archiso
#do_clean_offline_installer
do_endeavouros
rm -rf /usr/bin/calamares_switcher
rm -rf /usr/bin/cleaner_script.sh


