# Synology Container Manager - OpenBao Server Configuration
# /volume1/docker/openbao/config/bao.hcl

ui = true
disable_mlock = true

storage "file" {
  path = "/openbao/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1 # Terminated at Synology reverse proxy / Cloudflare Tunnel
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

default_lease_ttl = "168h"
max_lease_ttl     = "720h"
