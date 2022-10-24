resource "vault_mount" "intermediate_ca2_mount" {
  path                      = "${var.server_cert_domain}/intCA2"
  type                      = "pki"
  description               = "PKI engine hosting Intermediate CA2 for ${var.cert_organization} org's domain ${var.server_cert_domain}"
  default_lease_ttl_seconds = local.default_1hr_in_sec
  max_lease_ttl_seconds     = 78900000 # 2.5 years
}

# Generate a new private key and a Certificate Signing Request for signing the PKI Secret Backend.
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_cert_request
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_ca2_csr" {
  depends_on   = [vault_mount.intermediate_ca2_mount]
  backend      = vault_mount.intermediate_ca2_mount.path
  type         = "internal"
  common_name  = "${var.cert_organization} Intermediate CA2"
  key_type     = "rsa"
  key_bits     = "2048"
  format       = "pem"
  ou           = "${var.cert_ou}"
  organization = "${var.cert_organization}"
  country      = "${var.cert_country}"
  locality     = "${var.cert_locality}"
  province     = "${var.cert_province}"
}

# Create the PKI certificate
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_root_sign_intermediate
resource "vault_pki_secret_backend_root_sign_intermediate" "signed_intermediate_ca2_by_intermediate_ca1" {
  depends_on = [
    vault_mount.intermediate_ca1,
    vault_pki_secret_backend_intermediate_cert_request.intermediate_ca2_csr,
  ]
  backend              = vault_mount.intermediate_ca1.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate_ca2_csr.csr
  common_name          = "${var.cert_organization} Intermediate CA2"
  exclude_cn_from_sans = true
  ou                   = "${var.cert_ou}"
  organization         = "${var.cert_organization}"
  country              = "${var.cert_country}"
  locality             = "${var.cert_locality}"
  province             = "${var.cert_province}"
  max_path_length      = 1
  ttl                  = local.default_1y_in_sec
}

# Submit the CA cert to the PKI engine
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_set_signed
resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate_ca2_v1_signed_cert" {
  depends_on  = [vault_pki_secret_backend_root_sign_intermediate.signed_intermediate_ca2_by_intermediate_ca1]
  backend     = vault_mount.intermediate_ca2_mount.path
  certificate = format("%s\n%s", vault_pki_secret_backend_root_sign_intermediate.signed_intermediate_ca2_by_intermediate_ca1.certificate, file("${path.module}/cacerts/${var.server_cert_domain}IntCA1.crt"))
}