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
      url = "postgresql://boundary:password@127.0.0.1:5432/boundary"
  }
  public_cluster_addr = "boundary.domain"
  license = "/opt/boundary/license.hclic"
}
listener "tcp" {
  address = "0.0.0.0"
  purpose = "api"
  tls_cert_file = "/opt/boundary/certs/server-1.crt"
  tls_key_file  = "/opt/boundary/certs/server-1.key"
 
  # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
  # to appropriate values.
  #cors_enabled = true
  #cors_allowed_origins = ["https://yourcorp.yourdomain.com", "serve://boundary"]
}
# Data-plane listener configuration block (used for worker coordination)
listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "0.0.0.0"
#  address = "${IP_ADDRESS}"
  purpose = "cluster"
}
listener "tcp" {
  # Should be the address of the NIC where your external systems'
  # (eg: Load-Balancer) will connect on.
  address = "0.0.0.0"
  purpose = "ops"
  tls_cert_file = "/opt/boundary/certs/server-1.crt"
  tls_key_file  = "/opt/boundary/certs/server-1.key"
}
kms "awskms" {
  purpose    = "root"
  region     = "$AWS_REGION"
  access_key = "$AWS_KEY_ID"
  secret_key = "$AWS_SECRET"
  kms_key_id = "$KMS_KEY_ID"
}
# Worker authorization KMS
# Use a production KMS such as AWS KMS for production installs
# This key is the same key used in the worker configuration
kms "awskms" {
  purpose = "worker-auth"
  region     = "$AWS_REGION"
  access_key = "$AWS_KEY_ID"
  secret_key = "$AWS_SECRET"
  kms_key_id = "$KMS_KEY_ID"
}
# Recovery KMS block: configures the recovery key for Boundary
# Use a production KMS such as AWS KMS for production installs
kms "awskms" {
  purpose = "recovery"
  region     = "$AWS_REGION"
  access_key = "$AWS_KEY_ID"
  secret_key = "$AWS_SECRET"
  kms_key_id = "$KMS_KEY_ID"
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
