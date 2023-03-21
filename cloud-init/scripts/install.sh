#!/bin/bash

# Remember - MY_IP=$(curl ifconfig.me)

#MY_IP=$(curl ifconfig.me)
#export VAULT_ADDR='http://127.0.0.1:8200'
#echo 'export VAULT_ADDR=http://127.0.0.1:8200' >> /home/ubuntu/.bashrc
#echo "MY_IP=$(curl ifconfig.me)" >> /home/ubuntu/.bashrc
#source /home/ubuntu/.bashrc


sudo cp -r /home/ubuntu/*.hc* /opt/boundary/

sudo chown -R boundary:boundary /opt/boundary

# Make sure to initialize the DB before starting the service. This will result in
# a database already initialized warning if another controller or worker has done this
# already, making it a lazy, best effort initialization
#if [ "${TYPE}" = "controller" ]; then
#  sudo /usr/local/bin/boundary database init -config /etc/${NAME}-${TYPE}.hcl || true
#fi

#sudo chmod 664 /etc/systemd/system/${NAME}-${TYPE}.service
sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service
sudo systemctl enable boundary-worker.service
sudo systemctl start boundary]-worker.service

