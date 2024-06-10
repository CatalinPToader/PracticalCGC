read -p "Username: " USR
read -p "UID (e.g 1001): " UID
read -p "GID (e.g 1001): " GID
homedir=/home/$USR
echo "Home will be: $homedir"
read -p "Directory Manager (e.g cn=Directory Manager): " DM
read -p "Password: " PASS

read -p "Organizational unit name (e.g., ou=People): " OU_NAME
read -p "Base DN (e.g., dc=example,dc=com): " BASE_DN

# Create the LDIF file
LDIF_FILE="/tmp/add_user.ldif"

cat <<EOF > $LDIF_FILE
dn: uid=$USR,$OU_NAME,$BASE_DN
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
cn: $USR
sn: $USR
uid: $USR
uidNumber: $UID
gidNumber: $GID
homeDirectory: $homedir
loginShell: /bin/bash
EOF

# Add the user to the LDAP directory
ldapadd -x -D "$ROOT_DN" -w "$ROOT_PW" -f $LDIF_FILE

# Clean up
rm -f $LDIF_FILE

echo "User $USERNAME added successfully."