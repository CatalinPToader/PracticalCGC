sudo docker stop $(sudo docker ps -a -q)
sudo docker container prune -f