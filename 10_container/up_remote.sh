#!/bin/bash

skipTests=false

while getopts s flag
do
    case "${flag}" in
        s) skipTests=true;
    esac
done

git pull

if [ "release" == "$target" ] ; then
    cargo build --release
else
    cargo build
fi


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
cp -f ../target/${target}/web-api app/
cp -f .env.local .env
cp -f nginx/nginx.conf.local nginx/nginx.conf

echo "Setting temporary environment variables..."
export WINSTON_DB_ROOT_PASSWORD=$(pwgen -Bs1 18)
export WINSTON_DB=winston
export WINSTON_DB_USER=winston
export WINSTON_DB_PASSWORD=$(pwgen -Bs1 18)

echo "(Re-)building containers..."
docker compose --project-name="winston" down --rmi all
docker compose --project-name="winston" build --no-cache
docker compose --project-name="winston" up -d

echo "Storing Mariadb root pwd in $HOME/mariadb.txt..."
echo $WINSTON_DB_ROOT_PASSWORD > $HOME/mariadb.txt
echo "Dropping temporary environment variables..."
unset WINSTON_DB_ROOT_PASSWORD
unset WINSTON_DB
unset WINSTON_DB_USER
unset WINSTON_DB_PASSWORD

