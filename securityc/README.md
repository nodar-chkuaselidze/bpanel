# resources

https://www.linuxhelp.com/how-to-install-and-update-openssl-on-ubuntu-16-04/

## Dependencies

Mac:

```
$ brew install gettext
$ brew link --force gettext
```

The `gettext` package includes `envsubst`, which is a handy program
for rendering templates with environmental variables.

# Usage

securityc is configured with environmental variables. To properly generate a cert, 4
environmental variables are required. An arbitrary number of certs can be generated,
to properly bundle the inputs per cert, the environmental variables must follow the schema:

```bash
SECURITYC_{APP_NAME}_{ARG_NAME}
```

The prefix `SECURITYC` ensures that there are no collisions with other environmental variables.
The `{APP_NAME}` refers to an application that a cert/private key should be generated for.
The `{ARG_NAME}` refers to an argument that the script needs to generate the cert/private key pair.
The script will be invoked once for each `{APP_NAME}` that has all of the appropriate arguments.

The `{ARG_NAME}`s that must be provided are:

- `CA_COMMON_NAME` - Subject Common Name
- `CERT_CERT_NAME` - Subject Common Name
- `CERT_IP` - X509v3 SAN IP Address
- `CERT_DOMAIN` - X509v3 SAN DNS
- `CA_OUT` - Output file for generated Certificate Authority
- `KEY_OUT` - Output file for generated TLS key
- `CERT_OUT` - Output file for generated + signed TLS cert

An example would look like:

```bash
export SECURITYC_SERVER_CA_COMMON_NAME=bpanel
export SECURITYC_SERVER_CERT_COMMON_NAME=localhost
export SECURITYC_SERVER_CERT_IP=127.0.0.1
export SECURITYC_SERVER_CERT_DOMAIN=localhost
export SECURITYC_SERVER_CA_OUT=/etc/ssl/certs/ca.crt
export SECURITYC_SERVER_KEY_OUT=/etc/nginx/tls.key
export SECURITYC_SERVER_CERT_OUT=/etc/nginx/tls.crt
```

Lets inspect the produced certificates with:
Note, not all of the output is displayed

First up, the Certificate Authority

```
$ openssl x509 -noout -text -in /etc/ssl/certs/ca.crt
```

```
Signature Algorithm: sha256WithRSAEncryption
    Issuer: CN=bpanel
    Validity
        Not Before: Apr 19 18:31:39 2018 GMT
        Not After : Oct 19 18:31:39 2019 GMT
    Subject: CN=bpanel

------- removed for brevity -------------------

    X509v3 extensions:
        X509v3 Key Usage: critical
            Certificate Sign, CRL Sign
        X509v3 Basic Constraints: critical
            CA:TRUE, pathlen:0
```

The value of `SECURITYC_SERVER_CA_COMMON_NAME`
is set as the `Subject CN` and you can see that the certificate is a CA that
can do certificate signing.


Now the requested Certificate

```
$ openssl x509 -noout -text -in /etc/nginx/tls.crt
```

```
Signature Algorithm: sha256WithRSAEncryption
    Issuer: CN=bpanel
    Validity
        Not Before: Apr 19 18:31:44 2018 GMT
        Not After : Oct 19 18:31:38 2019 GMT
    Subject: CN=localhost

------- removed for brevity -------------------

    X509v3 extensions:
        X509v3 Key Usage: critical
            Digital Signature, Key Encipherment, Data Encipherment, Key Agreement
        X509v3 Extended Key Usage:
            TLS Web Server Authentication, TLS Web Client Authentication

------- removed for brevity -------------------

    X509v3 Subject Alternative Name:
        DNS:localhost, IP Address:127.0.0.1
```

The value of `SECURITYC_SERVER_CERT_COMMON_NAME` sets the `Subject CN`, 
`SECURITYC_SERVER_CERT_IP` and `SECURITYC_SERVER_CERT_DOMAIN` set the values
of the `X509v3 Subject Alternative Name` `IP Address` and `DNS` fields
respectively.

