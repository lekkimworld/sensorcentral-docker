# Docker Compose for SensorCentral #
Docker Compose support to run SensorCentral.

## Running ##
```
#!/bin/bash

RABBIT_USER="mquser" \
RABBIT_PASSWORD="Passw0rd" \
POSTGRES_USER="sensorcentral" \
POSTGRES_PASSWORD="Passw0rd" \
OIDC_PROVIDER_URL="https://accounts.google.com" \
OIDC_CLIENT_ID="..." \
OIDC_CLIENT_SECRET="..." \
OIDC_REDIRECT_URI="http://localhost:8080/openid/callback" \
GOOGLE_HOSTED_DOMAIN="heisterberg.dk" \
GOOGLE_SERVICE_ACCOUNT_EMAIL="..." \
GOOGLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----\n" \
API_JWT_SECRET="..." \
SESSION_SECRET="..." \
SMARTME_KEY="..." \
SMARTME_PROTOCOL=http \
SMARTME_DOMAIN=localhost:3001 \
docker compose up
```

## Backup database on Heroku ##
```
#!/bin/bash

heroku pg:backups:capture --app desolate-meadow-68880
heroku pg:backups:url --app desolate-meadow-68880 b026
curl <url> > /tmp/latest.dump
scp /tmp/latest.dump lekkim@a.b.c.d:/tmp/latest.dump
```

## Create initial database ##

Shell 1: `POSTGRES_PASSWORD=Passw0rd docker compose -f postgres-docker-compose.yaml up`
Shell 2: `psql -h localhost -U postgres -d sensorcentral`
Shell 2: `grant all on schema public to sensorcentral;`
Shell 2: `\q`
Shell 2: `pg_restore --verbose --clean --no-acl --no-owner -h localhost -U sensorcentral -d sensorcentral /tmp/latest.dump`
