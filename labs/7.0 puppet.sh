#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

apply_manifest() {
    local manifest_file="$1"
    echo "Applying manifest: $manifest_file"
    puppet apply "$manifest_file"
}

echo "Select a manifest to apply:"
echo "1. File Symbolic Link (file_sym.pp)"
echo "2. Nginx Service (nginx_service.pp)"
echo "3. Nginx Service with Conditionals (nginx_service_cond.pp)"
echo "4. SSH Authorized Key (ssh_auth.pp)"
echo "5. SSH Service (ssh_service.pp)"
read -p "Enter the number of the manifest to apply: " choice

case $choice in
    1)
        apply_manifest "/mnt/data/file_sym.pp"
        ;;
    2)
        apply_manifest "/mnt/data/nginx_service.pp"
        ;;
    3)
        apply_manifest "/mnt/data/nginx_service_cond.pp"
        ;;
    4)
        echo "Please run the following commands on another machine to generate an SSH key and obtain the public key:"
        echo "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N \"\""
        echo "cat ~/.ssh/id_ed25519.pub"

        read -p "Please enter the SSH public key: " PUB_KEY

        sed -i "s|REPLACE_WITH_PUBLIC_KEY|$PUB_KEY|" /mnt/data/ssh_auth.pp

        apply_manifest "/mnt/data/ssh_auth.pp"
        ;;
    5)
        apply_manifest "/mnt/data/ssh_service.pp"
        ;;
    *)
        echo "Invalid choice. Please run the script again and select a valid option."
        ;;
esac