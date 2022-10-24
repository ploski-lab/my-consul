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

### Step 2 Create the tls2 from the next-steps directory
Most of the steps were automated but I couldn't get around the lack of an output file.
In the meantime and run terraform apply again.



### Random Notes To Be Cleaned Up
Verify the output
<pre><code>curl -s $VAULT_ADDR/v1/YOUR_DOMAIN/intCA2/ca/pem | openssl crl2pkcs7 -nocrl -certfile /dev/stdin | openssl pkcs7 -print_certs -noout

curl -s $VAULT_ADDR/v1/home/intCA2/ca/pem | openssl x509 -in /dev/stdin -noout -text | grep "X509v3 extensions" -A 13</code> </pre>

<pre><code>terraform show -json | jq '.values["root_module"]["resources"][5].values.certificate' -r > cacerts/consulIntCA2.crt</code></pre>



https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_root_sign_intermediate

https://support.dnsimple.com/articles/what-is-common-name/#:~:text=The%20Common%20Name%20(AKA%20CN,common%20name%20in%20the%20certificate.

https://support.dnsimple.com/articles/ssl-certificate-names/