# PXE auto install Ubuntu Server (Jammy 22.04.5)

Complete PXE installation environment for automated Ubuntu (Jammy) installation using iPXE, preconfigured network settings, and cloud-init configuration.

DNS resolution is achieved by forwarding DNS traffic from the PXE interface to the internet-facing interface, 
allowing PXE clients to use external DNS servers like 8.8.8.8. 

> **Note:** All configuration files (e.g. in `dnsmasq.conf`, `netplan/00-installer-config.yaml`, and `user-data`) are provided as examples of a tested functional system.
> **You must customize them to suit your own system's network setup and security requirements.**

This setup has been tested on host machines running Ubuntu Desktop 22.04 and Ubuntu Server 24.04.

---

## 📁 Project Structure

- `install.sh`  
   Main setup script that installs and configures PXE services.

- `build-ipxe.sh` 
   Downloads and compiles iPXE firmware with an embedded script pointing to the TFTP-server, and places firmware binaries in `/pxeboot/firmware`.

- `etc/`  
   Configuration files:
  - `dnsmasq.conf`: PXE DHCP/TFTP server settings
  - `netplan/00-installer-config.yaml`: Static network configuration

- `pxeboot/`  
   iPXE bootloader files:
  - `config/boot.ipxe`: iPXE boot script
  - `firmware/`: Directory for compiled iPXE binaries. This folder is not tracked by   Git and is created automatically by `build-ipxe.sh`.


- `www/html/jammy/`  
   Root folder served by your web server (e.g. `/var/www/html/jammy`):
  - `boot/`: Place Ubuntu kernel (`vmlinuz`) and initrd here manually (see How To below) 
  - `iso/`: Place the Ubuntu ISO file here manually
  - `autoinstall/`: Contains cloud-init files for automated install:
    - `user-data` (Adjust to your own client settings)
    - `meta-data` (Leave it empty)

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
   ```

3. **Adjust network interfaces and IP-addresses in the following files**:
   - install.sh
   - etc/netplan/00-installer-config.yaml
   - etc/dnsmasq.conf
   - pxeboot/config/boot.ipxe
   - build-ipxe.sh

4. **Run the installer script as root**:

   ```bash
    sudo ./install.sh
   ```
 
## 💾 Ubuntu ISO & Boot Files (vmlinuz + initrd)

1. **Download Ubuntu 22.04.5 server ISO**

   ```bash
    wget -O ubuntu-22.04.5-live-server-amd64.iso https://releases.ubuntu.com/22.04/      ubuntu-22.04.5-live-server-amd64.iso
   ```
   
3. **Move the ISO file to /var/www/html/jammy/iso/**:

   ```bash
   sudo mv ubuntu-22.04.5-live-server-amd64.iso /var/www/html/jammy/iso
   ```

4. **Mount the ISO and extract boot files**:
  
  ```bash
    sudo mkdir /mnt/iso
    sudo mount /var/www/html/jammy/iso/ubuntu-22.04.5-live-server-amd64.iso /mnt/iso
    sudo cp /mnt/iso/casper/vmlinuz /var/www/html/jammy/boot/
    sudo cp /mnt/iso/casper/initrd /var/www/html/jammy/boot/
    sudo umount /mnt/iso
```

## ⚠️ iPXE Firmware not included

Precompiled iPXE firmware binaries are not included in this repository.
`build-ipxe.sh` will download ipxe source code and compile firmware for UEFI and Legacy boot for you: 

```bash
./build-ipxe.sh
```

## 🚀 PXE Boot Without Autoinstall (Manual Install)

Once you've built the iPXE firmware and configured your PXE environment, you should now be able to boot a client machine into the Ubuntu installer without autoinstall. This is useful for testing your PXE setup before enabling full automation.

📌 Tip:
Make sure to configure the client machine’s BIOS or UEFI firmware to enable PXE boot over the correct network interface (often called "Network Boot", "PXE Boot", or "LAN Boot" in BIOS settings).

The client should receive an IP address via DHCP, load ipxe.efi or undionly.kpxe from the TFTP server, and chain into the Ubuntu installer via HTTP.

## 📝 Adjust user-data file for a fully automated PXE installation

The user-data file contains the cloud-init autoinstall configuration used by Ubuntu during PXE-based installations. It defines everything from disk layout and locale to user accounts and installed packages.

You must customize this file to match your client machine’s hardware, especially the storage: section (disk device, partition sizes, offsets).

📌 Tip: To easily extract the correct values:
1. PXE boot the client into the Ubuntu installer and complete the installation manually.
2. After rebooting into the installed system, inspect disk info using:

```bash
sudo parted /dev/{your-disk-name} unit B print
```

You may also find the original autoinstall config stored under:

`/var/lib/cloud/instances/`

Once updated, copy your user-data file back to the correct web server directory:

```bash
sudo cp www/html/jammy/autoinstall/user-data /var/www/html/jammy/autoinstall/
```

## 🛠️🐧 Tips for Debugging

Here are a few suggestions if your PXE boot or autoinstall doesn't behave as expected:

🔍 **Monitor TFTP activity**

```bash
tail -f /var/log/dnsmasq/tftp.log
```

📄 **Validate your user-data**

- Make sure user-data is valid YAML — use a linter like yamllint.

- Avoid tabs; use spaces only.

- Ensure all id: fields match across partition, format, and mount.

🧪 **Boot issues?**

If the client boots into the Ubuntu installer GUI instead of starting the autoinstall, there's likely a syntax error in user-data or boot.ipxe.

- Double-check that your initrd is passed the autoinstall ds=nocloud parameters in boot.ipxe.

- Ensure that /var/www/html/jammy/autoinstall/meta-data exists (even if empty).
