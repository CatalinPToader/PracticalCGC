#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

CONTAINER_NAME=$(read_input "Enter the LXC container name" "ct2")
TEMPLATE=$(read_input "Enter the template to use for creating the container" "ubuntu")

apt update
apt install -y lxc lxc-templates

echo "Creating LXC container named ${CONTAINER_NAME} with template ${TEMPLATE}..."
lxc-create -n "${CONTAINER_NAME}" -t "${TEMPLATE}"

echo "Listing LXC containers..."
lxc-ls

echo "Starting ${CONTAINER_NAME} in background..."
lxc-start -n "${CONTAINER_NAME}" -d

echo "Verifying the container state..."
lxc-info -n "${CONTAINER_NAME}"

echo "Connecting to the container's console using"
echo "lxc-console -n \"${CONTAINER_NAME}\""

apt install -y psmisc

CONTAINER_PID=$(lxc-info -n "${CONTAINER_NAME}" | grep "PID:" | awk '{print $2}')

echo "Displaying the process hierarchy starting with the container's PID ${CONTAINER_PID}..."
pstree --ascii -s -c -p "${CONTAINER_PID}"

echo "Attaching to ${CONTAINER_NAME} and displaying its processes..."
lxc-attach -n "${CONTAINER_NAME}" -- ps -ef

echo "Creating a file within the container's /root directory..."
lxc-attach -n "${CONTAINER_NAME}" -- bash -c "echo 'Hello from within the container' > /root/container-file.txt"

echo "Accessing and editing the file from the host..."
echo "Modified from the host" >> "/var/lib/lxc/${CONTAINER_NAME}/rootfs/root/container-file.txt"

echo "Verifying that the changes are also visible from the container..."
lxc-attach -n "${CONTAINER_NAME}" -- cat /root/container-file.txt

echo "Starting an Ubuntu container named ${CONTAINER_NAME}..."
lxc-create -n "${CONTAINER_NAME}" -t ubuntu

echo "Connecting to ${CONTAINER_NAME} container. Username: ubuntu, Password: ubuntu..."
lxc-start -n "${CONTAINER_NAME}" -d
lxc-console -n "${CONTAINER_NAME}"

echo "Script execution completed."