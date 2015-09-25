#!/bin/bash

DEBIAN_FRONTEND=noninteractive
distro=$(uname -a|grep arm)
if [ "" == "$distro" ]; then
	echo "23.235.39.133 shadowsocks.org" >> /etc/hosts
	echo "deb https://shadowsocks.org/debian wheezy main" > /etc/apt/sources.list.d/ss.list
	echo "deb http://mirror.bit.edu.cn/ubuntu/ trusty main restricted universe multiverse" > /etc/apt/sources.list
else
	mkdir -p /etc/apt/sources.list.d/bk
	mv /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/bk
	echo "deb http://mirrors.ustc.edu.cn/raspbian/raspbian wheezy main contrib non-free rpi" > /etc/apt/sources.list
fi

#debconf-show pdnsd
echo "set pdnsd/conf Manual" | debconf-communicate

apt-get update
apt-get install dnsmasq haproxy vim curl wget sed openvpn pdnsd ipset -y --force-yes

if [ "" == "$distro" ]; then
	sudo apt-get install  -y --force-yes shadowsocks-libev
else
	wget http://192.168.168.240/software/linux/raspbian/dnsmasq -O /usr/sbin/dnsmasq
	wget http://192.168.168.240/software/linux/raspbian/shadowsocks-libev_2.2.3-1_armhf.deb -O /tmp/shadowsocks.deb
	dpkg -i /tmp/shadowsocks.deb
	rm -f /tmp/*.deb
fi

mkdir -p /etc/dnsmasq.d/
#wget http://192.168.168.240/software/linux/raspbian/dnsmasq_list.conf -O /etc/dnsmasq.d/dnsmasq_list.conf

mkdir -p  /var/lib/haproxy
chown haproxy:haproxy /var/lib/haproxy

tee /etc/dnsmasq.conf 1>/dev/null <<DNSMASQ
port=53
#interface=eth0
no-dhcp-interface=eth0
no-hosts
#no-resolv
log-queries
conf-dir=/etc/dnsmasq.d
server=123.59.58.107
server=114.114.114.114
server=219.239.26.42

DNSMASQ

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
        balance leastconn
        server 45.63.124.23 45.63.124.23:8443 check weight 1
        server 45.63.122.145 45.63.122.145:443 check weight 1
        server 108.61.126.222 108.61.126.222:8443 check weight 1
HAPROXY
tee /etc/shadowsocks-libev/config.json 1> /dev/null<<SS
{
    "server":"127.0.0.1",
    "server_port":8388,
    "local_port":12345,
    "local_address":"0.0.0.0",
    "password":"r1adev",
    "timeout":50,
    "method":"aes-256-cfb"
}
SS
tee /etc/shadowsocks-libev/config_prox.json 1> /dev/null<<SS
{
    "server":"127.0.0.1",
    "server_port":8388,
    "local_port":12346,
    "local_address":"0.0.0.0",
    "password":"r1adev",
    "timeout":50,
    "method":"aes-256-cfb"
}
SS
sed -i "s,ss-server,ss-redir,g" /etc/init.d/shadowsocks-libev

tee /usr/local/bin/update_ipset.sh 1>/dev/null <<UIPSET
ipset save gfwlist|tail -n +2 |awk -F "abcdefg" '{print "ipset "\$0}'>/opt/ipset_save
UIPSET
tee /usr/local/bin/start.sh 1>/dev/null <<START
/usr/bin/ss-local -c /etc/shadowsocks-libev/config_prox.json -a root -u -f /var/run/shadowsocks-libev/shadowsocks-libev-server_listen.pid
echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -t nat -A POSTROUTING  -j MASQUERADE

/sbin/iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-ports 12345
/sbin/iptables -t nat -A PREROUTING -p udp -j REDIRECT --to-ports 12345

/sbin/iptables -t nat -I PREROUTING -d 124.193.211.0/24 -j RETURN
/sbin/iptables -t nat -I PREROUTING -d 45.63.0.0/16 -j RETURN
/sbin/iptables -t nat -I PREROUTING -d 104.238.0.0/16 -j RETURN
/sbin/iptables -t nat -I PREROUTING -d 108.61.0.0/16 -j RETURN

/sbin/iptables -t nat -I OUTPUT -d 45.63.0.0/16 -j RETURN
/sbin/iptables -t nat -I OUTPUT -d 104.238.0.0/16 -j RETURN
/sbin/iptables -t nat -I OUTPUT -d 108.61.0.0/16 -j RETURN


START
tee /etc/cron.d/update_ipset 1>/dev/null <<CRRON_UPDATEIPSET
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/local/bin/update_ipset.sh
CRRON_UPDATEIPSET


tee /etc/default/haproxy 1>/dev/null <<DFAULTPDNS
ENABLED=1
DFAULTPDNS


tee /etc/default/pdnsd 1>/dev/null <<DFAULTPDNS
START_DAEMON=yes
AUTO_MODE=
# optional CLI options to pass to pdnsd(8)
START_OPTIONS=
DFAULTPDNS
tee /etc/pdnsd.conf 1>/dev/null <<PDNSD
global {
        perm_cache=12048;
        cache_dir="/var/cache/pdnsd";
        run_as="pdnsd";
        server_port = 9853;
        server_ip = 127.0.0.1;  // Use eth0 here if you want to allow other
        status_ctl = on;
        paranoid=on;
        query_method=tcp_only;   // pdnsd must be compiled with tcp
        min_ttl=15m;       // Retain cached entries at least 15 minutes.
        max_ttl=1w;        // One week.
        timeout=10;        // Global timeout option (10 seconds).
}
server {
    label= "googledns";
    ip = 8.8.8.8;
    root_server = on;
    uptest = none;
}
source {
        owner=localhost;
//      serve_aliases=on;
        file="/etc/hosts";
}
rr {
        name=localhost;
        reverse=on;
        a=127.0.0.1;
        owner=localhost;
        soa=localhost,root.localhost,42,86400,900,86400,86400;
}
PDNSD

chmod +x /usr/local/bin/start.sh
chmod +x /usr/local/bin/update_ipset.sh

/usr/local/bin/update_ipset.sh

sed -i 's,^exit,/usr/local/bin/start.sh\nexit,g' /etc/rc.local 

/etc/init.d/pdnsd restart


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
