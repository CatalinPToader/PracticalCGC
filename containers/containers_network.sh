read -p "Name of container network (e.g test-net): " NETWORK
read -p "Image to run (e.g debian:latest, ubuntu:18.04): " CONTAINER
read -p "Name of first container: " C1
read -p "Name of second container: " C2

echo "
FROM $CONTAINER

RUN apt update
RUN apt install iputils-ping -y
" > network_dockerfile

sudo docker build -f network_dockerfile -t network-con .
NET=sudo docker network create $NETWORK
ID1=`sudo docker run -d --net $NETWORK --name $C1 network-con sleep 10000`
ID2=`sudo docker run -d --net $NETWORK --name $C2 network-con sleep 10000`

echo "ID1: $ID1"
echo "ID2: $ID2"