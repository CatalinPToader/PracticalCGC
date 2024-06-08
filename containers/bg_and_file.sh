read -p "Image to run (e.g debian:latest, ubuntu:18.04): " CONTAINER
read -p "Folder to mount (e.g test): " FOLDER
read -p "Where to mount inside container (e.g /var/test): " MOUNT

ID=`sudo docker run -d -v ./$FOLDER:$MOUNT $CONTAINER sleep 10000`
echo "ID=$ID"