resource "null_resource" "create_offline_CA" {
  provisioner "local-exec" {
    command = "mkdir -p out;certstrap init --expires \"${var.ca_expiry_length}\" -o \"${var.cert_organization}\" --ou \"${var.cert_ou}\" -c \"${var.cert_country}\" --cn \"${local.root_common_name}\"  --exclude-path-length --passphrase \"${var.cert_passphrase}\""
  }
}

# Create a PKI secrets engine for the Intermediate Certificate Authority.
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount
resource "vault_mount" "intermediate_ca1" {
  depends_on = [null_resource.create_offline_CA]
  path                      = "${var.server_cert_domain}/intCA1"
  type                      = "pki"
  description               = "PKI engine hosting intermediate CA1 for ${var.cert_organization} org's domain ${var.server_cert_domain}"
  default_lease_ttl_seconds = local.default_1d_in_sec
  max_lease_ttl_seconds     = local.default_3y_in_sec
}

# Generate a new private key and a CSR for signing the PKI Secret Backend.
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_cert_request
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_ca1" {
  depends_on   = [vault_mount.intermediate_ca1]
  backend      = vault_mount.intermediate_ca1.path
  type         = "internal"
  common_name  = local.ca1_common_name
  key_type     = "rsa"
  key_bits     = "2048"
  ou           = var.cert_ou
  organization = var.cert_organization
  country      = var.cert_country
  locality     = var.cert_locality
  province     = var.cert_province
}

# Generates the certificate endpoints, the content revocation lists (CRLs) that will be encoded into issued certs.
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_config_urls
resource "vault_pki_secret_backend_config_urls" "intermediate_ca1" {
  backend = vault_mount.intermediate_ca1.path
  issuing_certificates = ["${var.vault_url}/${vault_mount.intermediate_ca1.path}/ca"]
  crl_distribution_points = ["${var.vault_url}/${vault_mount.intermediate_ca1.path}}/crl"]
}

resource "null_resource" "extract_and_sign" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.intermediate_ca1]

  # Pull the CSR out of TF state
  provisioner "local-exec" {
    command = "mkdir -p csr;terraform show -json |jq '.values[\"root_module\"][\"resources\"][].values.csr' -r | grep -v null > ${local.csr_path}"
  }

  # Sign the CSR with the offline Root CA
  provisioner "local-exec" {
    command = "certstrap sign --expires \"${var.ca_expiry_length}\" --csr ${local.csr_path} --cert ${local.root_ca_file} --intermediate --CA \"${local.root_common_name}\" --path-length 5 \"${local.ca1_common_name}\" --passphrase \"${var.cert_passphrase}\" --stdout > ${local.int_ca1_file}"
  }

  # Place signed Intermediate CA cert into the cacerts directory
  provisioner "local-exec" {
    command = "mkdir -p cacerts;cat ${local.int_ca1_file} ${local.root_ca_file} > ${local.cacert_path}"
  }

  # Copy the CA Root to the cacerts folder
  provisioner "local-exec" {
    command = "cp ${local.root_ca_file} cacerts/.; cp out/${var.cert_organization}_${var.server_cert_domain}_Root_CA.key cacerts/."
  }

  # Copy the next step into this directory
  provisioner "local-exec" {
    command = "cp next-steps/tls2.tf ."
  }
}

resource "null_resource" "clean_up"{
    provisioner "local-exec" {
      command = "rm -f out/*;rm -f csr/*;rm -f cacerts/*;rm tls2.tf"
      when = destroy
    }
}