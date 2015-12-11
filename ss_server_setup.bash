sudo su

DEBIAN_FRONTEND=noninteractive
echo "deb http://mirror.bit.edu.cn/ubuntu/ trusty main" > /etc/apt/sources.list
apt-get update
apt-get -y upgrade --fix-missing
apt-get install -y --force-yes shadowsocks-libev apache2
dd if=/dev/zero of=/var/www/html/100m bs=1024 count=102400
dd if=/dev/zero of=/var/www/html/10m bs=1024 count=10240

tee /etc/shadowsocks-libev/config.json 1> /dev/null<<SS
{
    "server":"0.0.0.0",
    "server_port":8443,
    "password":"r1adev",
    "timeout":50,
    "method":"aes-256-cfb"
}
SS

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