# Submit the CA cert to the PKI engine
# vault_pki_secret_backend_intermediate_set_signed
resource "vault_pki_secret_backend_intermediate_set_signed" "intCA1_signed_cert" {
  depends_on = [null_resource.extract_and_sign]
  backend      = vault_mount.intermediate_ca1.path
  certificate = file("${path.module}/${local.cacert_path}")
}

resource "vault_mount" "intermediate_ca2" {
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intCA1_signed_cert]
  path                      = "${var.server_cert_domain}/intCA2"
  type                      = "pki"
  description               = "PKI engine hosting intermediate CA2 for ${var.cert_organization} org's domain ${var.server_cert_domain}"
  default_lease_ttl_seconds = local.default_1d_in_sec
  max_lease_ttl_seconds     = local.default_3y_in_sec
}

# Generate a new private key and a Certificate Signing Request for signing the PKI Secret Backend.
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_cert_request
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_ca2_csr" {
  depends_on   = [vault_mount.intermediate_ca2]
  backend      = vault_mount.intermediate_ca2.path
  type         = "internal"
  common_name  = local.ca2_common_name
  key_type     = "rsa"
  key_bits     = "2048"
  ou           = var.cert_ou
  organization = var.cert_organization
  country      = var.cert_country
  locality     = var.cert_locality
  province     = var.cert_province
}

# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_root_sign_intermediate
resource "vault_pki_secret_backend_root_sign_intermediate" "intCA2_signed_cert" {
  depends_on = [
    vault_mount.intermediate_ca1,
    vault_pki_secret_backend_intermediate_cert_request.intermediate_ca2_csr,
  ]
  backend              = vault_mount.intermediate_ca1.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate_ca2_csr.csr
  common_name          = local.ca2_common_name
  exclude_cn_from_sans = true
  ou                   = var.cert_ou
  organization         = var.cert_organization
  country              = var.cert_country
  locality             = var.cert_locality
  province             = var.cert_province
  max_path_length      = 5
  ttl                  = local.default_10y_in_sec
}



# Submit the CA cert to the PKI engine
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_set_signed
resource "vault_pki_secret_backend_intermediate_set_signed" "intCA2_signed_cert" {
  depends_on  = [vault_pki_secret_backend_root_sign_intermediate.intCA2_signed_cert]
  backend     = vault_mount.intermediate_ca2.path
  certificate = format("%s\n%s", vault_pki_secret_backend_root_sign_intermediate.intCA2_signed_cert.certificate, file("${path.module}/${local.cacert_path}"))
}

output "intermediate_ca2_cert" {
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intCA2_signed_cert]
  value = vault_pki_secret_backend_intermediate_set_signed.intCA2_signed_cert.certificate
}

resource "null_resource" "write_intCA2" {
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intCA2_signed_cert]
  provisioner "local-exec"{
    command = "cat ${vault_pki_secret_backend_intermediate_set_signed.intCA2_signed_cert.certificate} > cacerts/${var.server_cert_domain}IntCA2.crt"
  }
}
# Create a role for the PKI Secret Engine in order to generate SSL certs.
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_role
resource "vault_pki_secret_backend_role" "role" {
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.intCA2_signed_cert]
  backend            = vault_mount.intermediate_ca2.path
  name               = "${var.server_cert_domain}-subdomain"
  ttl                = local.default_1y_in_sec
  allow_ip_sans      = true
  key_type           = "rsa"
  key_bits           = 2048
  key_usage          = [ "DigitalSignature"]
  allow_any_name     = true
  allow_localhost    = true
  allowed_domains    = [var.server_cert_domain, "localhost", "*.home", "*.home-lab.consul" ]
  allow_bare_domains = true
  allow_subdomains   = true
  server_flag        = true
  client_flag        = true
  no_store           = true
  country            = [var.cert_country]
  locality           = [var.cert_locality]
  province           = [var.cert_province]
}