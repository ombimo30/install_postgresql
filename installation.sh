#!/bin/bash

HTTPS_PROXY='https_proxy=http://10.0.1.177:443/'
VERSION='12'
PGDATA='/mnt/crowdfunding/postgresql/data'
PGHOME='/usr/lib/postgresql/12/bin'
CONF_DIR='/home/ubuntu'
TUNE_CONF_FILE='/home/ubuntu'
LOG_CONF_FILE='/home/ubuntu'
REPLICATION_CONF_FILE='/home/ubuntu'
MONITORING_CONF_FILE='/home/ubuntu'

# Create the file repository configuration
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key
$HTTPS_PROXY wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists
apt-get update

# Install PostgreSQL
apt-get -y install postgresql-$VERSION postgresql-contrib-$VERSION

# Stop PostgreSQL service
systemctl stop postgresql

# Create data directory
mkdir -p $PGDATA
chown postgres. -R $PGDATA

# Initialize database
su - postgres
$PGHOME/initdb -D $PGDATA 

# Copy config file to data dir
cp $CONF_DIR/$TUNE_CONF_FILE $PGDATA/$TUNE_CONF_FILE
cp $CONF_DIR/$LOG_CONF_FILE $PGDATA/$LOG_CONF_FILE
cp $CONF_DIR/$REPLICATION_CONF_FILE $PGDATA/$REPLICATION_CONF_FILE

# Edit postgresql.conf file
PG_CONF_FILE='$PGDATA/postgresql.conf'
echo "include='$PGDATA/$TUNE_CONF_FILE'" >> $PG_CONF_FILE
echo "include='$PGDATA/$LOG_CONF_FILE'" >> $PG_CONF_FILE
echo "include='$PGDATA/$REPLICATION_CONF_FILE'" >> $PG_CONF_FILE
echo "include='$PGDATA/$MONITORING_CONF_FILE'" >> $PG_CONF_FILE

# Start database instance
$PGHOME/pg_ctl -D $PGDATA Start

# Create user
$PGHOME/psql -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD $DBPASSWORD CREATEDB;"
$PGHOME/psql -c "CREATE USER $ADMUSER WITH ENCRYPTED PASSWORD $ADMPASSWORD SUPERUSER;"
$PGHOME/psql -c "ALTER USER postgres NOLOGIN;"

# Create database
$PGHOME/psql -U $DBUSER -c "CREATE DATABASE $DBNAME;"

# Add pg_hba
PG_HBA_FILE='$PGDATA/pg_hba.conf'
echo "host  $DBNAME     $DBUSER     10.40.0.0/16       md5" >> $PG_HBA_FILE
$PGHOME/psql -c "SELECT PG_RELOAD_CONF();"
