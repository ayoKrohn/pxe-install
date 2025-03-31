# PXE auto install Ubuntu Server (Jammy 22.04.5)

Complete PXE installation environment for automated Ubuntu (Jammy) installation using iPXE, preconfigured network settings, and cloud-init configuration.

DNS resolution is achieved by forwarding DNS traffic from the PXE interface to the internet-facing interface, 
allowing PXE clients to use external DNS servers like 8.8.8.8. 

> **Note:** All configuration files (e.g. in `dnsmasq.conf`, `netplan/00-installer-config.yaml`, and `user-data`) are provided as examples.
> **You must customize them to suit your own system's network setup and security requirements.**

This setup has been tested on host machines running Ubuntu Desktop 22.04 and Ubuntu Server 24.04.

---

## 📁 Project Structure

- `install.sh`  
  → Main setup script that installs and configures PXE services.

- `etc/`  
  → Configuration files:
  - `dnsmasq.conf`: PXE DHCP/TFTP server settings    
  - `netplan/00-installer-config.yaml`: Static network configuration

- `pxeboot/`  
  → iPXE bootloader files:
  - `config/boot.ipxe`: iPXE boot script  
  - `firmware/`: Folder for compiled iPXE binaries (ignored in Git - see description below on how to compile the binaries.)

- `www/html/jammy/`  
  → Root folder served by your web server (e.g. `/var/www/html/jammy`):
  - `boot/`: Place Ubuntu kernel (`vmlinuz`) and initrd here manually (see How To below) 
  - `iso/`: Place the Ubuntu ISO file here manually  
  - `autoinstall/`: Contains cloud-init files for automated install:
    - `user-data`
    - `meta-data`

---

## ✅ Requirements

- Ubuntu system (22.04 or 24.04) with:
  - Network access to the internet
  - A dedicated Ethernet interface for PXE (e.g. USB-Ethernet)
- `dnsmasq` and `iptables-persistent` (installed by `install.sh`)
- Apache or another web server serving `/var/www/html`(`apache` is installed by `install.sh`)

---

## ⚙️ Installation

1. **Clone this repository**:
   ```bash
   git clone https://github.com/ayoKrohn/pxe-install
   cd pxe-install

2. **Replace network interfaces with your systems network interfaces in the following files**:
   - install.sh
   - etc/dnsmasq.conf
   - etc/netplan/00-installer-config.yaml
  
3. **Run the installer script as root**:
   ```bash
    sudo ./install.sh      

## 💾 Ubuntu ISO & Boot Files (vmlinuz + initrd)

1. **Download Ubuntu 22.04.5 server ISO**
   ```bash
    wget -O ubuntu-22.04.5-live-server-amd64.iso https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
   
3. **Move the ISO file to /var/www/html/jammy/iso/**:
   ```bash
   sudo mv ubuntu-22.04.5-live-server-amd64.iso /var/www/html/jammy/iso
   
4. **Mount the ISO and extract boot files**:
  ```bash
    mkdir /mnt/iso
    sudo mount /var/www/html/jammy/iso/ubuntu-22.04-live-server-amd64.iso /mnt/iso
    cp /mnt/iso/casper/vmlinuz /var/www/html/jammy/boot/
    cp /mnt/iso/casper/initrd /var/www/html/jammy/boot/
    sudo umount /mnt/iso
```

## ⚠️ iPXE Firmware not included

Precompiled iPXE firmware binaries are not included in this repository.

You must build them manually:
```bash
git clone https://github.com/ipxe/ipxe.git
cd ipxe/src
make bin/ipxe.efi bin/undionly.kpxe
cp bin/ipxe.efi bin/undionly.kpxe /pxeboot/firmware/


