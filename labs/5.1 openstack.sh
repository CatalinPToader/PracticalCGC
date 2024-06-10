#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

download_and_source_rc_file() {
    echo "Please download your OpenStack RC file from the Horizon dashboard:"
    echo "1. Go to Project → API Access"
    echo "2. Click on 'Download OpenStack RC File'"
    echo "3. Save the file to your home directory"
    echo "4. Copy the file to fep.grid.pub.ro"
    RC_FILE=$(read_input "Enter the path to your OpenStack RC file on fep.grid.pub.ro" "~/openrc.sh")
    echo "Sourcing the OpenStack RC file..."
    source "$RC_FILE"
}

update_rc_for_token() {
    echo "Updating RC file for token-based authentication..."
    sed -i '/OS_PASSWORD_INPUT/d' "$RC_FILE"
    sed -i '/export OS_PASSWORD/d' "$RC_FILE"
    echo 'unset OS_TOKEN' >> "$RC_FILE"
    echo 'export OS_TOKEN=$(openstack token issue --os-auth-type=password -f value -c id)' >> "$RC_FILE"
    echo 'export OS_AUTH_TYPE="token"' >> "$RC_FILE"
    echo 'unset OS_USER_DOMAIN_NAME' >> "$RC_FILE"
    echo "RC file updated."
}

authenticate_and_list_services() {
    echo "Authenticating and listing OpenStack services..."
    source "$RC_FILE"
    openstack catalog list
}

list_resources() {
    echo "Listing OpenStack resources..."
    openstack image list
    openstack flavor list
    openstack keypair list
    openstack net list
    openstack security group list
}

show_resource_details() {
    RESOURCE_ID=$(read_input "Enter the resource ID to show details" "")
    RESOURCE_TYPE=$(read_input "Enter the resource type (image/flavor/keypair/net/security_group)" "image")

    case $RESOURCE_TYPE in
        image)
            openstack image show "$RESOURCE_ID"
            ;;
        flavor)
            openstack flavor show "$RESOURCE_ID"
            ;;
        keypair)
            openstack keypair show "$RESOURCE_ID"
            ;;
        net)
            openstack net show "$RESOURCE_ID"
            ;;
        security_group)
            openstack security group show "$RESOURCE_ID"
            ;;
        *)
            echo "Invalid resource type."
            ;;
    esac
}

boot_instance() {
    IMAGE_ID=$(read_input "Enter the image ID" "")
    FLAVOR_ID=$(read_input "Enter the flavor ID" "")
    KEYPAIR_NAME=$(read_input "Enter the keypair name" "")
    NETWORK_ID=$(read_input "Enter the network ID" "")
    SECURITY_GROUP=$(read_input "Enter the security group" "default")
    INSTANCE_NAME=$(read_input "Enter the instance name" "user.name-vm")

    echo "Booting an instance..."
    openstack server create --flavor "$FLAVOR_ID" --image "$IMAGE_ID" --nic net-id="$NETWORK_ID" --security-group "$SECURITY_GROUP" --key-name "$KEYPAIR_NAME" "$INSTANCE_NAME"
}

manage_instance_lifecycle() {
    INSTANCE_ID=$(read_input "Enter the instance ID" "")
    ACTION=$(read_input "Enter the action (start/stop/delete)" "stop")

    case $ACTION in
        start)
            openstack server start "$INSTANCE_ID"
            ;;
        stop)
            openstack server stop "$INSTANCE_ID"
            ;;
        delete)
            openstack server delete "$INSTANCE_ID"
            ;;
        *)
            echo "Invalid action."
            ;;
    esac
}

create_network_and_subnet() {
    NETWORK_NAME=$(read_input "Enter the network name" "user.name-network")
    SUBNET_NAME=$(read_input "Enter the subnet name" "user.name-subnet")
    SUBNET_RANGE=$(read_input "Enter the subnet range (e.g., 172.16.X.0/24)" "172.16.1.0/24")

    echo "Creating network $NETWORK_NAME..."
    openstack net create "$NETWORK_NAME"
    
    echo "Creating subnet $SUBNET_NAME..."
    openstack subnet create "$SUBNET_NAME" --network "$NETWORK_NAME" --subnet-range "$SUBNET_RANGE"
}

create_stack() {
    STACK_NAME=$(read_input "Enter the stack name" "user.name-stack")
    TEMPLATE_FILE=$(read_input "Enter the path to the Heat template file" "~/stack_template.yaml")

    echo "Creating stack $STACK_NAME..."
    openstack stack create -t "$TEMPLATE_FILE" "$STACK_NAME"
}

revoke_token() {
    echo "Revoking OpenStack token..."
    openstack token revoke "$OS_TOKEN"
}

download_and_source_rc_file

update_rc_for_token

authenticate_and_list_services

list_resources

# show_resource_details

# boot_instance

# manage_instance_lifecycle

# create_network_and_subnet

# create_stack

# Revoke OpenStack token
revoke_token