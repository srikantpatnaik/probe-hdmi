#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# This program is intended to write/copy images to any media or drive.

# This script depends on 'easybashgui'.
# The password function has extra dependency on 'zenity' & 'dialog'
# programs, which can be modified to work with other libraries too

source easybashgui

#Paths
fb1=/etc/X11/xorg.conf.fb1
xorg=/etc/X11/xorg.conf

function sudo_access() {
# Clear remember password
sudo -K
# The only place 'easybashgui' fails. So adding separate functions for both tty(consoles)
# and pts(terminals). If tty not found, it returns 1, and 'zenity' is used
tty | grep tty
if [ $? -eq 1 ]; then

while true
        do
                password=$(zenity --title "Enter your password to continue" --password)
                # zenity dialog button 'Cancel' returns 1, and 'Yes' returns 0.
                [ $? -eq 1 ] && exit 0
                echo $password | sudo -S echo "test">/dev/null
                # If wrong password then brek
                [ $? -eq 0 ] && break
        done
else

while true
        do
                password=$(dialog --title "Password" \
                  --clear \
                  --passwordbox "Enter your password" 10 30 \
                  --stdout)
        [ $? -eq 1 ] && exit 0
                echo $password | sudo -S echo "test">/dev/null
                # If wrong password then brek
                [ $? -eq 0 ] && break
        done
fi
}

# ==================================================================================

function probe_hdmi() {

kernel_resolution=$(cat /sys/class/graphics/fb1/modes | cut -d ':' -f2 | cut -d '-' -f1)
which_fb=$(lsof /dev/fb* 2>1 | grep -om1 "fb[1|0]")

if [ $kernel_resolution == '1024x720p' ] && [ $which_fb == 'fb0' ]; then
return_code_A=$(question -w 800 -h 200 "There are two possible settings, A and B. You are in Setting-(A) (default setting): HDMI might work in setting-(A) with thick bottom bar.\\n The setting-(B) will make your bottom panel unvailable on netbook screen, but HDMI might work in full screen. \\nYour desktop will be reloaded, hence save your files. Select 'Ok' to try setting-(B), select 'Cancel' to continue Setting-(A). \\nYou may change from setting-(B) to setting-(A) anytime by revisiting this application" 2>&1)
[ $return_code_A -eq 1 ] &&  exit 0
sudo cp -v $fb1 $xorg;
sudo service lightdm stop;
lightdm_stop=$(service lightdm status|grep -o stop)
	while [[ $lightdm_stop == 'stop' ]] ; do
		sleep 1
		sudo service lightdm restart &&\
		lightdm_stop=$(service lightdm status|grep -o stop)
	done
exit 0
fi

# ---------------------------------------------------------------------------------

if [ $kernel_resolution == '1024x720p' ] && [ $which_fb == 'fb1' ]; then
return_code_B=$(question -w 350 -h 250 "You are in setting-(B): Do you wish to change to setting-(A)(default setting)? Select 'Ok' to switch to setting-(A). Select 'Cancel' to continue setting-(B)" 2>&1)
[ $return_code_B -eq 1 ] && exit 0
sudo rm -v $xorg;
sudo service lightdm stop;
lightdm_stop=$(service lightdm status|grep -o stop)
	while [[ $lightdm_stop == 'stop' ]] ; do
		sudo service lightdm restart &&\
		sleep 1
		lightdm_stop=$(service lightdm status|grep -o stop)
	done
exit 0
fi

}

sudo_access
probe_hdmi
