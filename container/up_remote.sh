#!/bin/bash

skipTests=false

while getopts s flag
do
    case "${flag}" in
        s) skipTests=true;
    esac
done

git pull

if [ $skipTests = false ] ; then
    echo "Launching tests..."
    (cd .. && exec cargo test --release)

    if [ $? = 0 ] ; then
        echo "Tests succeeded, moving on..."
    else
        echo "Tests failed. Exiting."
        exit -1
    fi
else
    echo "Skipping tests"
fi

(cd .. && exec cargo build --release)
cp -f ../target/release/task_score app/
cp -f .env.remote .env
cp -f nginx/nginx.conf.remote nginx/nginx.conf

echo "Setting temporary environment variables..."
export MARIADB_ROOT_PASSWORD=pwgen -Bs1 18
export APPDB=winston
export APPDBUSER=winston
export APPDBPASSWORD=pwgen -Bs1 18

echo "(Re-)building containers..."
docker compose --project-name="winston" down --rmi all
docker compose --project-name="winston" build --no-cache
docker compose --project-name="winston" up -d

echo "!!!IMPORTANT!!! MariaDB root password is '${MARIADB_ROOT_PASSWORD}'. PLEASE REMEMBER THIS!"
echo "Dropping temporary environment variables..."
unset MARIADB_ROOT_PASSWORD
unset APPDB
unset APPDBUSER
unset APPDBPASSWORD

