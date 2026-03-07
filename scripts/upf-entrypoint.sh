#!/bin/bash
set -e

# Create TUN device for UE data plane
ip tuntap add name ogstun mode tun || true
ip addr add 10.45.0.1/16 dev ogstun || true
ip addr add 2001:db8:cafe::1/48 dev ogstun || true
ip link set ogstun up

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# NAT for UE internet access
iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE

echo "UPF TUN device and NAT configured."

exec open5gs-upfd -c /open5gs/install/etc/open5gs/upf.yaml
