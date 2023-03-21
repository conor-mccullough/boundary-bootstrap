#!/bin/bash
# Installs the boundary as a service for systemd on linux
# Usage: ./install.sh <worker|controller>

TYPE=$1
NAME=boundary



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

