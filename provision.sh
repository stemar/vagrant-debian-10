timedatectl set-timezone $TIMEZONE

echo '==> Setting time zone to '$(cat /etc/timezone)

echo '==> Updating Debian repositories'

cp /vagrant/config/sources.list /etc/apt/sources.list
apt-get -q=2 update

echo '==> Installing Linux tools'

cp /vagrant/config/bash_aliases /home/vagrant/.bash_aliases
chown vagrant:vagrant /home/vagrant/.bash_aliases
apt-get -q=2 install software-properties-common apt-transport-https tree zip unzip pv whois &>/dev/null

echo '==> Installing Git and Subversion'

apt-get -q=2 install git subversion &>/dev/null

echo '==> Installing Apache'

apt-get -q=2 install apache2 apache2-utils &>/dev/null
apt-get -q=2 update
cp /vagrant/config/localhost.conf /etc/apache2/conf-available/localhost.conf
cp /vagrant/config/virtualhost.conf /etc/apache2/sites-available/virtualhost.conf
sed -i 's|GUEST_SYNCED_FOLDER|'$GUEST_SYNCED_FOLDER'|' /etc/apache2/sites-available/virtualhost.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/apache2/sites-available/virtualhost.conf
a2enconf localhost &>/dev/null
a2enmod rewrite vhost_alias &>/dev/null
a2ensite virtualhost &>/dev/null

echo '==> Setting MariaDB 10.6 repository'

apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' &>/dev/null
cp /vagrant/config/MariaDB.list /etc/apt/sources.list.d/MariaDB.list
apt-get -q=2 update

echo '==> Installing MariaDB'

DEBIAN_FRONTEND=noninteractive apt-get -q=2 install mariadb-server &>/dev/null

echo '==> Setting PHP 7.3 repository'

apt-get -q=2 update

echo '==> Installing PHP'

apt-get -q=2 install php php-pear php-cli libapache2-mod-php libphp-embed \
    php-bcmath php-bz2 php-curl php-fpm php-gd php-imap php-intl \
    php-mbstring php-mysql php-mysqlnd php-pgsql php-pspell php-readline \
    php-soap php-sqlite3 php-tidy php-xdebug php-xml php-xmlrpc php-yaml php-zip &>/dev/null
a2dismod mpm_event &>/dev/null
a2enmod mpm_prefork &>/dev/null
a2enmod php &>/dev/null
cp /vagrant/config/php.ini.htaccess /var/www/.htaccess
PHP_ERROR_REPORTING_INT=$(php -r 'echo '"$PHP_ERROR_REPORTING"';')
sed -i 's|PHP_ERROR_REPORTING_INT|'$PHP_ERROR_REPORTING_INT'|' /var/www/.htaccess

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer/adminer-plugins
    curl -LsS https://www.adminer.org/latest-en.php -o /usr/share/adminer/latest-en.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/login-password-less.php -o /usr/share/adminer/adminer-plugins/login-password-less.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/dump-json.php -o /usr/share/adminer/adminer-plugins/dump-json.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/pretty-json-column.php -o /usr/share/adminer/adminer-plugins/pretty-json-column.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi
cp /vagrant/config/adminer.php /usr/share/adminer/adminer.php
cp /vagrant/config/adminer-plugins.php /usr/share/adminer/adminer-plugins.php
cp /vagrant/config/adminer.conf /etc/apache2/conf-available/adminer.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/apache2/conf-available/adminer.conf
a2enconf adminer &>/dev/null

echo '==> Testing Apache configuration'

apache2ctl configtest

echo '==> Starting Apache'

service apache2 restart

echo '==> Starting MariaDB'

service mysql restart
mysqladmin -u root password ""

echo '==> Cleaning apt cache'

apt-get -q=2 autoclean
apt-get -q=2 autoremove

echo '==> Versions:'

lsb_release -d | cut -f 2
openssl version
curl --version | head -n1 | cut -d '(' -f 1
svn --version | grep svn,
git --version
apache2 -v | head -n1
mysql -V
php -v | head -n1
python --version
python3 --version
