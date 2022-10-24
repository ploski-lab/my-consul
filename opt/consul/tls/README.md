# Setup

You will need to download and/or compile these tools:
- certstrap
- tree

### Step 1: Create an offline Root CA
If you want to keep some control over your domain, you will want to create your CA offline and save the key.
(You can create a CA within Vault, but you'll not be able to retrieve you private key.) The recommendation is to 
create your primary CA offline and then build out your Intermediate CA's via Terraform and Vault.

To create your CA offline, it's suggested that you use `certstrap`. Here are the steps to get certstrap:


While trying to compile certstrap, I got random errors compiling as my distro had old golang binaries. Here's are the steps that I took to update my outdated go packages
https://github.com/square/certstrap

Once compiled, here is command to create the disconnected Certificate Authority:
<pre><code> certstrap init \
  --organization "YOUR_ORG" \
  --organizational-unit "YOUR_ORG_UNIT" \
  --country "US" \
  --province "MA" \
  --locality "Newton" \
  --common-name "YOUR_DOMAIN" \
  --expires "10 years" \
  --exclude-path-length
</code></pre>

Once completed, check to make certain everything is copacetic:
<pre><code>openssl x509 -in out/YOUR_DOMAIN.crt -noout -subject -issuer
</code></pre>

**Side Note:** It's a really, **really bad** idea to keep these kind of credentials lying around. It's best to create them
as a root user and store them very carefully.

### Step 2 Create the Intermediate CA1
Create the Intermediate Certificate Authority via Terraform
<pre><code>export VAULT_ADDR=http://YOUR_VAULT_SERVER:8200
export VAULT_TOKEN=YOUR_VAULT_TOKEN
terrafom plan
terraform apply</code></pre>

### Step 3 Get the CSR
Create a new folder named CSR
Get the Certificate Signing Request from the Terraform state file.
<pre><code>terraform show -json |jq '.values["root_module"]["resources"][].values.csr' -r | grep -v null > csr/IntCA1.csr
</code></pre>

### Step 4 Sign the ICA CSR
<pre><code>certstrap sign \
 --expires "3 year" \
 --csr csr/IntCA1.csr \
 --cert out/IntermediateCA1.crt \
 --intermediate \
 --CA "YOUR_DOMAIN_HERE DOMAIN_HERE Intermediate CA1" \
 --path-length 5 \
 "Intermediate CA1"
Enter passphrase for CA key (empty for no passphrase): 
Building intermediate
Created out/Intermediate_CA1.crt from out/Intermediate_CA1.csr signed by out/home.key
</code></pre>


### Step 5 Create a CA Chain
Append the offline Root CA at the end of the Intermediate CA1 to create a CA chain.
We use this to set the signed ICA1 in Vault
<pre><code>cat out/IntermediateCA1.crt out/YOUR_DOMAIN.crt > cacerts/YOUR_DOMAINIntCA1.crt</code></pre>

### Step 6 Update Vault with the Signed Intermediate CA
Copy zzz-Step6-intCA1_signed.tf into the main folder. Run terraform apply.
<pre><code>cp StepNext/zzz-Step6-intCA1_signed.tf .
terraform plan
terraform apply
</code></pre>

Verify the CA1 CA chain in Vault
<pre><code>curl -s $VAULT_ADDR/v1/YOUR_CA_DOMAIN/intCA1/ca/pem | openssl crl2pkcs7 -nocrl -certfile /dev/stdin | openssl pkcs7 -print_certs -noout</code></pre>

### Step 7 Generate the Intermediate CA2
Copy zzz-Step7-intCA2.tf to the working directory. Run terraform apply
<pre><code>cp StepNext/zzz-Step7-intCA2.tf .
terraform plan
terraform apply</code></pre>


Verify the output
<pre><code>curl -s $VAULT_ADDR/v1/YOUR_DOMAIN/intCA2/ca/pem | openssl crl2pkcs7 -nocrl -certfile /dev/stdin | openssl pkcs7 -print_certs -noout

curl -s $VAULT_ADDR/v1/home/intCA2/ca/pem | openssl x509 -in /dev/stdin -noout -text | grep "X509v3 extensions" -A 13</code> </pre>

<pre><code>terraform show -json | jq '.values["root_module"]["resources"][5].values.certificate' -r > cacerts/consulIntCA2.crt</code></pre>

### Step 8 Generate a PKI Role rooted in IntCA2




https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_root_sign_intermediate

https://support.dnsimple.com/articles/what-is-common-name/#:~:text=The%20Common%20Name%20(AKA%20CN,common%20name%20in%20the%20certificate.

https://support.dnsimple.com/articles/ssl-certificate-names/