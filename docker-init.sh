#!/bin/bash
ether_adp=$(ifconfig|egrep ^eth|awk '{print $1}')
host_ip=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')
last_digit=$(echo `ifconfig $ether_adp 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`|awk -F "." '{print $4}')
lsec_digit=$(echo `ifconfig $ether_adp 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`|awk -F "." '{print $3}')

bip=10.$lsec_digit.$last_digit.1/24
ip_range=10.$lsec_digit.$last_digit.0/24


docker_info=$(docker --version 2>/dev/null |grep version|grep build)

if [ "$docker_info" == "" ]; then
curl -sSL https://get.daocloud.io/docker | sh
curl -L get.daocloud.io/docker/compose/releases/download/1.4.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

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
tee /home/bill/.ssh/config 1>/dev/null <<SSHCONFIG
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
SSHCONFIG
chown -R bill:bill /home/bill/
chmod -R og-rw /home/bill/.ssh

useradd ros -u 5002  -m -s /bin/bash
touch /etc/sudoers.d/ros

chown -R  ros:ros /home/ros
mkdir -p touch /home/ros/.ssh/
touch /home/ros/.ssh/id_dsa
touch /home/ros/.ssh/known_hosts
tee /home/ros/.ssh/id_dsa 1>/dev/null <<PK
-----BEGIN DSA PRIVATE KEY-----
MIIBuwIBAAKBgQCoz2zXKYQa1PMv2hksg59d8XZYcxysWEXxviUCoQM2ynRY+w49
FsoaU/7ILrX1bWGnwxAH1Ub8+XfCNtfE4nzqFBmzpbxp3ZqlWns08CqVeauv7Lvj
pEmXesrqwWtOnOw6Wsj2YuG8HJXYCN9gFZq394qJCEC/DiAKN8kcvbVCcwIVAP6i
0v3hfkrgUY+RIe0nxvZc73EPAoGAHEF1A7sZVKLNgNI6q6qhp0lpKfdXmEwMawSC
NE6brjRpCMaKc93cLT+Sv6PlryQA6en4ob9qH6ow/Ek4Yrbk+87R7s6hSeCD6fvL
N/ggPnwUQpj08czED3nsv3w4AnmovG7dBrYM+uy2E4pSyWeDlSMB6Q98O9yzZGtc
dxkR2fICgYAdK7qhLt7GcVzVfkZ90L+NECKw/2FlK7mto3p4h6LpM0URI8O0s93F
fD5UKLUUTV6lTn7h/y1SiFmysTA108F+BGixGW4vzCDIBINNHlrMP46BCCkxin3r
wtz6Y/pqYMRW/P26ID+UfUTYAXGGyWsaHy8S6G6c9bdEVQHoudUvDQIVAM2kDcYE
22MfUFjWt7TG4ta/umeM
-----END DSA PRIVATE KEY-----
PK
tee /home/ros/.ssh/config 1>/dev/null <<SSHCONFIG
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
SSHCONFIG
chown -R ros:ros /home/ros/
chmod -R og-rw /home/ros/.ssh

sed -i 's,^exit,/usr/local/bin/docker_init.sh\nexit,g' /etc/rc.local
fi


ros_result=$(su ros -c "ssh -p 32200 192.168.168.1 /ip route print"|grep $ip_range)

if [ "" == "$ros_result" ]; then
echo "running /ip route add dst-address=$ip_range gateway=$host_ip check-gateway=ping distance=1"
su ros -c "ssh -p 32200 192.168.168.1 /ip route add dst-address=$ip_range gateway=$host_ip check-gateway=ping distance=1"
fi


service docker stop
ifconfig docker0 down
brctl delbr docker0
echo "DOCKER_OPTS=\"--insecure-registry docker.mxj.io --insecure-registry 192.168.168.110:50000 --insecure-registry 192.168.210.250 --insecure-registry 192.168.168.110 --insecure-registry 192.168.168.110  --insecure-registry registry.mxj.io  --insecure-registry docker.office.fizzback.net --registry-mirror http://22628a2d.m.daocloud.io  -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock --bip=$bip"\" > /etc/default/docker

