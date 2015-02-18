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
logfile=/tmp/hdmi.log
boot_part=/dev/mtd4
kernel_image_master=/opt/probe-hdmi/kernels/uzImage.bin.master.1280x720.1024x720
kernel_image_alternate=/opt/probe-hdmi/kernels/uzImage.bin.alternate.1024x600.1280x720
ramdisk_image=/opt/probe-hdmi/kernels/initrd.img
setting_b_activated=/opt/probe-hdmi/setting_c_flashed
setting_c_flashed=/opt/probe-hdmi/setting_c_flashed
setting_c_activated=/opt/probe-hdmi/setting_c_activated
#echo>$logfile

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

[ $kernel_resolution == '1024x720p' ] && [ ! -f $xorg ] &&\
question  "There are three possible settings, A, B, and C. You are in Setting-(A) (default setting) [HDMI might work in setting-(A) with thick bottom bar]: Is HDMI detected at all? If not, do you wish to try setting-(B)? The setting-(B) will make your bottom panel unvailable on netbook screen, but HDMI might work in full screen. Your desktop will be reloaded, save your files, if any. Select 'Ok' to try setting-(B), select 'Cancel' to continue Setting-(A). You may change from setting-(B) to setting-(A) anytime by revisiting this application" 2>&1 && exit 0

[ $kernel_resolution == '1024x720p' ] && [ ! -f $xorg ] &&\
sudo cp -v $fb1 $xorg>>$logfile &&\
sudo touch $setting_b_activated &&\
sudo service lightdm restart &&\
exit 0

#-=========================================================================================

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ -f $setting_b_activated ] &&\
question -w 350 -h 250 "You are in setting-(B): Do you wish to change to setting-(A)(default setting)? Select 'Ok' to switch to setting-(A). Select 'Cancel' to proceed further." 2>&1 && exit 0
[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ -f $setting_b_activated ]
sudo rm -v $xorg>>$logfile &&\
sudo service lightdm restart && exit 0

# ----------------------------------------------------

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ ! -f $setting_b_activated ] &&\
question "You are in setting-(B): If it works, it is highly recommended to use this setting. If not, you may switch to setting-(C), HDMI might work in full screen with HD resolution(available only in setting-(C)), but netbook screen may go blank. Select 'Ok' to apply setting-(C) (will require 20 seconds, system will be restarted(will confirm restart one more time)). Select 'Cancel' to retain setting-(B). Also, please note, to complete setting-(C) you may also have to do 'Ctrl+Alt+F1' in netbook after restart, login and restart this application by typing 'probehdmi' on console" 2>&1 && exit 0

# ----------------------------------------------------

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ ! -f $setting_c_flashed ] &&\
sudo cp -v $fb1 $xorg>>$logfile &&\
sudo mkbootimg --kernel $kernel_image_alternate --ramdisk $ramdisk_image -o /tmp/boot.img && sync &&\
sudo echo 0 > /sys/module/yaffs/parameters/yaffs_bg_enable &&\
sudo flash_erase $boot_part 0 0 &&\
sudo nandwrite -p $boot_part /tmp/boot.img &&\
sudo echo 1 > /sys/module/yaffs/parameters/yaffs_bg_enable &&\
echo "alternate kernel flashed">>$logfile &&\
touch $setting_c_flashed
# ----------------------------------------------------

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ -f $setting_c_flashed ] &&\
question -w 100 -h 200 "Select 'Ok' to restart netbook and apply setting-(C). Select 'Cancel' to restart manually" 2>&1 &&
[ $? -eq 0 ] &&\
sudo rm -vf $setting_c_flashed && reboot


# =============================================================================================

[ $kernel_resolution == '1280x720p' ] && [ -f $xorg ] && [ ! -f $setting_c_activated ] &&\
sudo rm -vf $setting_c_flashed>>$logfile &&\
sudo service lightdm restart &&\
sudo service lightdm stop &&\
sudo service lightdm start &&\
sudo touch $setting_c_activated &&\
exit 0

# ----------------------------------------------------

[ $kernel_resolution == '1280x720p' ] && [ -f $xorg ] && [ -f $setting_c_activated ] &&\
question -w 400 -h 300 "You are in setting-(C): Is HDMI still not working? Sorry, we couldn't do much at this moment. When done, select 'Ok' to switch to setting-(A) (default setting), system will reboot without confirming again. Select 'Cancel' to continue" 2>&1 &&\
[ $? -eq 0 ] &&\
sudo rm -v $xorg>>$logfile &&\
sudo mkbootimg --kernel $kernel_image_master --ramdisk $ramdisk_image -o /tmp/boot.img && sync &&\
sudo echo 0 > /sys/module/yaffs/parameters/yaffs_bg_enable &&\
sudo flash_erase $boot_part 0 0 &&\
sudo nandwrite -p $boot_part /tmp/boot.img &&\
sudo echo 1 > /sys/module/yaffs/parameters/yaffs_bg_enable &&\
sudo echo "master kernel flashed">>$logfile &&\
sudo rm -v $setting_c_activated && sync && reboot
}

sudo_access
probe_hdmi
