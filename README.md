# Rpi2_stretch_AP
Script to create an Access Point with internet for the Raspberrypi 2. 

I have created this script by copying parts from several sources to make the installation of an Access Point on the Raspberry Pi 2 in one step. The script was tested with a fresh install of Jessie Lite and Stretch.

The script uses Hostapd and dnsmasq and is made to automatically download the required apps and create the required config files. You must have the Raspberry pi connected to the internet with a cable not WIFI.

Installation. From the terminal window type:

sudo git clone https://github.com/granpino/Rpi2_stretch_AP.git

cd Rpi2_stretch_AP

sudo chmod 755 Rpi2_stretch_AP.sh

sudo ./rpi2_stretch_AP.sh

After the installation, reboot the Rpi. By using your Cell Phone connect to the wifi service RpiAP, enter the password raspberry. You should now have internet on your phone if everything went well.

The default ethernet IP address is 192.168.0.140 and the Wlan is 192.168.42.10, you can change these by editing the script. The wifi is named RpiAP and the password is raspberry.
