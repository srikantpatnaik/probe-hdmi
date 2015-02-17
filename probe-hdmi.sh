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
fb1=/tmp/etc/X11/xorg.conf.fb1
xorg=/tmp/etc/X11/xorg.conf
logfile=/tmp/var/log/hdmi.log

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

function probe_hdmi() {

question -w 350 -h 250 "Do you want to try alternate setting for HDMI? The next setting will make your bottom panel unvailable on netbook temporary. You can revert to normal screen after reboot." 2>&1

if [ $? -eq 0 ]; then
	cp -v $fb1 $xorg>>$logfile
	service lightdm status&>>$logfile
	[ $? -eq 1 ] && \
	question -w 350 -h 250 "Changing to new setting failed. Restoring previous configuration." 2>&1 && \
        rm -v /tmp/etc/X11/xorg.conf>>$logfile && service lightdm status
else
	exit 0
fi

}

#sudo_access
probe_hdmi
























