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
logfile=/var/log/hdmi.log
boot_part=/dev/mtd4
kernel_image_master=/opt/probe-hdmi/kernels/uzImage.bin.master.1280x720.1024x720
kernel_image_alternate=/opt/probe-hdmi/kernels/uzImage.bin.alternate.1024x600.1280x720
ramdisk_image=/opt/probe-hdmi/kernels/initrd.img
setting_c_flashed=/opt/probe-hdmi/setting_c_flashed
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
question -w 550 -h 150 "You are in Setting-(A) (default setting) [HDMI might work in setting-(A) with thick bottom bar]: Is it detected at all? If not, do you wish to try setting-(B)? The setting-(B) will make your bottom panel unvailable on netbook, but HDMI might work in full screen. Your desktop will be reloaded, save your files, if any. Select 'Ok' to try setting-(B), select 'Cancel' to continue Setting-(A). You may change from setting-(B) to setting-(A) anytime by revisiting this application" 2>&1 &&\
[ $? -eq 1 ] && exit 0

[ $kernel_resolution == '1024x720p' ] && [ ! -f $xorg ] && [ ! -f $xorg ] &&\
cp -v $fb1 $xorg>>$logfile &&\
service lightdm restart &&\
exit 0

#-=========================================================================================

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ ! -f $setting_c_flashed ] &&
question -w 350 -h 250 "You are in setting-(B): Do you wish to change to setting-(A)(default setting)? Select 'Ok' to switch to setting-(A). Select 'Cancel' to proceed further." 2>&1 &&\
[ $? -eq 0 ] &&\
rm -v $xorg>>$logfile &&\
service lightdm restart && exit 0

# ----------------------------------------------------

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ ! -f $setting_c_flashed ] &&\
question -w 450 -h 350 "You are in setting-(B): Is HDMI working now? If not, do you wish to change to setting-(C), HDMI might work in full screen with HD resolution(available only in setting-(C)), but netbook screen may go blank. Select 'Ok' to apply setting-(C) (will require 20 seconds, system will be restarted with one more confirmation dialog). Select 'Cancel' to retain setting-(B). Also, do remember, if HDMI doesn't work in setting-(C) do 'Ctrl+Alt+F1', login and restart this application by typing 'probehdmi' on console, and switch to default mode." 2>&1 &&\
[ $? -eq 1 ] && exit 0


# ----------------------------------------------------

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ ! -f $setting_c_flashed ] &&\
cp -v $fb1 $xorg>>$logfile &&\
mkbootimg --kernel $kernel_image_alternate --ramdisk $ramdisk_image -o /tmp/boot.img && sync &&\
echo 0 > /sys/module/yaffs/parameters/yaffs_bg_enable &&\
flash_erase $boot_part 0 0 &&\
nandwrite -p $boot_part /tmp/boot.img &&\
echo 1 > /sys/module/yaffs/parameters/yaffs_bg_enable &&\
echo "alternate kernel flashed">>$logfile
touch $setting_c_flashed
# ----------------------------------------------------

[ $kernel_resolution == '1024x720p' ] && [ -f $xorg ] && [ -f $setting_c_flashed ] &&\
question -w 100 -h 200 "Select 'Ok' to restart netbook and apply setting-(C). Select 'Cancel' to restart manually"
[ $? -eq 0 ] &&\
rm -vf $setting_c_flashed && reboot



# =============================================================================================

[ $kernel_resolution == '1280x720p' ] && rm -vf $setting_c_flashed>>$logfile && [ -f $xorg ] &&\
service lightdm restart &&\
service lightdm stop &&\
service lightdm start && exit 0

# ----------------------------------------------------

[ $kernel_resolution == '1280x720p' ] && [ -f $xorg ] &&\
}


#sudo_access
probe_hdmi
