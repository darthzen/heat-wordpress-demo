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
true#======================================
# Configure MySQL database
#--------------------------------------

# Helper function to wait 30s for MySQL socket to appear.
wait_for_socket() {
  local i
  for((i=0; i<150; i++)); do
    sleep 0.2
    test -S $1 && i='' && break
  done
  test -z "$i" || return 1
  return 0
}

# Helper function to execute the given sql file.
execute_sql_file() {
  local socket=$1
  local sql_file=$2
  mysql --socket="$socket" -u root < "$sql_file" 2>&1
}

# Initialize MySQL
echo "## Initializing MySQL databases and tables..."
mysql_install_db --user=mysql

# Start MySQL without networking
echo "## Starting MySQL..."
mkdir -p /var/log/mysql/
socket=/var/run/mysql/mysql.sock
mysqld_safe --skip-networking --user=mysql --pid-file=/tmp/mysqld.pid --socket=$socket &
wait_for_socket $socket || {
  echo "## Error: $socket didn't appear within 30 seconds"
}

# Load MySQL data dump, if it exists
mysql_dump=/tmp/mysql_dump.sql
if [ -f "$mysql_dump" ]; then
  echo "## Loading MySQL data dump..."
  execute_sql_file "$socket" "$mysql_dump"
else
  echo "## No MySQL data dump found, skipping"
fi

# Load MySQL users and permissions, if setup file exists
mysql_perms=/tmp/mysql_config.sql
if [ -f "$mysql_perms" ]; then
  echo "## Loading MySQL users and perms..."
  execute_sql_file "$socket" "$mysql_perms"
else
  echo "## No MySQL user/perms config found, skipping"
fi

# Auto-start MySQL
echo "## Configuring MySQL to auto-start on boot..."
chkconfig mysql on

# Stop MySQL service (for uncontained builds)
echo "## Stopping MySQL..."
mysql_pid=/tmp/mysqld.pid
kill -TERM `cat $mysql_pid`

# Clean up temp files (for uncontained builds)
rm -f "$mysql_perms" "$mysql_dump" "$mysql_pid"

echo "## MySQL configuration complete"


#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
c_rehash
