read -p "Image to use as base (e.g: almalinux-8.qcow2): " BASE
read -p "Name for new image (e.g: new.qcow2): " NAME

qemu-img create -f qcow2 -b $BASE $NAME