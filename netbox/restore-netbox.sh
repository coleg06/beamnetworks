#!/bin/bash
# Script to restore netbox from backup script
# Still working on it, but it's close to working.

sudo wget https://{SOURCEURLREDACTED}/netbox-full-backup.zip

unzip netbox-full-backup.zip

sudo rm netbox-full-backup.zip

cd netbox-backup

sudo docker image load -i netbox-full.tar

netbox1=$(cat image1)
netbox2=$(cat image2)
netbox3=$(cat image3)
netbox4=$(cat image4)
netbox5=$(cat image5)
netbox6=$(cat image6)

sudo mv netbox-docker ~

cd ~

sudo rm -rf netbox-backup

cd netbox-docker

sudo docker tag $netbox1 beamnetworks-netbox/netbox1
sudo docker tag $netbox2 beamnetworks-netbox/netbox2
sudo docker tag $netbox3 beamnetworks-netbox/netbox3
sudo docker tag $netbox4 beamnetworks-netbox/netbox4
sudo docker tag $netbox5 beamnetworks-netbox/netbox5
sudo docker tag $netbox6 beamnetworks-netbox/netbox6

sudo mv docker-compose.yml docker-compose-backup-netbox.yml

cat << EOF > docker-compose.yml
version: '3.4'
services:
  netbox:
    image: beamnetworks-netbox/netbox1
    depends_on:
    - postgres
    - redis
    - redis-cache
    - netbox-worker
    env_file: env/netbox.env
    user: 'unit:root'
    volumes:
    - ./configuration:/etc/netbox/config:z,ro
    - ./reports:/etc/netbox/reports:z,ro
    - ./scripts:/etc/netbox/scripts:z,ro
    - netbox-media-files:/opt/netbox/netbox/media:z
  netbox-worker:
    image: beamnetworks-netbox/netbox2
    depends_on:
    - redis
    - postgres
    command:
    - /opt/netbox/venv/bin/python
    - /opt/netbox/netbox/manage.py
    - rqworker
  netbox-housekeeping:
    image: beamnetworks-netbox/netbox3
    depends_on:
    - redis
    - postgres
    command:
    - /opt/netbox/housekeeping.sh

  # postgres
  postgres:
    image: beamnetworks-netbox/netbox4
    env_file: env/postgres.env
    volumes:
    - netbox-postgres-data:/var/lib/postgresql/data

  # redis
  redis:
    image: beamnetworks-netbox/netbox5
    command:
    - sh
    - -c # this is to evaluate the $REDIS_PASSWORD from the env
    - redis-server --appendonly yes --requirepass $$REDIS_PASSWORD ## $$ because of docker-compose
    env_file: env/redis.env
    volumes:
    - netbox-redis-data:/data
  redis-cache:
    image: beamnetworks-netbox/netbox6
    command:
    - sh
    - -c # this is to evaluate the $REDIS_PASSWORD from the env
    - redis-server --requirepass $$REDIS_PASSWORD ## $$ because of docker-compose
    env_file: env/redis-cache.env

volumes:
  netbox-media-files:
    driver: local
  netbox-postgres-data:
    driver: local
  netbox-redis-data:
    driver: local
EOF
