#!/bin/bash
#
# Raspberry Pi2 "Jessie lite and stretch" Access Point using dnsmasq and hostapd
# 
# To run the file : sudo chmod 755 Rpi2_stretch_AP.sh
# Then: sudo ./Rpi2_stretch_AP.sh
#by: 
#

###################################################
#set default values
###################################################
# General
CURRENT_AUTHOR="User"

# Network Interface static eth0
IP4_ADDRESS=192.168.0.140
IP4_GATEWAY=192.168.0.1
IP4_NETMASK=255.255.255.0

# Wifi Access Point
AP_COUNTRY=US
AP_CHAN=6
AP_SSID=RpiAP
AP_PASSPHRASE=raspberry

clear
echo ""
###################################################
echo "            RaspberryPi 2 Access Point with internet"
echo "                    Raspbian Stretch Desktop"
echo "Performing a series of prechecks..."
echo "==================================="
###################################################


#check current user privileges
  (( `id -u` )) && echo "This script MUST be ran with root privileges, try prefixing with sudo. i.e sudo $0" && exit 1

#check that internet connection is available

((ping -w5 -c3 google.com || ping -w5 -c3 wikipedia.org) > /dev/null 2>&1) && echo "Internet connectivity - OK" || (echo "** Internet connection NOT FOUND, Internet connectivity is required for this script to complete.**" && exit 1)
echo ""
echo "Press Ctrl-C to exit"
read -p "Press [Enter] key to continue..."

#pre-checks complete#####################################################

#clear the screen
#clear

# Get Input from User
echo "Capture User Settings:"
echo "======================"
echo "Please answer the following questions."
echo "Hitting return will continue with the default option"
echo
echo
echo "This is the static ethernet address to connect to your network"
read -p "IPv4 Address [$IP4_ADDRESS]: " -e t1
if [ -n "$t1" ]; then IP4_ADDRESS="$t1";fi

read -p "IPv4 gateway [$IP4_GATEWAY]: " -e t1
if [ -n "$t1" ]; then IP4_GATEWAY="$t1";fi



# wifi settings
read -p "Wifi Country [$AP_COUNTRY]: " -e t1
if [ -n "$t1" ]; then AP_COUNTRY="$t1";fi

read -p "Wifi Channel Name [$AP_CHAN]: " -e t1
if [ -n "$t1" ]; then AP_CHAN="$t1";fi

read -p "Wifi SSID [$AP_SSID]: " -e t1
if [ -n "$t1" ]; then AP_SSID="$t1";fi

read -p "Wifi PassPhrase (min 8 max 63 characters) [$AP_PASSPHRASE]: " -e t1
if [ -n "$t1" ]; then AP_PASSPHRASE="$t1";fi

###################################################
# Get Decision from User
###################################################

  echo "#####################################################"
  echo 
  echo 
  echo

# Point of no return
  read -p "Do you wish to continue and Setup RPi as an Access Point? (y/n) " RESP
  if [ "$RESP" = "y" ]; then

  clear
  echo "Configuring RPI as an Access Point...."
  # update system =========
  echo ""
  echo "#####################PLEASE WAIT##################"######
  echo -en "Package list update                                "
  apt-get -qq update 
  echo -en "[OK]\n"

  echo -en "Adding hostapd and dnsmasq                         "
  apt-get -y -qq install hostapd dnsmasq > /dev/null 2>&1
  echo -en "[OK]\n"

# stop dnsmasq, hostapd ===============================
  echo -en "stop hostapd, dnsmasq                              "
  systemctl stop hostapd
  systemctl stop dnsmasq
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi


#create the hostapd configuration to match what the user has provided =========
  echo -en "Create hostapd.conf file                           "
  cat <<EOF > /etc/hostapd/hostapd.conf
#created by $0
interface=wlan0
driver=nl80211
ssid=$AP_SSID
hw_mode=g
channel=$AP_CHAN
wmm_enabled=0
wpa=2
wpa_passphrase=$AP_PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
auth_algs=1
ignore_broadcast_ssid=0
macaddr_acl=0
EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi

#create the hostapd default =========
  echo -en "Create hostapd default file                        "
  cat <<EOF > /etc/default/hostapd
#created by $0
DAEMON_CONF="/etc/hostapd/hostapd.conf"
#DAEMON_OPTS=""
EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi

#create the dhcpcd conf file=========
  echo -en "Create dhcpcd.conf file                            "
  cp /etc/dhcpcd.conf dhcpcd.bak
  cat <<EOF > /etc/dhcpcd.conf
#created by $0
hostname
clientid
persistent
option rapid_commit
# A list of options to request from the DHCP server.
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
# Most distributions have NTP support.
option ntp_servers
# A ServerID is required by RFC2131.
require dhcp_server_identifier
# Generate Stable Private IPv6 Addresses instead of hardware based ones
slaac private

nohook lookup-hostname

interface eth0
static ip_address=$IP4_ADDRESS
static routers=$IP4_GATEWAY
static domain_name_servers=$IP4_GATEWAY

nohook wpa_supplicant
interface wlan0
static ip_address=192.168.42.10/24
static routers=192.168.42.1
static domain_name_servers=8.8.8.8

EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi

#create sysctl.conf file ==============================
  echo -en "Create sysctl.conf file                            "
  cp /etc/sysctl.conf /etc/sysctl.conf.bak
  cat <<EOF > /etc/sysctl.conf
#created by $0s
#kernel.printk = 3 4 1 3
net.ipv4.ip_forward=1
#vm.swappiness=1
#vm.min_free_kbytes = 8192

EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi

#creat the default file to point at the configuration file =======
  echo -en "Create /etc/dnsmasq.conf file                      "
  cat <<EOF > /etc/dnsmasq.conf
#created by $0
interface=wlan0
bind-dynamic
domain-needed 
bogus-priv
dhcp-range=192.168.42.50,192.168.42.100,255.255.255.0,12h

EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi



# configure iptables-hs ==============
  echo -en "Create iptables-hs file                            "
  cat <<EOF > /etc/iptables-hs
#!/bin/bash
#created by $0
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT92

EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi

# iptables-hs executable ===============================
  echo -en "iptables-hs executable                             "
  chmod +x /etc/iptables-hs
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi


# configure service ==============
  echo -en "Create iptables-hs service                         "
  cat <<EOF > /etc/systemd/system/hs-iptables.service
#created by $0
[Unit]
Description=Activate IPtables for Hotspot
After=network-pre.target
Before=network-online.target

[Service]
Type=simple
ExecStart=/etc/iptables-hs

[Install]
WantedBy=multi-user.target

EOF
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi

# make executable at boot ==============
  echo -en "making sure it starts at boot                      "
  systemctl -qq enable hs-iptables
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo -en "[FAIL]\n"
    echo ""
    exit $rc
  else
    echo -en "[OK]\n"
  fi


  echo "###################INSTALL COMPLETE###############"######
  echo "The services will now be restarted to activate the changes"
  read -p "Press [Enter] key to restart services..."

  
# Restart the access point software
    echo -en "starting hostapd"
  service hostapd start
    echo ""
# Restart dnsmasq ===============================
    echo -en "starting dnsmasq"
    echo ""
  service dnsmasq start
    echo -en "now reboot your RPI"
####################################################################
else
echo "exiting..."
fi
echo ""
exit 0



