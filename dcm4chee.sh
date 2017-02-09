#!/usr/bin/env bash

sudo su

# INSTALL REQUIRED DEBIAN PACKAGES
yum -q -y update

rpm --import http://dev.mysql.com/doc/refman/5.7/en/checking-gpg-signature.html
rpm -ihv http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm
yum --disablerepo=\* --enablerepo='mysql57-community*' list available
yum --enablerepo='mysql57-community*' install -q -y mysql-community-server

yum install -q -y  git java-1.8.0-openjdk  unzip vim haproxya expect openldap-servers openldap-clients

service mysqld start
chkconfig mysqld on

TEMPPASS=`grep 'temporary password' /var/log/mysqld.log | cut -d' ' -f11`
echo $TEMPPASS

mysql -uroot -p"${TEMPPASS}" --connect-expired-password -e"set password for root@localhost=password('passwordPASSWORD@999');"
mysql -uroot -ppasswordPASSWORD@999 -e"SET GLOBAL validate_password_length=4;"
mysql -uroot -ppasswordPASSWORD@999 -e"SET GLOBAL validate_password_policy=LOW;"
mysql -uroot -ppasswordPASSWORD@999 -e"set password for root@localhost=password('root');"

expect -c "
mysql_secure_installation
expect \"Enter password for user root:\"
send -- \"root\n\"
expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send -- \"\n\"
expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send -- \"y\n\"
expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send -- \"y\n\"
expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send -- \"y\n\"
expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send -- \"y\n\"
"

echo 'character-set-server = utf8' >> /etc/my.cnf
echo 'default_password_lifetime = 0' >> /etc/my.cnf
echo 'skip-character-set-client-handshake' >> /etc/my.cnf

service mysqld restart

# SET UP THE DATABASE
mysql -uroot -proot -e'create database dcm4chee;'
mysql -uroot -proot -e"SET GLOBAL validate_password_length=8;"
mysql -uroot -proot -e"SET GLOBAL validate_password_policy=LOW;"
mysql -uroot -proot -e"grant all on dcm4chee.* to 'dcm4user'@'localhost' identified by 'dcm4pass';"

# Download 
cd /root
wget https://sourceforge.net/projects/dcm4che/files/dcm4chee-arc-light5/5.8.1/dcm4chee-arc-5.8.1-mysql.zip/download -O dcm4chee-arc-5.8.1-mysql.zip
unzip dcm4chee-arc-5.8.1-mysql.zip

cp -f /home/vagrant/create-mysql.sql /root
mysql -udcm4user -pdcm4pass dcm4chee < /root/create-mysql.sql

# INSTALL maven
cd /root
wget http://ftp.kddilabs.jp/infosystems/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar zxvf apache-maven-3.3.9-bin.tar.gz
mv ./apache-maven-3.3.9 /usr/local/apache-maven
echo 'export M2_HOME=/usr/local/apache-maven' >> ~/.bash_profile
echo 'export M2=$M2_HOME/bin' >> ~/.bash_profile
echo 'export MAVEN_OPTS="-Xms256m -Xmx512m"' >> ~/.bash_profile
echo 'export PATH=$M2:$PATH' >> ~/.bash_profile
source ~/.bash_profile

# DOWNLOAD AND DEPLOY WILDFLY
# Thanks to https://gesker.wordpress.com/2015/02/17/quick-install-wildfly-8-2-0-on-ubuntu-14-04/ for some of the steps!
cd /root
useradd --system --no-create-home  wildfly
usermod -s /sbin/nologin wildfly
wget http://download.jboss.org/wildfly/10.0.0.Final/wildfly-10.0.0.Final.zip
unzip wildfly-10.0.0.Final.zip
mv wildfly-10.0.0.Final /opt/wildfly
mkdir /opt/wildfly/bin/init.d/
cp -f /home/vagrant/wildfly-init-redhat.sh /opt/wildfly/bin/init.d/
chmod a+x /opt/wildfly/bin/init.d/wildfly-init-redhat.sh
chown -R wildfly /opt/wildfly
cd /opt/wildfly/bin/init.d/
cat > wildfly.conf <<EOL

# General configuration for the init.d scripts,
# not necessarily for JBoss AS itself.
# default location: /etc/default/wildfly

## Location of JDK
JAVA_HOME="/usr/lib/jvm/jre-openjdk"

## Location of WildFly
JBOSS_HOME="/opt/wildfly"

## The username who should own the process.
JBOSS_USER=wildfly

## The mode WildFly should start, standalone or domain
JBOSS_MODE=standalone

## Configuration for standalone mode
JBOSS_CONFIG=standalone.xml

## Configuration for domain mode
# JBOSS_DOMAIN_CONFIG=domain.xml
# JBOSS_HOST_CONFIG=host-master.xml

## The amount of time to wait for startup
# STARTUP_WAIT=60

## The amount of time to wait for shutdown
# SHUTDOWN_WAIT=60

## Location to keep the console log
# JBOSS_CONSOLE_LOG="/var/log/wildfly/console.log"
EOL

cp /opt/wildfly/bin/init.d/wildfly.conf /etc/default/wildfly
cp /opt/wildfly/bin/init.d/wildfly-init-redhat.sh /etc/init.d/wildfly
service wildfly start
chkconfig wildfly on



