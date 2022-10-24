# Full configuration options can be found at https://www.consul.io/docs/agent/config

# datacenter
# This flag controls the datacenter in which the agent is running. If not provided,
# it defaults to "dc1". Consul has first-class support for multiple datacenters, but
# it relies on proper configuration. Nodes in the same datacenter should be on a
# single LAN.
datacenter = "home-lab"

# data_dir
# This flag provides a data directory for the agent to store state. This is required
# for all agents. The directory should be durable across reboots. This is especially
# critical for agents that are running in server mode as they must be able to persist
# cluster state. Additionally, the directory must support the use of filesystem
# locking, meaning some types of mounted folders (e.g. VirtualBox shared folders) may
# not be suitable.
data_dir = "/opt/consul"

# client_addr
# The address to which Consul will bind client interfaces, including the HTTP and DNS
# servers. By default, this is "127.0.0.1", allowing only loopback connections. In
# Consul 1.0 and later this can be set to a space-separated list of addresses to bind
# to, or a go-sockaddr template that can potentially resolve to multiple addresses.
client_addr = "0.0.0.0"

# server
# This flag is used to control if an agent is in server or client mode. When provided,
# an agent will act as a Consul server. Each Consul cluster must have at least one
# server and ideally no more than 5 per datacenter. All servers participate in the Raft
# consensus algorithm to ensure that transactions occur in a consistent, linearizable
# manner. Transactions modify cluster state, which is maintained on all server nodes to
# ensure availability in the case of node failure. Server nodes also participate in a
# WAN gossip pool with server nodes in other datacenters. Servers act as gateways to
# other datacenters and forward traffic as appropriate.
server = true

# Bind addr
# You may use IPv4 or IPv6 but if you have multiple interfaces you must be explicit.
#bind_addr = "[::]" # Listen on all IPv6
bind_addr = "0.0.0.0" # Listen on all IPv4

# Enterprise License
# As of 1.10, Enterprise requires a license_path and does not have a short trial.
license_path="/etc/consul.d/consul.hclic"

# bootstrap_expect
# This flag provides the number of expected servers in the datacenter. Either this value
# should not be provided or the value must agree with other servers in the cluster. When
# provided, Consul waits until the specified number of servers are available and then
# bootstraps the cluster. This allows an initial leader to be elected automatically.
# This cannot be used in conjunction with the legacy -bootstrap flag. This flag requires
# -server mode.
bootstrap_expect=1

# encrypt
# https://developer.hashicorp.com/consul/tutorials/security/gossip-encryption-secure
# Specifies the secret key to use for encryption of Consul network traffic. This key must
# be 32-bytes that are Base64-encoded. The easiest way to create an encryption key is to
# use consul keygen. All nodes within a cluster must share the same encryption key to
# communicate. The provided key is automatically persisted to the data directory and loaded
# automatically whenever the agent is restarted. This means that to encrypt Consul's gossip
# protocol, this option only needs to be provided once on each agent's initial startup
# sequence. If it is provided after Consul has been initialized with an encryption key,
# then the provided key is ignored and a warning will be displayed.
encrypt = "YOUR_ENCRYPT_KEYGEN"
encrypt_verify_outgoing = true


alt_domain="home"
acl_datacenter="home-lab"
#acl_default_policy="allow"
acl = {
  enabled = false
  default_policy="allow"
  enable_token_persistence = true
  enable_token_replication = true
  tokens {
  agent = "YOUR_TOKEN"
  }
}

# Use Consul Connect for Service Mesh
# https://developer.hashicorp.com/consul/docs/agent/config/config-files#connect-parameters
connect {
  # Controls whether Connect features are enabled on this agent. Should be enabled on all servers in the cluster in order for Connect to function properly.
  enabled = true
  # Controls which CA provider to use for Connect's CA. Currently only the aws-pca, consul, and vault providers are supported. This is only used when initially bootstrapping the cluster.
  ca_provider = "vault"
  ca_config{
    address = "https://127.0.0.1:8200"
    token = "BLAH_TOKEN"
    root_pki_path = "consul/intCA1"
    intermediate_pki_path = "consul/intCA2"
  }
}

auto_encrypt {
  allow_tls = true
}

tls {
  defaults {
    tls_min_version = "TLSv1_2"
    verify_outgoing = true
    verify_incoming = true
    ca_file = "/usr/local/share/ca-certificates/home.crt"
    cert_file = "/opt/consul/tls/mars.consul.crt"
    key_file = "/opt/consul/tls/mars.consul.key"
  }

  #internal_rpc {
  #  verify_server_hostname = true
  #}
}

ports {
  http  = 8500
  https = 8501
  grpc  = 8502
}
