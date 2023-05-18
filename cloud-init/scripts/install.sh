#!/bin/bash
set -x
# Remember - IP_ADDR=$(curl ifconfig.me)
IP_ADDR=$(ip a | grep enp0s1 | awk -v RS='([0-9]+\\.){3}[0-9]+' 'RT{print RT}' | head -n 1)
HOSTNAME=$(hostname)

echo "Launching Postgres container.."
# Install postgres containers, wait until they are in a running state, then pull their info for Boundary DB connection
./postgres-install.sh
until [[ $NEW_POD_STATE == "Running" ]]
do
  NEW_POD_STATE=$(kubectl get pod $MY_POD | awk 'FNR==2{printf $3}')
  echo "Not running: $NEW_POD_STATE"
  sleep 1
done

MY_POD=$(kubectl get pods | grep -m1 postgres |  awk '{printf $1}')
POD_IP=$(kubectl get pod $MY_POD -o jsonpath='{.status.podIP}')

echo "----------------------"
echo "$MY_POD now in $NEW_POD_STATE with IP $POD_IP - We are ready to continue with Boundary configuration.."
echo "----------------------"
sleep 1

read -p "Enter Boundary license key: " BOUNDARY_LICENSE
echo $BOUNDARY_LICENSE > /home/ubuntu/license.hclic

sudo openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out boundarycert.crt -keyout boundarycert.key -subj "/C=AU/ST=Melbourne/L=Melbourne/O=Hashicorp/OU=Vault Support Engineering/CN=${IP_ADDR}" -addext "subjectAltName = DNS:${HOSTNAME}, DNS:localhost, DNS:${IP_ADDR}, DNS:${POD_IP}, DNS:127.0.0.1"
sudo mkdir /opt/boundary
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
      url = "postgresql://boundary:password@${POD_IP}:5432/boundary"
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

pass init conor
sudo mkdir -p /opt/boundary/certs
sudo chown boundary:boundary /usr/local/bin/boundary
sudo cp /home/ubuntu/license.hclic /opt/boundary/ 
sudo cp boundarycert.* /opt/boundary/certs
sudo cp boundarycert.crt /usr/local/share/ca-certificates/
sudo chown -R boundary:boundary /opt/boundary
sudo update-ca-certificates

echo " -----------------------------------------------------------------"
echo "|                Start testing database_init.sh now              |"
echo " -----------------------------------------------------------------"

# Initialize the database
# psql -h 10.42.0.84 -U boundary -W + password defined in config file to log in
# `\l` to verify databases
./database-init.sh

echo "Database initialized! To connect: "
echo "psql -h $POD_IP -U boundary -w"

sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service
sudo systemctl enable boundary-worker.service
sudo systemctl start boundary-worker.service

echo "Remember to export BOUNDARY_ADDR=https://localhost:9200, etc"
echo "For keyring errors, generate a key with <gpg --full-generate-key>, followed by <pass init USER-ID-FROM-GPG>"

export PASSWORD=$(cat database_login_role_info.txt  | grep -A 7 "Initial auth information")

echo "export BOUNDARY_ADDR=https://localhost:9200"

echo "boundary login & follow the prompts rather than logging in with the entire string"

printf "###########################################\nlogin info: \n\n$PASSWORD\n###########################################\n"