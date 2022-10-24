variable server_cert_domain {
    description = "We create a role to create client certs, what DNS domain will these certs be in"
    default = "mydomain.com"
}
variable client_cert_domain {
    description = "Allowed Domains for Client Cert"
    default = "mydomain.com"
}

variable cert_organization {
    description = "The organization name (corp, limited partnership, university, government agency, etc."
    default = "Acme, Inc."
}

variable cert_ou {
    description = "The organizational unit is the specific division or department within the organization"
    default = "Home Lab"
}

variable cert_country {
    description = "2-character ISO format country code. See www.nationsonline.org/oneworld/country_code_list.htm for a list"
    default = "US"
}

variable cert_locality {
    description = "City in which the organization is located"
    default = "Brigadoon"
}

variable cert_province {
    description = "State or province of the organization"
    default = "Scotland"
}

variable cert_passphrase {
    description = "A secret passphrase for the CA certificate signing"
}