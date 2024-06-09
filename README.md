# Scripts for Practical Exam for CGC

Please organize into folders relating to what the scripts cover.

## Docker Containers
    ./create_bg.sh -- Creates a docker container in background (abusing sleep), spits out ID
    ./connect_container.sh -- Connects to specified ID using /bin/bash (oops for non-bash systems)
    ./bg_and_file.sh -- Creates a docker container in bg, with a volume mount inside a specified location (passing files host<->container)
    ./containers_network.sh -- Creates 2 containers in the same network (assumes debian, should be changed), allowing pings on container names
    ./network_compose.sh -- Uses the docker-compose.yaml to create 2 containers in the same network (assumes debian again), doesn't install ping on them
    ./kill_purge_containers.sh -- Kills all active containers and prunes them

## LXC Containers
    ./create_bg.sh -- Creates a lxc container in the background (using daemon)
    ./connect_container.sh -- !Attaches! to a container to bypass login requirements.