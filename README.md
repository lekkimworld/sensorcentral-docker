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
docker-compose up
```
