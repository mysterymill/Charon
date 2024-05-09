#!/bin/bash

target="debug"
skipTests=false

while getopts t:s flag
do
    case "${flag}" in
        t) target=${OPTARG};;
        s) skipTests=true;
    esac
done

if [ "release" == "$target" ] ; then
    cargo build --release
else
    cargo build
fi

if [ $skipTests = false ] ; then
    echo "Launching tests..."
    (cd .. && exec cargo test)

    if [ $? = 0 ] ; then
        echo "Tests succeeded, moving on..."
    else
        echo "Tests failed. Exiting."
        exit -1
    fi
else
    echo "Skipping tests"
fi

cp -f ../target/${target}/web-api app/
cp -f .env.local .env
cp -f nginx/nginx.conf.local nginx/nginx.conf

echo "Setting temporary environment variables..."
export MARIADB_ROOT_PASSWORD=DefaultR00tPwd
export APPDB=winston
export APPDBUSER=winston
export APPDBPASSWORD=$(pwgen -Bs1 18)

echo "(Re-)building containers..."
docker compose --project-name="winston" down --rmi all
docker compose --project-name="winston" build --no-cache
docker compose --project-name="winston" up -d

echo "Dropping temporary environment variables..."
unset MARIADB_ROOT_PASSWORD
unset APPDB
unset APPDBUSER
unset APPDBPASSWORD
