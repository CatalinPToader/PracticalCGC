#!/bin/bash

master_ip="$1"
slave_ip="$2"
domain="$3"

configure_master() {
    ssh student@$master_ip <<EOF
        sudo apt-get update
        sudo apt install -y host dnsutils bind9 bind9utils

        sudo tee /etc/bind/named.conf.local << EOL
zone "$domain" {
    type master;
    file "/etc/bind/db.$domain";
    allow-transfer { $slave_ip; };
    also-notify { $slave_ip; };
};
EOL

        sudo tee /etc/bind/db.$domain << EOL
\\$TTL    604800
@       IN      SOA     $domain. root.$domain. (
                            23         ; Serial
                        604800         ; Refresh
                         86400         ; Retry
                       2419200         ; Expire
                        604800 )       ; Negative Cache TTL
; NS - name servers
    IN     NS      ns1.$domain.
; MX - mail exchange
    IN     MX      10      mail.$domain.
; A - address record
mail    IN      A       $master_ip
*       IN      A       $master_ip
EOL
EOF
}

configure_slave() {
    ssh student@$slave_ip <<EOF
        apt-get update
        apt-get install -y host dnsutils bind9 bind9utils

        sudo tee /etc/bind/named.conf.local << EOL
zone "$domain" {
    type slave;
    file "/var/lib/bind/db.$domain";
    masters { $master_ip; };
};
EOL
        systemctl restart bind9
EOF
}

# Allow only requests from master and slave
restrict_access() {
    ssh student@$master_ip <<EOF
        sudo tee /etc/bind/named.conf.options << EOL
acl "trusted" {
    $master_ip;
    $slave_ip;
};

options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { trusted; };
    dnssec-validation no;
    listen-on { $master_ip; localhost; };
};
EOL
EOF
}

restart_dns() {
    ssh student@$master_ip <<EOF
        sudo systemctl restart bind9
EOF
    ssh student@$slave_ip <<EOF
        sudo systemctl restart bind9
EOF
}

configure_master
configure_slave
restrict_access
restart_dns
