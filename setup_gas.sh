touch /etc/cron.d/reg_mac_dns
tee  /etc/cron.d/reg_mac_dns 1>/dev/null <<CRON
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

HOSTMAC=$(cat /sys/class/net/eth0/address|awk -F ":" '{print $1$2$3$4$5$6}').mxj.io
IP=$(/sbin/ifconfig tun0 | grep 'inet ad' | cut -d: -f2 | awk '{ print $1}')
*/1 * * * * root curl "http://123.59.58.107:9090/api/set_dns?apiVersion=1&name=$(cat /sys/class/net/eth0/address|awk -F ":" '{print $1$2$3$4$5$6}').mxj.io&address=\$(/sbin/ifconfig tun0 | grep 'inet ad' | cut -d: -f2 | awk '{ print \$1}')&type=A&ttl=70"
CRON
