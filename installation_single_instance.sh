#!/bin/bash

# Please create OS user postgres by using adduser postgres command
# Before begin the installation, please make sure that you have the correct tuning configuration taking from https://pgtune.leopard.in.ua/#/
# Don't forget to edit configuration file especially replication.conf if necessary
# Grant sudoers to postgres user by using these command :
# usermod -aG wheel postgres (for RHEL/centOS)
# usermod -aG sudo postgres (for Ubuntu)
# echo "postgres  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/postgres
# Revoke sudoers from postgres when it's done by using this command 
# deluser postgres sudo
# PLEASE ENJOY #

export HOST=''
export HTTPS_PROXY=''
export SERVICE=''
export VERSION='13'
export PGDATA=/mnt/$SERVICE/postgresql/data
export PGARCHIVE=/mnt/$SERVICE/postgresql/archive
export CONF_DIR='/home/postgres/install_postgresql'
export TUNE_CONF_FILE='tune.conf'
export LOG_CONF_FILE='logging.conf'
export REPLICATION_CONF_FILE='replication.conf'
export MONITORING_CONF_FILE='monitoring.conf'
export DBUSER=''
export DBPASSWORD=''
export ADMUSER=''
export ADMPASSWORD=''
export DBNAME=''
export PORT=''
export WORKING_DIR='/home/postgres'
export LOG_FILE_FORMAT=postgresql-$VERSION.log

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
export PGHOME=/usr/lib/postgresql/$VERSION/bin
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

echo Creating Postgresql-$VERSION instance

STARTTIME=$(date -Is)

# Initialize database
#su - postgres
$PGHOME/initdb -D $PGDATA

# Copy config file to data dir
echo "archive_command='cp %p $PGARCHIVE/%f'" >> $CONF_DIR/$REPLICATION_CONF_FILE
cp $CONF_DIR/$TUNE_CONF_FILE $PGDATA/
cp $CONF_DIR/$LOG_CONF_FILE $PGDATA/
cp $CONF_DIR/$REPLICATION_CONF_FILE $PGDATA/
cp $CONF_DIR/$MONITORING_CONF_FILE $PGDATA/

# Edit postgresql.conf file
cd $PGDATA
export PG_CONF_FILE='postgresql.conf'
echo "include='$TUNE_CONF_FILE'" >> $PG_CONF_FILE
echo "include='$LOG_CONF_FILE'" >> $PG_CONF_FILE
echo "include='$REPLICATION_CONF_FILE'" >> $PG_CONF_FILE
echo "include='$MONITORING_CONF_FILE'" >> $PG_CONF_FILE

# Start database instance
$PGHOME/pg_ctl -D $PGDATA start

ENDTIME=$(date -Is)
STARTTIMESTAMP=$(date -d "${STARTTIME}" +%s)
ENDTIMESTAMP=$(date -d "${ENDTIME}" +%s)
TIMEUSED=$(( ENDTIMESTAMP-STARTTIMESTAMP ))

export TZ=Asia/Jakarta
STARTTIME=$(date --date=$STARTTIME -Is)
ENDTIME=$(date --date=$ENDTIME -Is)

echo Created Postgresql-$VERSION instance at $ENDTIME

printf "\"CREATE POSTGRESQL INSTANCE STATUS\",\"$HOST\",\"$SERVICE\",\"$VERSION\",\"$STARTTIME\", \"$ENDTIME\", \"$TIMEUSED\"" >> $WORKING_DIR/$LOG_FILE_FORMAT


