
#Some local variables to make coding simpler.
locals {
  default_10y_in_sec   = 315360000
  default_3y_in_sec   = 94607700
  default_2y_in_sec   = 63072000
  default_1y_in_sec   = 31536000
  default_1d_in_sec   = 86400
  default_1hr_in_sec  = 3600

  root_common_name = "${var.cert_organization} ${var.server_cert_domain} Root CA"
  root_ca_file = "out/${var.cert_organization}_${var.server_cert_domain}_Root_CA.crt"
  csr_path = "csr/IntCA1.csr"
  cacert_path = "cacerts/${var.server_cert_domain}IntCA1.crt"
  ca1_common_name = "${var.cert_organization} ${var.server_cert_domain} Intermediate CA1"
  ca2_common_name = "${var.cert_organization} ${var.server_cert_domain} Intermediate CA2"
  int_ca1_file = "out/${var.cert_organization}_${var.server_cert_domain}_Intermediate_CA1.crt"
}

