# Scripts for Practical Exam for CGC

Please organize into folders relating to what the scripts cover.

## Docker Containers
    ./create_bg.sh -- Creates a docker container in background (abusing sleep), spits out ID
    ./connect_container.sh -- Connects to specified ID using /bin/bash (oops for non-bash systems)
    ./bg_and_file.sh -- Creates a docker container in bg, with a volume mount inside a specified location (passing files host<->container)
    ./containers_network.sh -- Creates 2 containers in the same network (assumes debian, should be changed), allowing pings on container names
    ./kill_purge_containers.sh -- Kills all active containers and prunes them