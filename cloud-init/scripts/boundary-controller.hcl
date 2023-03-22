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
  public_cluster_addr = "<CHANGEME>"
  license = "/opt/boundary/license.hclic"
}
listener "tcp" {
  address = "0.0.0.0"
  purpose = "api"
  tls_cert_file = "/opt/boundary/certs/boundarycert.crt"
  tls_key_file  = "/opt/boundary/certs/boundarycert.key"

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
  tls_cert_file = "/opt/boundary/certs/boundarycert.crt"
  tls_key_file  = "/opt/boundary/certs/boundarycert.key"
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