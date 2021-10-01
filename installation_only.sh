#!/bin/bash

HTTPS_PROXY=''
SERVICE=''
VERSION='12'
PGDATA='/mnt/$SERVICE/postgresql/data'
PGARCHIVE='/mnt/$SERVICE/postgresql/archived_wal'
CONF_DIR='/home/postgres'
TUNE_CONF_FILE='tune.conf'
LOG_CONF_FILE='logging.conf'
REPLICATION_CONF_FILE='replication.conf'
MONITORING_CONF_FILE='monitoring.conf'
DBUSER=''
DBPASSWORD=''
ADMUSER=''
ADMPASSWORD=''
DBNAME=''
PORT=''

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


