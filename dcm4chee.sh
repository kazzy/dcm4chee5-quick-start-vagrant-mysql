#!/usr/bin/env bash

sudo su

# INSTALL REQUIRED DEBIAN PACKAGES
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -q -y  git openjdk-7-jdk maven unzip postgresql postgresql-contrib postgresql-client haproxy


# SET UP THE DATABASE
sudo -u postgres psql -c  "CREATE USER dcm4chee WITH PASSWORD 'dcm4chee';"
sudo -u postgres psql -c  "CREATE DATABASE dcm4chee;"
sudo -u postgres psql -c  "GRANT ALL PRIVILEGES ON DATABASE dcm4chee to dcm4chee;"


# DOWNLOAD AND DEPLOY WILDFLY
# Thanks to https://gesker.wordpress.com/2015/02/17/quick-install-wildfly-8-2-0-on-ubuntu-14-04/ for some of the steps!
cd /root
adduser --system --no-create-home --disabled-password --disabled-login wildfly
wget http://download.jboss.org/wildfly/8.2.0.Final/wildfly-8.2.0.Final.zip
unzip wildfly-8.2.0.Final.zip
mv wildfly-8.2.0.Final /opt/wildfly
chown -R wildfly /opt/wildfly
cd /opt/wildfly/bin/init.d/
cat > wildfly.conf <<EOL

# General configuration for the init.d scripts,
# not necessarily for JBoss AS itself.
# default location: /etc/default/wildfly

## Location of JDK
JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64/"

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
ln -s /opt/wildfly/bin/init.d/wildfly.conf /etc/default/wildfly
ln -s /opt/wildfly/bin/init.d/wildfly-init-debian.sh /etc/init.d/wildfly
cd /etc/init.d
update-rc.d wildfly defaults
# TODO Change listening IP address from 0.0.0.0 to 0.0.0.0
cd /root

# CLONE DCM4CHE (ONE E) AND COMPILE
git clone https://github.com/dcm4che/dcm4che.git
cd dcm4che
mvn install -Dmaven.test.skip=true
cd ..


# CLONE STORAGE AND COMPILE
git clone https://github.com/dcm4che/dcm4chee-storage2.git
cd dcm4chee-storage2
mvn install -Dmaven.test.skip=true
cd ..


# CLONE CONF AND COMPILE
git clone https://github.com/dcm4che/dcm4chee-conf.git
cd dcm4chee-conf
mvn install -Dmaven.test.skip=true
cd ..


# CLONE MONITORING AND COMPILE
git clone https://github.com/dcm4che/dcm4chee-monitoring
cd dcm4chee-monitoring
mvn install -Dmaven.test.skip=true
cd ..


# SET UP THE STORAGE DIRECTORY
mkdir -p /var/local/dcm4chee-arc
chown -R wildfly /var/local/dcm4chee-arc


# CLONE DCM4CHEE (TWO E's) AND COMPILE THEN DEPLOY
git clone https://github.com/dcm4che/dcm4chee-arc-cdi.git
cd dcm4chee-arc-cdi
mvn install -Dmaven.test.skip=true -Ddb=psql
cd dcm4chee-arc-assembly/target
unzip dcm4chee-arc-*.zip
export DCM4CHEE_ARC=`find \`pwd\` -name "dcm4chee-arc-*" -type d`
cd /root


# CREATE THE DB STRUCTURE
export PGPASSWORD=dcm4chee
psql -h 0.0.0.0 -U dcm4chee dcm4chee -f $DCM4CHEE_ARC/sql/create-table-psql.ddl
psql -h 0.0.0.0 -U dcm4chee dcm4chee -f $DCM4CHEE_ARC/sql/create-fk-index.ddl
psql -h 0.0.0.0 -U dcm4chee dcm4chee -f $DCM4CHEE_ARC/sql/create-index.ddl


# SET UP HAProxy
cat /home/vagrant/haproxy_additions.txt >> /etc/haproxy/haproxy.cfg
service haproxy restart


# SET UP WILDFLY
service wildfly stop
cd /opt/wildfly/standalone/configuration
cp -r $DCM4CHEE_ARC/configuration/dcm4chee-arc/ .
cd /opt/wildfly/
find $DCM4CHEE_ARC/jboss-module/ -name "*.zip" -type f -exec unzip -o {} \;

# FIX POSTGRES DRIVER
cd /opt/wildfly/modules/org/postgresql/main/
cat > module.xml <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="urn:jboss:module:1.1" name="org.postgresql">
    <resources>
        <resource-root path="postgresql-9.4-1201.jdbc4.jar"/>
    </resources>

    <dependencies>
        <module name="javax.api"/>
        <module name="javax.transaction.api"/>
    </dependencies>
</module>
EOL
cd /opt/wildfly/standalone/deployments/
wget https://jdbc.postgresql.org/download/postgresql-9.4-1201.jdbc4.jar
cp postgresql-9.4-1201.jdbc4.jar /opt/wildfly/modules/org/postgresql/main/
cd /opt/wildfly/standalone/configuration
cp -f /home/vagrant/standalone.xml .
cd /opt/wildfly/standalone/deployments
cp $DCM4CHEE_ARC/deploy/*.war .
chown -R wildfly /opt/wildfly/
service wildfly start