service docker start

sleep 5
docker ps -a |awk '{print $1}'|tail -n +2|xargs  -I '{}' docker start '{}'
docker ps -a |awk '{print $1}'|tail -n +2|xargs  -I '{}' docker start '{}'


hn=m$(printf %02d%s $lsec_digit$last_digit)
sed -i "s,^127.0.1.1.*,127.0.1.1       $hn,g" /etc/hosts
echo $hn > /etc/hostname
hostnamectl set-hostname $hn


tee  /etc/cron.d/host_dns_update 1>/dev/null << HOSTUPDATE
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
* * * * * root sleep 5 && curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(hostname).mxj.io&address=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')&type=A&ttl=60" && logger -t hostdns "register dns $(hostname).mxj.io $(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')"
* * * * * root sleep 15 && curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(hostname).mxj.io&address=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')&type=A&ttl=60"
* * * * * root sleep 25 && curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(hostname).mxj.io&address=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')&type=A&ttl=60"
* * * * * root sleep 35 && curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(hostname).mxj.io&address=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')&type=A&ttl=60"
* * * * * root sleep 45 && curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(hostname).mxj.io&address=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')&type=A&ttl=60"
* * * * * root sleep 55 && curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(hostname).mxj.io&address=$(/sbin/ifconfig $ether_adp | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')&type=A&ttl=60"
HOSTUPDATE

# setup cron
tee /etc/cron.d/dns_update 1>/dev/null <<DNSUPDATE
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
* * * * * root sleep 5 && docker ps|tail -n +2 |awk '{print \$1}'|xargs docker inspect -f 'http://123.59.58.107:9090/api/set_dns?name={{.Config.Hostname}}.{{.Config.Domainname}}&address={{.NetworkSettings.IPAddress}}&type=A&ttl=80'|xargs curl|logger -t "docker-domain-pusher"
* * * * * root sleep 15 && docker ps|tail -n +2 |awk '{print \$1}'|xargs docker inspect -f 'http://123.59.58.107:9090/api/set_dns?name={{.Config.Hostname}}.{{.Config.Domainname}}&address={{.NetworkSettings.IPAddress}}&type=A&ttl=80'|xargs curl|logger -t "docker-domain-pusher"
* * * * * root sleep 25 && docker ps|tail -n +2 |awk '{print \$1}'|xargs docker inspect -f 'http://123.59.58.107:9090/api/set_dns?name={{.Config.Hostname}}.{{.Config.Domainname}}&address={{.NetworkSettings.IPAddress}}&type=A&ttl=80'|xargs curl|logger -t "docker-domain-pusher"
* * * * * root sleep 35 && docker ps|tail -n +2 |awk '{print \$1}'|xargs docker inspect -f 'http://123.59.58.107:9090/api/set_dns?name={{.Config.Hostname}}.{{.Config.Domainname}}&address={{.NetworkSettings.IPAddress}}&type=A&ttl=80'|xargs curl|logger -t "docker-domain-pusher"
* * * * * root sleep 45 && docker ps|tail -n +2 |awk '{print \$1}'|xargs docker inspect -f 'http://123.59.58.107:9090/api/set_dns?name={{.Config.Hostname}}.{{.Config.Domainname}}&address={{.NetworkSettings.IPAddress}}&type=A&ttl=80'|xargs curl|logger -t "docker-domain-pusher"
* * * * * root sleep 55 && docker ps|tail -n +2 |awk '{print \$1}'|xargs docker inspect -f 'http://123.59.58.107:9090/api/set_dns?name={{.Config.Hostname}}.{{.Config.Domainname}}&address={{.NetworkSettings.IPAddress}}&type=A&ttl=80'|xargs curl|logger -t "docker-domain-pusher"
DNSUPDATE