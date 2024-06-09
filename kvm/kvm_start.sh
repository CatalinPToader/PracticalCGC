read -p "Image to use (e.g: almalinux-8.qcow2): " IMG
read -p "RAM in MB for VM (e.g 512): " RAM
read -p "Number of VCPUs (e.g 2): " $CPU

sudo kvm -hda $IMG -m $RAM -smp $CPU