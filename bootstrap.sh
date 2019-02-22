#!/bin/bash

echo "defining ENV variables"
# MariaDB
DBUSER=root
DBPSW=rootpass
DBNAME=campingverna_wp

echo "defining ENV variables"
# Postfix
OEMAIL=out@aph.link
AEMAIL=alert@aph.link
DOMAIN=dev.local
MAILER=Satellite system
RELAYHOST=mail.aph.link
EPSW=cf56f9b38685b1d2

echo "Superpoteri!"
sudo -i

echo "Aggiornamento repository in corso"
apt-get update

echo "Impostazione della zona per correggere il fuso orario"
echo "Europe/Rome" | tee /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo "installazione di ntpdate per correggere l'orario"
apt-get install ntpdate -y
cd /etc/cron.daily/
touch ntpdate
echo '#!/bin/bash' | tee --append ntpdate
echo 'ntpdate ntp.ubuntu.com' | tee --append ntpdate
chmod a+x ntpdate
./ntpdate

echo "Impostazione LOCALE"
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

echo "Modifico il file hosts"
echo '192.168.10.10 dev.local' | tee --append /etc/hosts

echo "Installazione delle librerie php"
apt-get install -y php7.2 php7.2-cli php7.2-cgi php7.2-curl php7.2-mysql php7.2-gd php7.2-xmlrpc php7.2-fpm mcrypt

echo "Installazione di NginX"
apt-get install -y nginx
cp /usr/local/config/web/nginx/dev.local /etc/nginx/sites-available/
cp /usr/local/config/web/nginx/dev-wp.local /etc/nginx/sites-available/
cd /etc/nginx/sites-enabled/ && ln -s ../sites-available/dev.local dev.local
cd /etc/nginx/sites-enabled/ && ln -s ../sites-available/dev-wp.local
cp /usr/local/web/config/nginx/nginx.conf /etc/nginx/
rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default

echo "Installazione di MySQL client"
apt-get install -y mariadb-client

echo "Installazione di MariaDB"
debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password $DBPSW'
debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password $DBPSW'

echo "Installing MariaDB 10.1"
apt-get install mariadb-server-10.1 -y

echo "Caricamento della nuova configurazione di MariaDB"
cp /usr/local/data/config/mariadb/50-server.cnf /etc/mysql/mariadb.conf.d/
service mysql reload
service mysql start

echo "Creazione superutente"
echo "CREATE USER 'mrwooo'@'%' IDENTIFIED BY '*5AEC6C93A038338E23AED494060AF80BC1D75B37mrwooo_admin';" | mysql -u$DBUSER -p$DBPSW
echo "GRANT ALTER, CREATE, CREATE VIEW, CREATE USER, ALTER ROUTINE, CREATE ROUTINE, CREATE TEMPORARY TABLES, DELETE, DROP, EVENT, GRANT OPTION, INDEX, INSERT, LOCK TABLES, PROCESS, REFERENCES, RELOAD, SELECT, SHOW DATABASES, SHOW VIEW, SUPER, TRIGGER, UPDATE ON *.* TO 'mrwooo'@'%';" | mysql -u$DBUSER -p$DBPSW
echo "CREATE USER 'webapp'@'192.168.10.10' IDENTIFIED BY '*5AEC6C93A038338E23AED494060AF80BC1D75B37';" | mysql -u$DBUSER -p$DBPSW
echo "GRANT CREATE, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON *.* TO 'webapp'@'192.168.10.10';" | mysql -u$DBUSER -p$DBPSW
echo "flush privileges;" | mysql -u$DBUSER -p$DBPSW

echo "Creazione database $DBNAME"
echo "CREATE DATABASE IF NOT EXISTS $DBNAME;" | mysql -u$DBUSER -p$DBPSW

echo "Installazione Postfix"
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<E
'postfix postfix/root_address string $OEMAIL'
E
debconf-set-selections <<E
'postfix postfix/main_mailer_type string $MAILER'
E
debconf-set-selections <<E
'postfix postfix/mailname string $DOMAIN'
E
debconf-set-selections <<E
'postfix postfix/relayhost string $RELAYHOST'
E

apt-get install -y postfix > /dev/null

touch /etc/postfix/sasl_passwd
echo "$RELAYHOST $OEMAIL:$EPSW" | tee /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd

echo "Modifica di main.cf"
echo 'sender_dependent_relayhost_maps = hash:/etc/postfix/relayhost_maps' | tee --append /etc/postfix/main.cf
echo 'smtp_sasl_auth_enable = yes' | tee --append /etc/postfix/main.cf
echo 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' | tee --append /etc/postfix/main.cf
echo 'smtp_sasl_security_options = noanonymous' | tee --append /etc/postfix/main.cf
echo 'smtp_use_tls = yes' tee --append /etc/postfix/main.cf

touch /etc/postfix/relayhost_maps
echo "$AEMAIL [$RELAYHOST]" | tee /etc/postfix/relayhost_maps
postmap hash:/etc/postfix/relayhost_maps
service postfix reload
service postfix restart
newaliases

echo "Ricarico e riavvio i servizi"
service php7.2-fpm force-reload
service php7.2-fpm restart
pkill nginx
service nginx force-reload
service nginx restart
service mysql reload
service mysql restart
