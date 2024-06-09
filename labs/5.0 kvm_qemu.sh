#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

install_kvm() {
    echo "Updating package list and installing qemu-kvm..."
    sudo apt update
    sudo apt install -y qemu-kvm qemu-utils
    echo "qemu-kvm installation complete."
}

load_kernel_modules() {
    echo "Loading kernel modules..."
    sudo modprobe kvm
    sudo modprobe kvm_intel
    ls -l /dev/kvm
    echo "Kernel modules loaded."
}

start_vm() {
    VM_RAM=$(read_input "Enter the amount of RAM for the VM (in MB)" "512")
    VM_CPUS=$(read_input "Enter the number of CPUs for the VM" "2")
    VM_DISK_IMAGE=$(read_input "Enter the path to the VM disk image" "debian-12.qcow2")

    echo "Starting a virtual machine with $VM_RAM MB RAM and $VM_CPUS CPUs using $VM_DISK_IMAGE"
    sudo kvm -hda "$VM_DISK_IMAGE" -m "$VM_RAM" -smp "$VM_CPUS"
}

start_vm_vnc() {
    VM_RAM=$(read_input "Enter the amount of RAM for the VM (in MB)" "512")
    VM_CPUS=$(read_input "Enter the number of CPUs for the VM" "2")
    VM_DISK_IMAGE=$(read_input "Enter the path to the VM disk image" "debian-12.qcow2")
    VNC_PORT=$(read_input "Enter the VNC port number" ":1")

    echo "Starting a virtual machine with VNC export on port $VNC_PORT"
    sudo kvm -m "$VM_RAM" -smp "$VM_CPUS" -hda "$VM_DISK_IMAGE" -vnc "$VNC_PORT" --daemonize
}

create_disk_image() {
    NEW_DISK_IMAGE=$(read_input "Enter the name for the new disk image" "virtualdisk.qcow")
    DISK_SIZE=$(read_input "Enter the size for the new disk image (e.g., 2G)" "2G")

    echo "Creating a new disk image $NEW_DISK_IMAGE with size $DISK_SIZE"
    qemu-img create -f qcow2 "$NEW_DISK_IMAGE" "$DISK_SIZE"
}

verify_iso_image() {
    ISO_IMAGE=$(read_input "Enter the path to the ISO image" "debian-11.3.0-amd64-netinst.iso")

    echo "Verifying ISO image integrity"
    sha512sum -c --ignore-missing SHA512SUMS
    gpg --keyserver keyring.debian.org --receive-keys 0x11CD9819
    gpg --verify SHA512SUMS.sign
}

start_vm_with_iso() {
    VM_RAM=$(read_input "Enter the amount of RAM for the VM (in MB)" "512")
    VM_CPUS=$(read_input "Enter the number of CPUs for the VM" "2")
    NEW_DISK_IMAGE=$(read_input "Enter the path to the new disk image" "virtualdisk.qcow")
    ISO_IMAGE=$(read_input "Enter the path to the ISO image" "debian-11.3.0-amd64-netinst.iso")

    echo "Starting a virtual machine with new disk image $NEW_DISK_IMAGE and ISO $ISO_IMAGE"
    sudo kvm -hda "$NEW_DISK_IMAGE" -smp "$VM_CPUS" -m "$VM_RAM" -cdrom "$ISO_IMAGE"
}

add_new_disk_image() {
    VM_DISK_IMAGE=$(read_input "Enter the path to the primary VM disk image" "debian-12.qcow2")
    NEW_DISK_IMAGE=$(read_input "Enter the name for the additional disk image" "newdisk.qcow")

    echo "Creating an additional 1GB disk image $NEW_DISK_IMAGE"
    qemu-img create -f qcow2 "$NEW_DISK_IMAGE" 1G
    sudo kvm -hda "$VM_DISK_IMAGE" -hdb "$NEW_DISK_IMAGE" -smp 2 -m 512
}

create_disk_images_from_base() {
    BASE_IMAGE=$(read_input "Enter the path to the base disk image" "debian-12.qcow2")
    VM1_DISK_IMAGE=$(read_input "Enter the name for the first VM disk image" "sda-vm1.qcow2")
    VM2_DISK_IMAGE=$(read_input "Enter the name for the second VM disk image" "sda-vm2.qcow2")

    echo "Creating new disk images based on $BASE_IMAGE"
    qemu-img create -f qcow2 -b "$BASE_IMAGE" "$VM1_DISK_IMAGE"
    qemu-img create -f qcow2 -b "$BASE_IMAGE" "$VM2_DISK_IMAGE"

    echo "Starting VMs with new disk images $VM1_DISK_IMAGE and $VM2_DISK_IMAGE"
    sudo kvm -hda "$VM1_DISK_IMAGE" -smp 2 -m 512
    sudo kvm -hda "$VM2_DISK_IMAGE" -smp 2 -m 512
}

convert_disk_format() {
    VM_DISK_IMAGE=$(read_input "Enter the path to the VM disk image to convert" "debian-12.qcow2")
    TARGET_FORMAT=$(read_input "Enter the target format (e.g., vdi, vmdk)" "vdi")
    CONVERTED_DISK_IMAGE="${VM_DISK_IMAGE%.qcow2}.$TARGET_FORMAT"

    echo "Converting $VM_DISK_IMAGE to $TARGET_FORMAT format"
    qemu-img convert -O "$TARGET_FORMAT" "$VM_DISK_IMAGE" "$CONVERTED_DISK_IMAGE"
    qemu-img info "$VM_DISK_IMAGE"
    qemu-img info "$CONVERTED_DISK_IMAGE"
}

install_kvm

load_kernel_modules

start_vm

start_vm_vnc

create_disk_image

verify_iso_image

start_vm_with_iso

add_new_disk_image

create_disk_images_from_base

convert_disk_format