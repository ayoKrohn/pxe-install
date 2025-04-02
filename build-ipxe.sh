#!/bin/bash

set -e

# ADJUST to your system
TFTP_SERVER_IP="192.168.0.150"

SRC_DIR="/usr/local/src/ipxe"
PXE_FW_DIR="/pxeboot/firmware"
CHAIN_FILE="/tmp/chainload.ipxe"

# Avoid infinite loop by embedding a script that points iPXE to boot.ipxe
echo "[*] Creating embedded iPXE script ($CHAIN_FILE)..."
cat > "$CHAIN_FILE" <<EOF
#!ipxe

dhcp
chain tftp://$TFTP_SERVER_IP/config/boot.ipxe
EOF

# Clone iPXE repo if it does not exist
if [ ! -d "$SRC_DIR" ]; then
    echo "[*] Cloning iPXE source to $SRC_DIR..."
    git clone https://github.com/ipxe/ipxe.git /tmp/ipxe
    sudo mv /tmp/ipxe "$SRC_DIR"
fi

cd "$SRC_DIR/src"

# Build with embedded script
echo "[*] Building undionly.kpxe (BIOS) with embedded chainload.ipxe..."
make -j$(nproc) bin/undionly.kpxe EMBED="$CHAIN_FILE"

echo "[*] Building ipxe.efi (UEFI) with embedded chainload.ipxe..."
make -j$(nproc) bin-x86_64-efi/ipxe.efi EMBED="$CHAIN_FILE"

# Copy FW to PXE firmware dir
echo "[*] Copying binaries to $PXE_FW_DIR"
sudo mkdir "$PXE_FW_DIR"
sudo cp -v bin/undionly.kpxe "$PXE_FW_DIR/"
sudo cp -v bin-x86_64-efi/ipxe.efi "$PXE_FW_DIR/"

echo "[✓] iPXE build complete."
