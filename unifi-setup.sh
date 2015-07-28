echo "deb http://www.ubnt.com/downloads/unifi/debian stable ubiquiti" >  /etc/apt/sources.list.d/100-ubnt.list
echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >/etc/apt/sources.list.d/200-mongo.list  
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
apt-get update
sudo apt-get install unifi
apt-get install axel
axel -n 20 -a https://www.ubnt.com/downloads/unifi/4.6.6/unifi_sysvinit_all.deb
dpkg -i unifi_sysvinit_all.deb 
apt-get install mongodb-10gen mongodb-server openjdk-6-jre-headless jsvc
apt-get install mongodb-10gen mongodb-server openjdk-6-jre-headless jsvc mongodb-clients
sudo apt-get install unifi
