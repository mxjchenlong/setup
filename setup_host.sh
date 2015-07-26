hn=$1
sed -i "s,^127.0.1.1.*,127.0.1.1       $hn,g" /etc/hosts
echo $hn > /etc/hostname
hostnamectl set-hostname $hn
