#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# SuSEconfig
#--------------------------------------
echo "** Running suseConfig..."
suseConfig

echo "** Running ldconfig..."
/sbin/ldconfig

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey


#======================================
# Sysconfig Update
#--------------------------------------
echo '** Update sysconfig entries...'
baseUpdateSysConfig /etc/sysconfig/keyboard KEYTABLE us.map.gz
baseUpdateSysConfig /etc/sysconfig/network/config NETWORKMANAGER no
baseUpdateSysConfig /etc/sysconfig/SuSEfirewall2 FW_SERVICES_EXT_TCP 22\ 80\ 443
baseUpdateSysConfig /etc/sysconfig/console CONSOLE_FONT lat9w-16.psfu


#======================================
# Setting up overlay files 
#--------------------------------------
echo '** Setting up overlay files...'
echo mkdir -p /srv/www/htdocs/
mkdir -p /srv/www/htdocs/
echo tar xfp /image/7f392f749e56e77c86ac2b3856140bae -C /srv/www/htdocs/
tar xfp /image/7f392f749e56e77c86ac2b3856140bae -C /srv/www/htdocs/
echo rm /image/7f392f749e56e77c86ac2b3856140bae
rm /image/7f392f749e56e77c86ac2b3856140bae
mkdir -p /srv/www/htdocs/
mv /studio/overlay-tmp/files//srv/www/htdocs//wordpress.tar.gz /srv/www/htdocs//wordpress.tar.gz
chown nobody:nobody /srv/www/htdocs//wordpress.tar.gz
chmod 644 /srv/www/htdocs//wordpress.tar.gz
mkdir -p /etc/
mv /studio/overlay-tmp/files//etc//ntp.conf /etc//ntp.conf
chown nobody:nobody /etc//ntp.conf
chmod 644 /etc//ntp.conf
chown root:root /build-custom
chmod 755 /build-custom
# run custom build_script after build
/build-custom
chown root:root /etc/init.d/suse_studio_custom
chmod 755 /etc/init.d/suse_studio_custom
test -d /studio || mkdir /studio
cp /image/.profile /studio/profile
cp /image/config.xml /studio/config.xml
rm -rf /studio/overlay-tmp
true
#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
c_rehash
