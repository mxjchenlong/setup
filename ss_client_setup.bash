#!/bin/bash

DEBIAN_FRONTEND=noninteractive
echo "deb http://mirror.bit.edu.cn/ubuntu/ trusty main restricted universe multiverse" > /etc/apt/sources.list
apt-get update
apt-get install  haproxy vim curl wget sed   -y --force-yes
wget http://192.168.168.110/Linux/shadowsocks-libev_2.4.0-1_amd64.deb -O shadowsocks-libev_2.4.0-1_amd64.deb && dpkg -i shadowsocks-libev_2.4.0-1_amd64.deb 


mkdir -p  /var/lib/haproxy
chown haproxy:haproxy /var/lib/haproxy


tee /etc/haproxy/haproxy.cfg 1> /dev/null <<HAPROXY
global
        maxconn 24096
        ulimit-n  51200
        chroot /var/lib/haproxy
        user haproxy
        group haproxy
        daemon
defaults
        log     global
        mode    http
        option  dontlognull
        option redispatch
        retries 3
        contimeout      5000
        clitimeout      50000
        srvtimeout      50000

listen stats :9090
        balance
        mode http
        stats enable

listen  mxj :8388
        mode tcp
        balance roundrobin
        server hk1.mydreamplus.com 45.120.158.39:8443 check weight 1
        server hk2.mydreamplus.com 45.120.158.80:8443 check weight 1
        server hk4.mydreamplus.com 45.120.158.147:8443 check weight 1
        
HAPROXY
wget http://192.168.168.110/mdp/autoinstall/ss.json -O /etc/shadowsocks-libev/config.json

sed -i "s,ss-server,ss-redir,g" /etc/init.d/shadowsocks-libev
sed -i "s,Port 22,Port 22\nPort 32200,g" /etc/ssh/sshd_config
tee /usr/local/bin/start.sh 1>/dev/null <<START
echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -t nat -A POSTROUTING  -j MASQUERADE


/sbin/iptables -t nat -A PREROUTING -p tcp -m multiport ! --dports 9090 32200  -j REDIRECT --to-ports 12345
/sbin/iptables -t nat -A PREROUTING -p udp -j REDIRECT --to-ports 12345


START

tee /etc/default/haproxy 1>/dev/null <<DFAULTPDNS
ENABLED=1
DFAULTPDNS


chmod +x /usr/local/bin/start.sh

sed -i 's,^exit,/usr/local/bin/start.sh\nexit,g' /etc/rc.local 



#setup worker user:
userdel bill
useradd bill -u 5001  -m -s /bin/bash
touch /etc/sudoers.d/bill
tee /etc/sudoers.d/bill 1>/dev/null <<SUDOFILE
bill ALL=(ALL) NOPASSWD:ALL
SUDOFILE
chmod 0440 /etc/sudoers.d/bill
chown -R  bill:bill /home/bill
mkdir -p touch /home/bill/.ssh/
touch /home/bill/.ssh/authorized_keys
touch /home/bill/.ssh/config
tee /home/bill/.ssh/authorized_keys 1>/dev/null <<AUTHPUBKEY
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCms4MdgAujbVFgq+nc8zjovCo3Ccy8x697D6T3Ximl0868k1hzIvp3DQe6FwssxE9qTkWv0y1x0YvpIudsVGky1IPQY4/LcDe61W9ZzUAs/piydvUwo4mKsSpqjYkCidaiE7JuP1Y64ay9Quvp+mmZIM0QVNA8tXOeCmZ1B5m1bkbQRqgKmT3T47jHPfpPUbDjXFNHc7JpRuJ/dU1gK16zqhOm1VapMEfT3nA69fIc84i2bem2cHqwsxqjjL2TsuqNAX7aj0sVdTvweZKq/5iYT5cZzGZidqU6RDCr1JeTbb1Gtd4mAjvzQpzrERgyujn54I9C6/sCavb9GdEuDfQ/ bill@Bills-MacBook-Pro.local
AUTHPUBKEY
chown -R bill:bill /home/bill/
chmod -R og-rw /home/bill/.ssh
