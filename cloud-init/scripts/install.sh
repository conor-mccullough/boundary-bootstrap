#!/bin/bash

# Remember - IP_ADDR=$(curl ifconfig.me)
IP_ADDR=$(ip a | grep enp0s1 | awk -v RS='([0-9]+\\.){3}[0-9]+' 'RT{print RT}' | head -n 1)
HOSTNAME=$(hostname)

sudo openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out boundarycert.crt -keyout boundarycert.key -subj '/C=AU/ST=Melbourne/L=Melbourne/O=Hashicorp/OU=Vault Support Engineering/CN=localhost' -addext "subjectAltName = DNS:${HOSTNAME}"

sudo tee /opt/boundary/boundary-controller.hcl << EOF

controller {
  # This name attr must be unique across all controller instances if running in HA mode
  name = "controller-1"
  description = "controller-1"

  graceful_shutdown_wait_duration = "10s"

  # Database URL for postgres. This can be a direct "postgres://"
  # URL, or it can be "file://" to read the contents of a file to
  # supply the url, or "env://" to name an environment variable
  # that contains the URL.
  database {
      url = "postgresql://boundary:password@10.43.75.28:5432/boundary"
  }
  public_cluster_addr = "${IP_ADDR}"
  license = "file:///opt/boundary/license.hclic"
}

listener "tcp" {
  address = "0.0.0.0:9200"
  purpose = "api"
  tls_cert_file = "/opt/boundary/certs/boundarycert.crt"
  tls_key_file  = "/opt/boundary/certs/boundarycert.key"
}

# Data-plane listener configuration block (used for worker coordination)
listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "${IP_ADDR}:9201"
  purpose = "cluster"
}

kms "aead" {
    purpose   = "root"
    aead_type = "aes-gcm"
    key       = "sP1fnF5Xz85RrXyELHFeZg9Ad2qt4Z4bgNHVGtD6ung="
    key_id    = "global_root"
}
kms "aead" {
    purpose   = "worker-auth"
    aead_type = "aes-gcm"
    key       = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
    key_id    = "global_worker-auth"
}
kms "aead" {
    purpose   = "recovery"
    aead_type = "aes-gcm"
    key       = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
    key_id    = "global_recovery"
}

events {
  observations_enabled = true
  sysevents_enabled = true
  sink "stderr" {
    name = "all-events"
    description = "All events sent to stderr"
    event_types = ["*"]
    format = "hclog-text"
  }
}

EOF

sudo tee /opt/boundary/boundary-worker.hcl << EOF
listener "tcp" {
    purpose = "proxy"
    tls_disable = true
    address = "127.0.0.1"
}

worker {
  # Name attr must be unique across workers
  name = "worker-1"
  description = "A default worker created for testing"
  # Workers must be able to reach upstreams on :9201
  initial_upstreams = [
    "${IP_ADDR}",
    "127.0.0.1"
  ]
  public_addr = "${IP_ADDR}"
  tags {
    type   = ["test", "testservers"]
    region = ["local"]
  }
}

# must be same key as used on controller config
kms "aead" {
    purpose   = "worker-auth"
    aead_type = "aes-gcm"
    key       = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
    key_id    = "global_worker-auth"
}

EOF

# Take off here from the k3s psql install script
./postgres-install.sh

sudo mkdir -p /opt/boundary/certs
sudo chown boundary:boundary /usr/local/bin/boundary
sudo cp /home/ubuntu/license.hclic /opt/boundary/ 
sudo cp boundarycert.* /opt/boundary/certs
sudo chown -R boundary:boundary /opt/boundary

echo " -----------------------------------------------------------------"
echo "|                Start testing database_init.sh now               |"
echo " -----------------------------------------------------------------"


./database-init.sh

sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service
sudo systemctl enable boundary-worker.service
sudo systemctl start boundary-worker.service

echo "Remember to export BOUNDARY_ADDR=https://127.0.0.1:9200, etc"