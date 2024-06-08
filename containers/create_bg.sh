read -p "Image to run (e.g debian:latest, ubuntu:18.04): " CONTAINER

ID=`sudo docker run -d $CONTAINER sleep 10000`
echo "ID=$ID"