#!/bin/bash

echo "🔧 Setze iptables-Regeln und optimiere conntrack..."

# **Aktive Netzwerkschnittstelle automatisch ermitteln**
IFACE=$(ip route | grep default | awk '{print $5}')
if [[ -z "$IFACE" ]]; then
    echo "⚠️ Keine aktive Netzwerkschnittstelle gefunden. Bitte manuell prüfen!"
    exit 1
fi
echo "🌍 Gefundene Netzwerkschnittstelle: $IFACE"

# Standardrichtlinien setzen (sollte nur gemacht werden, wenn gewünscht)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Bestehende Regeln leeren
iptables -F
iptables -X

# Loopback-Schnittstelle zulassen
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Verbindungen erlauben, die zu einer bestehenden Verbindung gehören
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# **DNS erlauben** (damit `apt-get update` funktioniert)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p tcp --sport 53 -j ACCEPT

# **HTTP und HTTPS erlauben** (für `apt-get update` und Web-Anfragen)
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# **SSH-Zugang erlauben** (wichtig, falls du über SSH auf den Server zugreifst)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# **Traefik-Ports erlauben (nur falls nötig)**
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# **Docker-Netzwerkverkehr zulassen**
iptables -A INPUT -i docker0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o docker0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i docker0 -o $IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i $IFACE -o docker0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "🚀 Bereinige conntrack-Tabelle..."
conntrack -F
conntrack -D --state INVALID

echo "📌 Setze `conntrack`-Maximalwert auf 1.048.576..."
echo 1048576 > /proc/sys/net/netfilter/nf_conntrack_max
sysctl -w net.netfilter.nf_conntrack_max=1048576

# **Regeln dauerhaft speichern (falls iptables-persistent installiert ist)**
if command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables.rules
    echo "📌 iptables-Regeln gespeichert unter /etc/iptables.rules"
fi

echo "✅ iptables-Regeln erfolgreich gesetzt & conntrack optimiert!"