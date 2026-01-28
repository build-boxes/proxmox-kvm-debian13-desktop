#!/usr/bin/env bash
set -euo pipefail

###############################################
# CONFIGURATION (USER PARAMETERS)
###############################################
VMID="${1:-}"   # VMID passed as first argument

if [[ -z "$VMID" ]]; then
    echo "Usage: $0 <VMID>"
    exit 1
fi

PCI_HOST_ID="${2:-0}"   # Default to hostpci0 if not provided
VM_UPDATED=false

# Validate range 0–15
if ! [[ "$PCI_HOST_ID" =~ ^([0-9]|1[0-5])$ ]]; then
    echo "ERROR: PCI_HOST_ID must be between 0 and 15"
    exit 1
fi

MODPROBE_FILE="/etc/modprobe.d/vfio.conf"
QEMU_CONF="/etc/pve/qemu-server/${VMID}.conf"

###############################################
# Helper: Ensure file exists
###############################################
ensure_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        touch "$file"
    fi
}

###############################################
# Step 0: Enable IOMMU in GRUB for PCI passthrough
###############################################
configure_grub_iommu() {
    echo "Checking GRUB configuration for IOMMU..."

    GRUB_FILE="/etc/default/grub"

    if [[ ! -f "$GRUB_FILE" ]]; then
        echo "ERROR: $GRUB_FILE not found."
        exit 1
    fi

    # Detect CPU vendor
    if grep -qi "intel" /proc/cpuinfo; then
        IOMMU_FLAG="intel_iommu=on"
    else
        IOMMU_FLAG="amd_iommu=on"
    fi
    IOMMU_PT="iommu=pt"

    # Check if GRUB already contains the flags
    if grep -q "$IOMMU_FLAG" "$GRUB_FILE"; then
        echo "IOMMU already enabled in GRUB."
        return
    fi
    IOMMU_FLAG="$IOMMU_FLAG $IOMMU_PT"

    echo "IOMMU not found in GRUB. Updating..."

    # Insert flags into GRUB_CMDLINE_LINUX_DEFAULT
    sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/&$IOMMU_FLAG /" "$GRUB_FILE"

    echo "Updated GRUB with: $IOMMU_FLAG"

    # Apply changes
    update-grub
    VM_UPDATED=true
    echo "GRUB updated successfully."
}

###############################################
# Step 1: Detect PCI Audio Device
###############################################
detect_pci_audio() {
    echo "Detecting PCI audio device..."

    # Extract PCI address + vendor:device ID
    read PCI_ADDR PCI_ID <<< "$(lspci -nn | grep -i audio | awk '{gsub(/\[|\]/,""); print $1, $12 }')"

    if [[ -z "$PCI_ADDR" || -z "$PCI_ID" ]]; then
        echo "ERROR: No audio PCI device found via lspci."
        exit 1
    fi

    echo "Detected PCI Address: $PCI_ADDR"
    echo "Detected PCI ID:      $PCI_ID"
}

###############################################
# Step 2: Ensure vfio-pci binding exists
###############################################
configure_vfio() {
    echo "Configuring vfio-pci..."

    # Search all files in /etc/modprobe.d for the PCI ID
    if grep -Rqs "options vfio-pci ids=${PCI_ID}" /etc/modprobe.d/; then
        echo "vfio-pci already configured for PCI ID $PCI_ID in /etc/modprobe.d/"
        return
    fi

    # If not found, append to vfio.conf
    ensure_file "$MODPROBE_FILE"
    echo "options vfio-pci ids=$PCI_ID" >> "$MODPROBE_FILE"
    echo "Added vfio-pci binding for $PCI_ID to $MODPROBE_FILE"
    VM_UPDATED=true
}

###############################################
# Step 3: Add hostpci entry to VM config
###############################################
configure_vm_pci() {
    echo "Configuring VM $VMID PCI passthrough..."

    if [[ ! -f "$QEMU_CONF" ]]; then
        echo "ERROR: VM config $QEMU_CONF does not exist."
        exit 1
    fi

    HOSTPCI_KEY="hostpci${PCI_HOST_ID}"

    # Check if this specific hostpci slot already exists
    if grep -q "^${HOSTPCI_KEY}:" "$QEMU_CONF"; then
        echo "VM already has ${HOSTPCI_KEY} configured."
    else
        echo "${HOSTPCI_KEY}: ${PCI_ADDR},pcie=1" >> "$QEMU_CONF"
        echo "Added ${HOSTPCI_KEY} entry to VM config."
        VM_UPDATED=true
    fi
}

###############################################
# Step 4: Reboot VM if needed
###############################################
reboot_vm() {
    echo "Rebooting VM $VMID..."
    qm reboot "$VMID"
    sleep 20  # Wait for VM to reboot
    qm status "$VMID"
}

###############################################
# MAIN EXECUTION
###############################################
configure_grub_iommu
detect_pci_audio
configure_vfio
configure_vm_pci
if [[ "$VM_UPDATED" == true ]]; then
    reboot_vm
fi

echo "PCI passthrough setup complete."
