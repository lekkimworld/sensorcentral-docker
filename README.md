# Docker Compose for SensorCentral #
Docker Compose support to run SensorCentral and steps for installing a new server to run it on Digital Ocean.

## DigitalOcean ##
```
# ssh in as root (ssh root@.....)
apt-get update
apt-get upgrade -y

# uninstall unoffical docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker run --rm hello-world

# add user
adduser lekkim
usermod -aG docker lekkim

# switch to user
su - lekkim
mkdir .ssh
chmod 700 .ssh
nano ~/.ssh/authorized_keys
exit

# add new user as sudoer
adduser lekkim sudo

# exit
exit

# ssh back in as lekkim (ssh lekkim@.....)
# test docker
docker run --rm hello-world

# install tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

sudo apt-get update
sudo apt-get install tailscale
sudo tailscale up

# configure portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts

# open portainer and add admin user (https://tailscale-hostname:9443)

# setup watchtower 
docker run --detach --restart=unless-stopped \
    --name watchtower \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    containrrr/watchtower

# using portainer create stack for nginx-proxy-manager
version: '3'
services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "npm_db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
    volumes:
      - /opt/docker-volumes/nginxproxymanager/data:/data
      - /opt/docker-volumes/nginxproxymanager/letsencrypt:/etc/letsencrypt
    restart: unless-stopped
    depends_on: [npm_db]

  npm_db:
    image: 'jc21/mariadb-aria:latest'
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - /opt/docker-volumes/nginxproxymanager-db:/var/lib/mysql
    restart: unless-stopped

networks:
  default:
    name: npm-bridge

# open nginx-proxy-manager ui (http://tailscale-hostname:81, configure from admin@exanmple.com (changeme) to lekkim@heisterberg.dk)


# create directories for sensorcentral data
sudo mkdir -p /opt/docker-volumes
sudo mkdir -p /opt/docker-volumes/redis
sudo mkdir -p /opt/docker-volumes/postgres
sudo chgrp docker /opt/docker-volumes
sudo chgrp docker /opt/docker-volumes/redis
sudo chgrp docker /opt/docker-volumes/postgres
sudo chmod 770 /opt/docker-volumes/redis
sudo chmod 770 /opt/docker-volumes/postgres

# checkout sensorcentral-docker repo into /home/lekkim
# create sensorcentral stack in portainer
version: '3'
services:
  redis:
    container_name: redis
    image: 'redis:7'
    restart: unless-stopped
    command: redis-server --include /usr/local/etc/redis/redis.conf --save 60 1 --loglevel warning
    ports:
     - "6379:6379"
    volumes:
      - ${PWD}/redis.conf:/usr/local/etc/redis/redis.conf
      - /opt/docker-volumes/redis:/data
  postgres:
    container_name: postgres
    image: 'postgres:15.5'
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=postgres
      - POSTGRES_HOST_AUTH_METHOD=password
    volumes:
      - /opt/docker-volumes/postgres:/var/lib/postgresql/data
      - ${PWD}/00-init-sensorcentral-db.sh:/docker-entrypoint-initdb.d/00-init-sensorcentral-db.sh
  app:
    container_name: sensorcentral
    image: 'lekkim/sensorcentral:1.14'
    restart: on-failure
    ports:
      - "8080:8080"
    depends_on:
      - redis
      - postgres
    environment:
      - PORT=8080
      - LOG_LEVEL=${LOG_LEVEL}
      - LOG_LEVEL_LOGGERS=${LOG_LEVEL_LOGGERS}
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/sensorcentral
      - DATABASE_ALLOW_SCHEMA_UPGRADE=${DATABASE_ALLOW_SCHEMA_UPGRADE}
      - APP_NO_PROD_TLS=${APP_NO_PROD_TLS}
      - APP_DOMAIN=${APP_DOMAIN}
      - ADMIN_USERNAME=${ADMIN_USERNAME}
      - ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - OIDC_PROVIDER_URL_GOOGLE=${OIDC_PROVIDER_URL_GOOGLE}
      - OIDC_CLIENT_ID_GOOGLE=${OIDC_CLIENT_ID_GOOGLE}
      - OIDC_CLIENT_SECRET_GOOGLE=${OIDC_CLIENT_SECRET_GOOGLE}
      - OIDC_REDIRECT_URI_GOOGLE=${OIDC_REDIRECT_URI_GOOGLE}
      - OIDC_PROVIDER_URL_GITHUB=${OIDC_PROVIDER_URL_GITHUB}
      - OIDC_CLIENT_ID_GITHUB=${OIDC_CLIENT_ID_GITHUB}
      - OIDC_CLIENT_SECRET_GITHUB=${OIDC_CLIENT_SECRET_GITHUB}
      - OIDC_REDIRECT_URI_GITHUB=${OIDC_REDIRECT_URI_GITHUB}
      - OIDC_PROVIDER_URL_MICROSOFT=${OIDC_PROVIDER_URL_MICROSOFT}
      - OIDC_CLIENT_ID_MICROSOFT=${OIDC_CLIENT_ID_MICROSOFT}
      - OIDC_CLIENT_SECRET_MICROSOFT=${OIDC_CLIENT_SECRET_MICROSOFT}
      - OIDC_REDIRECT_URI_MICROSOFT=${OIDC_REDIRECT_URI_MICROSOFT}
      - GOOGLE_SERVICE_ACCOUNT_EMAIL=${GOOGLE_SERVICE_ACCOUNT_EMAIL}
      - GOOGLE_PRIVATE_KEY=${GOOGLE_PRIVATE_KEY}
      - API_JWT_SECRET=${API_JWT_SECRET}
      - SESSION_SECRET=${SESSION_SECRET}
      - SMARTME_KEY=${SMARTME_KEY}
      
networks:
  default:
    name: npm-bridge



POSTGRES_PASSWORD=Passw0rd
APP_DOMAIN=sensorcentral.heisterberg.dk
OIDC_PROVIDER_URL_GOOGLE=https://accounts.google.com
OIDC_CLIENT_ID_GOOGLE=800552357999-rq6jmbtgjedaivkn5snapc70g1jchjdi.apps.googleusercontent.com
OIDC_CLIENT_SECRET_GOOGLE=DFl1Ds...mGFORY
OIDC_REDIRECT_URI_GOOGLE=https://sensorcentral.heisterberg.dk/openid/callback/google
GOOGLE_SERVICE_ACCOUNT_EMAIL=sensorcentral-serv-acc-dev@directions-displ-1546933269991.iam.gserviceaccount.com
GOOGLE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nMIIEvg....VdAUHzZ+\n-----END PRIVATE KEY-----
API_JWT_SECRET=fGgiHY...wrujXkoO
SESSION_SECRET=Z5zhQ...hbisz
PWD=/home/lekkim/sensorcentral-docker
POSTGRES_USER=sensorcentral
SMARTME_KEY=ZpFH...RYI7n
DATABASE_ALLOW_SCHEMA_UPGRADE=1
LOG_LEVEL_LOGGERS=HTTP-REQUEST=WARN,HTTP-RESPONSE=WARN,queue-service=INFO,data=INFO
OIDC_PROVIDER_URL_GITHUB=
OIDC_CLIENT_ID_GITHUB=Ov23...HDT
OIDC_CLIENT_SECRET_GITHUB=556...95f
OIDC_REDIRECT_URI_GITHUB=https://sensorcentral.heisterberg.dk/openid/callback/github
OIDC_REDIRECT_URI_MICROSOFT=https://sensorcentral.heisterberg.dk/openid/callback/microsoft
OIDC_CLIENT_SECRET_MICROSOFT=d~g8...OaKE
OIDC_CLIENT_ID_MICROSOFT=522f4fe2-7942-41cf-8965-58a3fd2535f6
OIDC_PROVIDER_URL_MICROSOFT=https://login.microsoftonline.com/common/v2.0
ADMIN_USERNAME=admin
ADMIN_PASSWORD=7Yo...!5Cc

# to restore the database stop the sensorcentral and postgres containers, remove the postgres directory (/opt/docker-volumes/postgres) and recreate it 
# restore the database
psql -X sensorcentral -h localhost -U sensorcentral < /tmp/sensorcentral-backup-20250805T1017.dump


# backup database (-Fc compresses the backup) over tailscale
pg_dump -h sensorcentral-2025 -U sensorcentral -d sensorcentral -Fc > sensorcentral-backup-20250805T1043.dump


```



## Running ##
```
#!/bin/bash

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






