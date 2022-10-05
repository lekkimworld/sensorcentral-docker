#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER sensorcentral PASSWORD '$POSTGRES_PASSWORD';
	CREATE DATABASE sensorcentral;
	GRANT ALL PRIVILEGES ON DATABASE sensorcentral TO sensorcentral;
EOSQL
