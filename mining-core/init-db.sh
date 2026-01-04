#!/bin/bash
# Initialize Miningcore Database
set -e

echo "Downloading database schema..."
wget https://raw.githubusercontent.com/oliverw/miningcore/master/src/Miningcore/Persistence/Postgres/Scripts/createdb.sql -O createdb.sql

echo "Checking if database is ready..."
until docker exec miningcore-db pg_isready -U miningcore; do
  echo "Waiting for Postgres..."
  sleep 2
done

echo "applying schema..."
docker cp createdb.sql miningcore-db:/createdb.sql
docker exec miningcore-db psql -U miningcore -d miningcore -f /createdb.sql

echo "Database initialized!"
rm createdb.sql
