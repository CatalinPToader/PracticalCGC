read -p "Template to use (e.g ubuntu, alpine, debian, busybox, etc): " CONTAINER
read -p "Name to use: " NAME

lxc-create -n $NAME -t $CONTAINER
lxc-start -n $NAME -d