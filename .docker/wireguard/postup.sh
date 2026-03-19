#!/bin/sh

WIREGUARD_INTERFACE=wg0
WIREGUARD_LAN=10.0.0.0/24
DOCKER_LAN=172.18.0.0/16   # охватывает 172.18.0.0/24, 172.18.1.0/24, 172.18.2.0/24

# Разрешаем форвардинг в обе стороны через wg0
iptables -A FORWARD -i $WIREGUARD_INTERFACE -j ACCEPT
iptables -A FORWARD -o $WIREGUARD_INTERFACE -j ACCEPT

# NAT из WG в Docker (чтобы пакеты от 10.0.0.x к 172.18.x.x выглядели "как локальные")
iptables -t nat -A POSTROUTING -s $WIREGUARD_LAN -d $DOCKER_LAN -j MASQUERADE

# NAT из Docker в WG (если контейнеры сами обращаются к 10.0.0.x)
iptables -t nat -A POSTROUTING -s $DOCKER_LAN -o $WIREGUARD_INTERFACE -j MASQUERADE
