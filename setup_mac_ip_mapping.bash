touch /etc/cron.d/reg_mac_dns
tee  /etc/cron.d/reg_mac_dns 1>/dev/null <<CRON
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
HOSTMAC=\$(cat /sys/class/net/eth0/address|awk -F ":" '{print $1$2$3$4$5$6}').mxj.io
IP=$(/sbin/ifconfig tun0 | grep 'inet ad' | cut -d: -f2 | awk '{ print \$1}')
* * * * * root curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=\$HOSTMAC&address=\$IP&type=A&ttl=60"
CRON