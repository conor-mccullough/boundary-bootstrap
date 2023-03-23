#!/bin/bash


# sudo journalctl -u boundary

# Remember - MY_IP=$(curl ifconfig.me)

# Take off here from the k3s psql install script

sudo openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out boundarycert.crt -keyout boundarycert.key -subj '/C=AU/ST=Melbourne/L=Melbourne/O=Hashicorp/OU=Vault Support Engineering/CN=localhost' -addext 'subjectAltName = DNS:$(hostname)'

sudo mkdir /opt/boundary/certs
sudo chown boundary:boundary /usr/local/bin/boundary
sudo cp /home/ubuntu/license.hclic /opt/boundary/ && sudo cp boundary*hcl /opt/boundary
sudo cp boundarycert.* /opt/boundary/certs
sudo chown -R boundary:boundary /opt/boundary

./database_init.sh

sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service
sudo systemctl enable boundary-worker.service
sudo systemctl start boundary-worker.service

echo "Remember to export BOUNDARY_ADDR=https://127.0.0.1:9200, etc"