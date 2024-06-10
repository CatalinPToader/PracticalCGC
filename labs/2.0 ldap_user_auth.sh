#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

HOSTNAME=$(read_input "Enter the system's hostname" "lab-ldap")
INSTANCE_NAME=$(read_input "Enter the instance name" "$HOSTNAME")
PORT=$(read_input "Enter port number" "389")
SECURE_PORT=$(read_input "Enter secure port number" "636")
DIR_MANAGER_PASSWORD=$(read_input "Enter the Directory Manager password" "password")
DB_SUFFIX=$(read_input "Enter the database suffix" "dc=lab-ldap,dc=scgc,dc=ro")
LDAP_IP=$(read_input "Enter the IP address of the LDAP server" "192.168.100.21")
LDAP_URI="ldap://$LDAP_IP"

cat <<EOL > dscreate.inf
[general]
full_machine_name = $HOSTNAME
start = True

[slapd]
instance_name = $INSTANCE_NAME
port = $PORT
secure_port = $SECURE_PORT
root_password = $DIR_MANAGER_PASSWORD
self_sign_cert = True

[backend-userroot]
create_suffix_entry = True
suffix = $DB_SUFFIX
EOL

sudo dscreate from-file dscreate.inf

sudo dsctl $INSTANCE_NAME status
sudo ss -lntp | egrep '389|636'

ldapsearch -x -b "$DB_SUFFIX"

sudo systemctl enable --now cockpit.socket

echo "To be executed on host to allow port forwarding:"
echo "ssh -4 -i ~/.ssh/id_openstack -J vlad.vasile1907@fep.grid.pub.ro,student@10.9.1.128 -fN -D 12345 student@$LDAP_IP"

echo "firefox -P &"
read -p "Press Enter to continue"

sudo dnf install -y nss-pam-ldapd sssd sssd-ldap oddjob-mkhomedir

sudo authselect select sssd --force

sudo bash -c "cat <<EOL > /etc/sssd/sssd.conf
[domain/default]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
ldap_uri = $LDAP_URI
ldap_search_base = $DB_SUFFIX
ldap_default_bind_dn = cn=Directory Manager
ldap_default_authtok_type = password
ldap_default_authtok = $DIR_MANAGER_PASSWORD
ldap_user_auth_type = userPassword
ldap_tls_reqcert = allow

[sssd]
services = nss, pam
domains = default

[nss]
homedir_substring = /home
EOL"

sudo chmod 600 /etc/sssd/sssd.conf

sudo systemctl restart sssd

sudo authselect enable-feature with-mkhomedir

sudo systemctl enable --now oddjobd.service