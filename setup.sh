### These instructions assume that you are running Debian 9. After completing these instructions
### you will have a basic installation with database and webserver.
# https://www.debian.org/distrib/
# debian-9.3.0-amd64-netinstall.iso  
# graphical (debian desktop environment) installed with default system tools 

#!/bin/bash
#
# https://github.com/Igel18/Berlussimo
#
# Copyright (c) 2018 GNU Affero General Public License v3.0

### Attention: You should only use this script for develop becouse of default passwords and usernames

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

if [[ -e /etc/debian_version ]]; then
	OS=debian
	GROUPNAME=nogroup
	RCLOCAL='/etc/rc.local'
else
	echo "Looks like you aren't running this installer on Debian, Ubuntu or CentOS"
	exit
fi

echo
echo 'Welcome to this berlussimo installer!'
echo

# upgrade debian
echo
echo 'update linux'
echo

apt update --yes
apt upgrade --yes
apt dist-upgrade --yes

# install npm
echo 
echo 'install curl'
echo 
apt install curl --yes
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt update --yes
apt install -y nodejs --yes

# update npm to latest release 
# npm -i -g npm 

# install nginx and dependencies
echo
echo 'install nginx'
echo 
apt install nginx libnginx-mod-nchan git nasm --yes

# install libpng 12
echo 
echo 'install libpng 12'
echo 
wget http://ftp.de.debian.org/debian/pool/main/libp/libpng/libpng12-0_1.2.50-2+deb8u3_amd64.deb -P ~
apt install ~/libpng12-0_1.2.50-2+deb8u3_amd64.deb

#install php 
echo
echo 'install php'
echo 
apt install php7.0 php7.0-gd php7.0-mysql php7.0-fpm php7.0-xml php7.0-mbstring php7.0-curl php7.0-bcmath php7.0-zip --yes

echo
echo 'get berlussimo from git'
echo 
cd /var/www/; git clone https://github.com/Igel18/Berlussimo berlussimo
cd /var/www/berlussimo/; git checkout develop

# install MySQL. The setup will let you set a root password for the mySQL server. You will need this later.
echo
echo 'install mysql'
echo 
apt-get install mysql-server --yes

### import database schema. Theese instructions will create a database named berlussimo.
### Set this name to reflect your settings from config.inc.php
### You will be prompted for the root password set above.
echo 
echo 'install and setup database berlussimo with user root and password berlussimo'
echo 
mysqladmin create -u root -p berlussimo
### Change password do "ra"

#echo
#echo 'please type manually the password ra and then the sql command to change privileges if not automated'
#echo

### Connect to mysql and Change Privileges 
mysql -u root -p berlussimo < /var/www/berlussimo/install/DB-Version-0.4.0/berlussimo_db_permissions.sql
 
echo 
echo 'setup database query for berlussimo'
echo 
mysql -u root -p berlussimo < /var/www/berlussimo/install/DB-Version-0.4.0/berlussimo_db_0.4.0.sql
mysql -u root -p berlussimo < /var/www/berlussimo/install/DB-Version-0.4.0/berlussimo_db_0.4.1.sql
mysql -u root -p berlussimo < /var/www/berlussimo/install/DB-Version-0.4.0/berlussimo_db_0.4.2.sql
mysql -u root -p berlussimo < /var/www/berlussimo/install/DB-Version-0.4.0/berlussimo_db_0.4.3.sql

#install composer and fetch dependencies
echo 
echo 'install composer'
echo 
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
cd /var/www/berlussimo/

composer install

echo "APP_KEY=" > .env
php artisan key:generate

php artisan migrate
php artisan optimize
php artisan route:cache
php artisan parser:generate

# if you setup a fresh database
# php artisan passport:install
# else if you only setup a fresh webserver
php artisan passport:keys

# install node dependencies
echo
echo 'install npm node dependencies'
echo 
npm install

# build javascript app
echo
echo 'build javascript app'
echo 
npm run prod

#make web directory writeable by the webserver
echo
echo 'make web directory writeable by the webserver'
echo 
chown -R www-data:www-data /var/www/berlussimo

# edit default (/etc/nginx/sites-available/default) site to
# reflect settings from install/config/nginx/default
#nano /etc/nginx/sites-available/default
#systemctl restart nginx

#oder einfach die Datei kopieren:  
echo
echo 'copy webserver configuration'
echo 
cp /var/www/berlussimo/install/config/nginx/default /etc/nginx/sites-available/

echo
echo 'restart the webserver'
echo 
systemctl restart nginx

echo
echo 'copy laravel configuration and restart the webserver'
echo 
# copy install/config/systemd/laravell-queue.service to /etc/systemd/system/
cp /var/www/berlussimo/install/config/systemd/laravel-queue.service /etc/systemd/system/

echo
echo 'restart laravel'
echo 
# start laravel queue and enable start on startup
systemctl start laravel-queue
systemctl enable laravel-queue

### you should now be able to open http://<your_server>/ in your browser and login with
echo
echo 'you should now be able to open http://localhost/ in your browser and login with'
echo 'login: admin@berlussimo'
echo 'password: password'
echo 
