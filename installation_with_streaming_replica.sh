#!/bin/bash

export HTTPS_PROXY=''
export VERSION='12'
export SERVICE=''
export PGDATA=''
export PGARCHIVE=''
export CONF_DIR='/home/postgres/install_postgresql'
export TUNE_CONF_FILE='tune.conf'
export LOG_CONF_FILE='logging.conf'
export REPLICATION_CONF_FILE='replication.conf'
export MONITORING_CONF_FILE='monitoring.conf'
export DBMASTER=''
export DBUSER=''
export DBPASSWORD=''
export ADMUSER=''
export ADMPASSWORD=''
export REPUSER='pgrep'
export DBNAME=''
export PORT='5432'

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
PGHOME=/usr/lib/postgresql/$VERSION/bin
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
    echo "promote_trigger_file='/tmp/$SERVICE-promote'" >> $PGDATA/postgresql.conf
    $PGHOME/pg_ctl -D $PGDATA start
    echo "Instance is created"
else
    echo "Backup failed, no instance created"
    exit 1
fi



