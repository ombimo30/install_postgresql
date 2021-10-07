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

# Create data directory
PGHOME='/usr/lib/postgresql/12/bin'
sudo mkdir -p $PGDATA
sudo mkdir -p $PGARCHIVE
sudo chown postgres. -R $PGDATA
sudo chown postgres. -R $PGARCHIVE

echo 'Creating Postgresql-$VERSION instance'

STARTTIME=$(date -Is)

# Initialize database
#su - postgres
$PGHOME/initdb -D $PGDATA

# Copy config file to data dir
cd $CONF_DIR
cp $TUNE_CONF_FILE $PGDATA/
cp $LOG_CONF_FILE $PGDATA/
cp $REPLICATION_CONF_FILE $PGDATA/
cp $MONITORING_CONF_FILE $PGDATA/

# Edit postgresql.conf file
cd $PGDATA
PG_CONF_FILE='postgresql.conf'
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

echo 'Created Postgresql-$VERSION instance at $ENDTIME'

printf "\"CREATE POSTGRESQL INSTANCE STATUS\",\"$DB_NAME\",\"$VERSION\",\"$STARTTIME\", \"$ENDTIME\", \"$TIMEUSED\", \"$DUMP_STATUS\" >> $WORKING_DIR/$LOG_FILE_FORMAT

# Create user
$PGHOME/psql -U postgres -d postgres -p $PORT -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWORD' CREATEDB;"
$PGHOME/psql -U postgres -d postgres -p $PORT -c "CREATE USER $ADMUSER WITH ENCRYPTED PASSWORD '$ADMPASSWORD' SUPERUSER;"
$PGHOME/psql -U postgres -d postgres -p $PORT -c "ALTER USER postgres NOLOGIN;"

# Create database
$PGHOME/psql -U $DBUSER -d postgres -p $PORT -c "CREATE DATABASE $DBNAME;"

# Add pg_hba
cd $PGDATA
PG_HBA_FILE='pg_hba.conf'
echo "host  $DBNAME     $DBUSER     0.0.0.0/0       md5" >> $PG_HBA_FILE
$PGHOME/psql -U $ADMUSER -d postgres -p $PORT -c "SELECT PG_RELOAD_CONF();"
