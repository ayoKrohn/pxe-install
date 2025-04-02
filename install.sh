#!/bin/bash -x
set -e

# ADJUST these to match your system
PXE_IFACE="enx28ee5202221b"
INTERNET_IFACE="enxb656e393a249"

echo "Installing required packages..."
apt update
apt install -y apache2 iptables-persistent dnsmasq

echo "Applying PXE netplan config..."
cp etc/netplan/00-installer-config.yaml /etc/netplan/
# Fix permissions so that netplan config is not too open
chmod 600 /etc/netplan/00-installer-config.yaml
chmod 600 /etc/netplan/01-network-manager-all.yaml
netplan apply

echo "Setting up iptables rules..."
# Check if each rule already exists before adding it
if ! iptables -C FORWARD -i $PXE_IFACE -o $INTERNET_IFACE -j ACCEPT 2>/dev/null; then
    iptables -A FORWARD -i $PXE_IFACE -o $INTERNET_IFACE -j ACCEPT
fi

if ! iptables -C FORWARD -i $INTERNET_IFACE -o $PXE_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null; then
    iptables -A FORWARD -i $INTERNET_IFACE -o $PXE_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
fi

if ! iptables -t nat -C POSTROUTING -o $INTERNET_IFACE -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o $INTERNET_IFACE -j MASQUERADE
fi

iptables-save > /etc/iptables/rules.v4

echo "Enabling IP forwarding..."
SYSCTL_FILE="/etc/sysctl.d/99-pxe.conf"
# Only add the setting if it is not already present
if [ ! -f "$SYSCTL_FILE" ] || ! grep -q "^net.ipv4.ip_forward=1" "$SYSCTL_FILE"; then
    echo "net.ipv4.ip_forward=1" > "$SYSCTL_FILE"
fi
sysctl -p "$SYSCTL_FILE"

echo "Configuring dnsmasq..."
# Backup existing dnsmasq configuration if it exists
if [ -f /etc/dnsmasq.conf ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi
cp etc/dnsmasq.conf /etc/dnsmasq.conf
# Create dir for dnsmasq's DHCP and TFTP logs
mkdir -p /var/log/dnsmasq
chown dnsmasq:adm /var/log/dnsmasq/

# Prompt user before overwriting /var/www/html/jammy
if [ -d "/var/www/html/jammy" ]; then
    read -p "/var/www/html/jammy already exists. Do you want to overwrite it? (y/n): " answer
    if [ "$answer" != "y" ]; then
        echo "Aborting installation."
        exit 1
    else
        rm -rf /var/www/html/jammy
    fi
fi

echo "Preparing TFTP and PXE boot files..."
mkdir -p /var/www/html/jammy/{boot,iso,autoinstall}

# Prompt user before overwriting /pxeboot
if [ -d "/pxeboot" ]; then
    read -p "/pxeboot already exists. Do you want to overwrite it? (y/n): " answer2
    if [ "$answer2" != "y" ]; then
        echo "Aborting installation."
        exit 1
    else
        rm -rf /pxeboot
    fi
fi

cp -r pxeboot/ /pxeboot/
cp -r www/html/jammy/autoinstall/meta-data /var/www/html/jammy/autoinstall/

echo "Restarting dnsmasq..."
systemctl restart dnsmasq

echo "Installation complete."
