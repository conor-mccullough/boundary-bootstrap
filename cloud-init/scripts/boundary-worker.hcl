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
    "<CHANGEME>",
    "127.0.0.1"
  ]
  public_addr = "192.168.64.76"
  tags {
    type   = ["prod", "webservers"]
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