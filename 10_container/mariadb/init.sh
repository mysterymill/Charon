#!/bin/bash

mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "CREATE DATABASE \`${WINSTON_DB}\` CHARACTER SET utf8 COLLATE utf8_general_ci;"
mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "CREATE USER \`${WINSTON_DB_USER}\`@\`localhost\` IDENTIFIED BY ${WINSTON_DB_PASSWORD};"
mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON \`${WINSTON_DB}\`.\`%\` TO \`${WINSTON_DB_USER}\`@\`%\`;"
mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"
