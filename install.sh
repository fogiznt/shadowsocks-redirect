#!/bin/bash

cd ~
echo "Введите ip первого сервера"
read ip_1
echo $ip_1

echo "Введите ip второго сервера"
read ip_2
echo $ip_2

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

iptables -t nat -I PREROUTING -p tcp -d $ip_1 --dport 8388 -j DNAT --to-destination $ip_2
iptables -t nat -I POSTROUTING -p tcp -d $ip_2 -j MASQUERADE
password=$(openssl rand -base64 12)

cat >>server2.sh <<EOF
apt update && apt install shadowsocks-libev -y
cat >/etc/shadowsocks-libev/config.json <<FOE
{
    "server":["::1", "0.0.0.0"],
    "mode":"tcp_and_udp",
    "server_port":8388,
    "local_port":1080,
    "password":"$password",
    "timeout":86400,
    "method":"chacha20-ietf-poly1305"
}
FOE
systemctl restart shadowsocks-libev.service
systemctl enable shadowsocks-libev.service
EOF

echo "Введите пароль от второго сервера"
scp /root/server2.sh root@$ip_2:/root/
echo "Снова введите пароль от второго сервера"
ssh root@$ip_2 "chmod +x /root/server2.sh && /root/server2.sh"

echo -e "Доступ к shadowsocks:\nip - $ip_1\nport - 8388\ncipher - chacha20-ietf-poly1305\npassword - $password"
