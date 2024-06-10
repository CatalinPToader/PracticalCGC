#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

DOMAIN=$(read_input "Enter your domain" "<your_last_name>.scgc.ro")
DNS_IP=$(read_input "Enter the IP address of your DNS server" "192.168.100.11")
HELPER_IP=$(read_input "Enter the IP address of your helper server" "192.168.100.12")

apt update
apt install -y bind9 bind9utils

cat <<EOF > /etc/bind/named.conf.options
acl goodguys { ${DNS_IP}; 127.0.0.1; ::1; };

options {
    directory "/var/cache/bind";

    // Disable DNSSEC validation
    dnssec-validation no;

    // Allow recursion only for goodguys
    allow-recursion { goodguys; };
    recursion yes;

    // Listen on specific IP addresses
    listen-on { ${DNS_IP}; localhost; };

    // Other options can go here
};
EOF

cat <<EOF > /etc/bind/named.conf.local
zone "${DOMAIN}" {
    type master;
    file "/etc/bind/db.${DOMAIN}";
};
EOF

cp /etc/bind/db.local /etc/bind/db.${DOMAIN}

cat <<EOF > /etc/bind/db.${DOMAIN}
\$TTL    604800
@       IN      SOA     ${DOMAIN}. root.${DOMAIN}. (
                          3         ; Serial
                     604800         ; Refresh
                      86400         ; Retry
                    2419200         ; Expire
                     604800 )       ; Negative Cache TTL

; Name servers - NS records
        IN      NS      ns1.${DOMAIN}.
        IN      NS      ns2.${DOMAIN}.

; Name servers - A records
ns1.${DOMAIN}.       IN      A       ${DNS_IP}
ns2.${DOMAIN}.       IN      A       ${HELPER_IP}

; Web server - A records
www.${DOMAIN}.      IN      A       ${DNS_IP}

; Mail servers - MX records
        IN      MX 10   mail1.${DOMAIN}.
        IN      MX 20   mail2.${DOMAIN}.

; Mail server - A records
mail1.${DOMAIN}.    IN      A       ${DNS_IP}
mail2.${DOMAIN}.    IN      A       ${HELPER_IP}
EOF

named-checkconf

named-checkzone ${DOMAIN} /etc/bind/db.${DOMAIN}

service bind9 restart

echo "Testing DNS server..."

host www.${DOMAIN} localhost
host -t ns ${DOMAIN} localhost
host ns1.${DOMAIN} localhost

echo "Testing recursive queries..."
host google.com localhost

# Allow recursive queries from the helper VM
sed -i "s/acl goodguys { .*/acl goodguys { ${DNS_IP}; ${HELPER_IP}; 127.0.0.1; ::1; };/" /etc/bind/named.conf.options

service bind9 restart

echo "Testing updated recursive queries..."
echo "From helper server, run the following command to test:"
echo "host google.com ${DNS_IP}"