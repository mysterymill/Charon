#!/bin/bash

mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "CREATE DATABASE ${WINSTON_DB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "CREATE USER ${WINSTON_DB_USER}@localhost IDENTIFIED BY '${WINSTON_DB_PASSWORD}';"
mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${WINSTON_DB}.* TO '${WINSTON_DB_USER}'@'localhost';"
mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"
