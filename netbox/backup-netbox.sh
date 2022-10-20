#!/bin/bash
# Work in progress script to backup netbox.
# This script is for the source docker host.


mkdir netbox-backup

netbox1=$(sudo docker container commit netbox-docker_netbox_1)
netbox2=$(sudo docker container commit netbox-docker_netbox-worker_1)
netbox3=$(sudo docker container commit netbox-docker_netbox-housekeeping_1)
netbox4=$(sudo docker container commit netbox-docker_postgres_1)
netbox5=$(sudo docker container commit netbox-docker_redis-cache_1)
netbox6=$(sudo docker container commit netbox-docker_redis_1)

sudo docker image save -o netbox-full.tar \
$netbox1 \
$netbox2 \
$netbox3 \
$netbox4 \
$netbox5 \
$netbox6

mv netbox-full.tar netbox-backup/

echo $netbox1 > netbox-backup/image1
echo $netbox2 > netbox-backup/image2
echo $netbox3 > netbox-backup/image3
echo $netbox4 > netbox-backup/image4
echo $netbox5 > netbox-backup/image5
echo $netbox6 > netbox-backup/image6

sudo docker image rm $netbox1 $netbox2 $netbox3 $netbox4 $netbox5 $netbox6

sudo cp -r netbox-docker netbox-backup/

sudo zip -r netbox-full-backup.zip netbox-backup/

sudo rm -rf netbox-backup

sudo mv netbox-full-backup.zip /usr/share/nginx/html/host/
sudo chown www-data /usr/share/nginx/html/host/netbox-full-backup.zip
