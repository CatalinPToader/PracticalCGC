read -p "Image to use (e.g: almalinux-8.qcow2): " IMG
read -p "RAM in MB for VM (e.g 512): " RAM
read -p "Number of VCPUs (e.g 2): " $CPU
read -p "VNC port (e.g 1): " $VNC

sudo kvm -hda $IMG -m $RAM -smp $CPU -vnc :$VNC --daemonize
echo "Connect to vnc using localhost:1 or 127.0.0.1:1"