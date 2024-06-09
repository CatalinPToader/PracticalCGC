#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

install_ipvsadm() {
    echo "Installing ipvsadm on load balancer..."
    sudo apt update
    sudo apt install -y ipvsadm
}

configure_virtual_ip() {
    VIRTUAL_IP=$(read_input "Enter the virtual IP address" "192.168.100.251")
    INTERFACE=$(read_input "Enter the network interface" "eth0")
    echo "Configuring virtual IP $VIRTUAL_IP on $INTERFACE..."
    sudo ip addr add dev "$INTERFACE" "$VIRTUAL_IP/24" label "$INTERFACE:1"
}

configure_ipvs_dr() {
    VIRTUAL_IP=$(read_input "Enter the virtual IP address" "192.168.100.251")
    echo "Configuring IPVS in Direct Routing mode for $VIRTUAL_IP..."
    sudo ipvsadm -A -t "$VIRTUAL_IP:80"
    REAL_SERVER_1=$(read_input "Enter the IP address of real server 1" "192.168.100.72")
    REAL_SERVER_2=$(read_input "Enter the IP address of real server 2" "192.168.100.73")
    sudo ipvsadm -a -t "$VIRTUAL_IP:80" -r "$REAL_SERVER_1:80" -g
    sudo ipvsadm -a -t "$VIRTUAL_IP:80" -r "$REAL_SERVER_2:80" -g
}

configure_iptables_real_servers() {
    VIRTUAL_IP=$(read_input "Enter the virtual IP address" "192.168.100.251")
    echo "Configuring iptables rule on real servers..."
    ssh student@real-server-1 "sudo iptables -t nat -A PREROUTING -d $VIRTUAL_IP -j REDIRECT"
    ssh student@real-server-2 "sudo iptables -t nat -A PREROUTING -d $VIRTUAL_IP -j REDIRECT"
}

set_connection_threshold() {
    VIRTUAL_IP=$(read_input "Enter the virtual IP address" "192.168.100.251")
    CONNECTION_THRESHOLD=$(read_input "Enter the connection threshold" "3")
    echo "Setting connection threshold for real servers to $CONNECTION_THRESHOLD..."
    REAL_SERVER_1=$(read_input "Enter the IP address of real server 1" "192.168.100.72")
    REAL_SERVER_2=$(read_input "Enter the IP address of real server 2" "192.168.100.73")
    sudo ipvsadm -e -t "$VIRTUAL_IP:80" -r "$REAL_SERVER_1:80" -g -x "$CONNECTION_THRESHOLD"
    sudo ipvsadm -e -t "$VIRTUAL_IP:80" -r "$REAL_SERVER_2:80" -g -x "$CONNECTION_THRESHOLD"
}

cleanup_ipvs_iptables() {
    VIRTUAL_IP=$(read_input "Enter the virtual IP address" "192.168.100.251")
    echo "Cleaning up IPVS and iptables rules..."
    sudo ipvsadm -D -t "$VIRTUAL_IP:80"
    ssh student@real-server-1 "sudo iptables -t nat -F"
    ssh student@real-server-2 "sudo iptables -t nat -F"
}

# Configure IPVS in TUN mode
configure_ipvs_tun() {
    VIRTUAL_IP=$(read_input "Enter the virtual IP address" "192.168.100.251")
    echo "Configuring IPVS in TUN mode for $VIRTUAL_IP..."
    sudo ipvsadm -A -t "$VIRTUAL_IP:80"
    REAL_SERVER_1=$(read_input "Enter the IP address of real server 1" "192.168.100.72")
    REAL_SERVER_2=$(read_input "Enter the IP address of real server 2" "192.168.100.73")
    sudo ipvsadm -a -t "$VIRTUAL_IP:80" -r "$REAL_SERVER_1:80" -i
    sudo ipvsadm -a -t "$VIRTUAL_IP:80" -r "$REAL_SERVER_2:80" -i
}

configure_ipip_tunnel_real_servers() {
    echo "Configuring IP-IP tunnel on real servers..."
    ssh student@real-server-1 "sudo ip tunnel add tun0 mode ipip local 192.168.100.72; sudo ip address add 192.168.100.251/24 dev tun0 metric 32678; sudo ip link set tun0 up"
    ssh student@real-server-2 "sudo ip tunnel add tun0 mode ipip local 192.168.100.73; sudo ip address add 192.168.100.251/24 dev tun0 metric 32678; sudo ip link set tun0 up"
}

cleanup_ipip_tunnel() {
    echo "Cleaning up IP-IP tunnel on real servers..."
    ssh student@real-server-1 "sudo ip tunnel del tun0"
    ssh student@real-server-2 "sudo ip tunnel del tun0"
}

install_configure_haproxy() {
    echo "Installing and configuring HAProxy..."
    sudo apt update
    sudo apt install -y haproxy
    sudo systemctl enable --now haproxy

    cat <<EOF | sudo tee -a /etc/haproxy/haproxy.cfg
frontend www
        bind *:80
        default_backend realservers

backend realservers
        mode http
        balance roundrobin
        server realserver-1 192.168.100.72:80
        server realserver-2 192.168.100.73:80
EOF

    sudo systemctl restart haproxy
}

configure_haproxy_health_checks() {
    echo "Configuring HAProxy health checks..."
    sudo sed -i '/backend realservers/,+5d' /etc/haproxy/haproxy.cfg

    cat <<EOF | sudo tee -a /etc/haproxy/haproxy.cfg
backend realservers
        mode http
        balance roundrobin
        option httpchk
        http-check send meth GET
        server realserver-1 192.168.100.72:80 check inter 3000
        server realserver-2 192.168.100.73:80 check inter 3000
EOF

    sudo systemctl restart haproxy
}

echo "LVS-DR, LVS-TUN, and HAProxy Setup Script"

install_ipvsadm

configure_virtual_ip

configure_ipvs_dr

configure_iptables_real_servers

set_connection_threshold

cleanup_ipvs_iptables

configure_ipvs_tun

configure_ipip_tunnel_real_servers

cleanup_ipip_tunnel

install_configure_haproxy

configure_haproxy_health_checks