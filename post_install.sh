#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf postgresql_enable="YES"
sysrc -f /etc/rc.conf bacula_dir_enable="YES"
sysrc -f /etc/rc.conf bacula_fd_enable="YES"
sysrc -f /etc/rc.conf bacula_sd_enable="YES"

# Start the service
service postgresql initdb
service postgresql start

USER="bacula"
DB="bacula"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`

# create user 
psql -d template1 -U pgsql -c "CREATE USER ${USER} CREATEDB SUPERUSER;"

# Create the production database & grant all privileges on database
psql -d template1 -U pgsql -c "CREATE DATABASE ${DB} OWNER ${USER};"

# Set a password on the postgres account
psql -d template1 -U pgsql -c "ALTER USER ${USER} WITH PASSWORD '${PASS}';"

# Connect as superuser to the db and enable pg_trgm extension
psql -U pgsql -d ${DB} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Fix permission for postgres 
echo "listen_addresses = '*'" >> /usr/local/pgsql/data/postgresql.conf
echo "host  all  all 0.0.0.0/0 md5" >> /usr/local/pgsql/data/pg_hba.conf

# Restart postgresql after config change
service postgresql restart

#Prepare the Database
cd /usr/local/share/bacula
for i in make_bacula_tables grant_bacula_privileges
do
./$i -U $USER -w -d $DB
done

# Start the service
service bacula-dir start 2>/dev/null
service bacula-fd start 2>/dev/null
service bacula-sd start 2>/dev/null

touch /var/log/bacula.log
chown bacula:bacula /var/log/bacula.log

echo "Please save your Database Access in a safe place!"
echo "Database Name: $DB"
echo "Database User: $USER"
echo "Database Password: $PASS"

echo "Documentation can be found at https://blog.bacula.org/documentation/documentation/."
echo "The config files can be found at /usr/local/etc/bacula/."
