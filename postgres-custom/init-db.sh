#!/bin/bash
set -e

# Create the 'assetdb' database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE assetdb;
EOSQL

# Connect to 'assetdb' and create the extension
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "assetdb" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public;
EOSQL
