#!/bin/bash

HTTPS_PROXY=''
VERSION='12'
SERVICE=''
PGDATA=''
PGARCHIVE=''
CONF_DIR='/home/postgres'
TUNE_CONF_FILE='tune.conf'
LOG_CONF_FILE='logging.conf'
REPLICATION_CONF_FILE='replication.conf'
MONITORING_CONF_FILE='monitoring.conf'
DBMASTER=''
DBUSER=''
DBPASSWORD=''
ADMUSER=''
ADMPASSWORD=''
REPUSER='pgrep'
DBNAME=''
PORT='5432'

# Create the file repository configuration
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key
sudo $HTTPS_PROXY wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists
sudo apt-get update

# Install PostgreSQL
sudo apt-get -y install postgresql-$VERSION postgresql-contrib-$VERSION

# Stop PostgreSQL service
sudo systemctl stop postgresql

# Create data directory
PGHOME='/usr/lib/postgresql/12/bin'
if [ ! -d "$PGDATA" ];
then
    sudo mkdir -p $PGDATA
    sudo mkdir -p $PGARCHIVE
    sudo chown postgres. -R $PGDATA
    sudo chmod 700 postgres. -R $PGDATA
    sudo chown postgres. -R $PGARCHIVE
    echo "Directory $PGDATA created"
    echo "Directory $PGARCHIVE created"
else
    echo "Directory exists"
    exit 1
fi

# Run pg_basebackup
$PGHOME/pg_basebackup -U $REPUSER -h $DBMASTER -p $PORT -D $PGDATA -X stream -c fast -RvP > /tmp/replica.log
BASEBACKUP_STATUS=$?

# Start instance
if [ $BASEBACKUP_STATUS -eq 0 ];
then 
    echo 'promote_trigger_file='/tmp/$SERVICE-promote' >> $PGDATA/postgresql.conf'
    $PGHOME/pg_ctl -D $PGDATA start
    echo "Instance is created"
else
    echo "Backup failed, no instance created"
    exit 1
fi



