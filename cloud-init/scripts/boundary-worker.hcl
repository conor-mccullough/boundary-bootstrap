listener "tcp" {
    purpose = "proxy"
    tls_disable = true
    address = "127.0.0.1"
}
worker {
  # Name attr must be unique across workers
  name = "${HOST}"
  description = "A default worker created for testing"
  # Workers must be able to reach upstreams on :9201
  initial_upstreams = [
    "10.100.2.11",
    "10.100.2.12"
  ]
  public_addr = "myhost.mycompany.com"
  tags {
    type   = ["prod", "webservers"]
    region = ["local"]
  }
}
# must be same key as used on controller config
kms "awskms" {
    purpose = "worker-auth"
    region     = "$AWS_REGION"
    access_key = "$AWS_KEY_ID"
    secret_key = "$AWS_SECRET"
    kms_key_id = "$KMS_KEY_ID"
}