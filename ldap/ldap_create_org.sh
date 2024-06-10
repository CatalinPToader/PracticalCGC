#!/bin/bash

# Prompt for user input
read -p "Enter the organizational unit (OU) name (e.g., People): " OU_NAME
read -p "Enter the LDAP base DN (e.g., dc=example,dc=com): " BASE_DN

# Prompt for the LDAP root DN and password
read -p "Enter the LDAP root DN (e.g., cn=Directory Manager): " ROOT_DN
read -p "Enter the LDAP root password: " ROOT_PW

# Create the LDIF file
LDIF_FILE="/tmp/add_ou.ldif"

cat <<EOF > $LDIF_FILE
dn: ou=$OU_NAME,$BASE_DN
objectClass: top
objectClass: organizationalUnit
ou: $OU_NAME
EOF

# Add the organizational unit to the LDAP directory
ldapadd -x -D "$ROOT_DN" -w "$ROOT_PW" -f $LDIF_FILE

# Clean up
rm -f $LDIF_FILE

echo "Organizational unit $OU_NAME added successfully."