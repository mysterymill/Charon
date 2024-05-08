#!/bin/bash

SEMAPHORE_FILE="/var/semaphore"

if [ ! -f "$SEMAPHORE_FILE" ]; then
    mysql -e "CREATE DATABASE ${APPDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -e "CREATE USER ${APPDBUSER}@localhost IDENTIFIED BY '${APPDBPASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${APPDB}.* TO '${APPDBUSER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    touch "$SEMAPHORE_FILE"
fi

tail -f /dev/null