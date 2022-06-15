# Membuat self sign certificate dan  menjadi Certificate Authority CA lokal untuk lokal development

### reference
- <https://www.ssl.com/faqs/what-is-a-certificate-authority/>
- <https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/>

## prerequisite
- sudah terinstall openssl
- [cara install OpenSSL di Windows]()

## menjadi CA (lokal)

- untuk menjadi CA lokal caranya cukup mudah,
- generate key dan generate certificate
- kemudian sign request menggunakan cert dan key CA

## generate private key untuk CA

``` shell
openssl genrsa -des3 -out starganCA.key 2048
```
passphrase : 12345678 # ganti dengan yang lebih aman

## generate root certificate

``` shell
openssl req -x509 -new -nodes -key starganCA.key -days 3650 -out starganCA.pem -config starganCA.cnf
```

untuk memudahkan kita akan membuat file config

``` config
[ req ]
default_bits       = 4096
default_md         = sha512
default_keyfile    = starganCA.pem
prompt             = no
encrypt_key        = yes

# base request
distinguished_name = req_distinguished_name

# distinguished_name
[ req_distinguished_name ]
countryName            = "ID"                     # C=
stateOrProvinceName    = "DKI Jakarta"                 # ST=
localityName           = "Jakarta"                 # L=
postalCode             = "10110"                 # L/postalcode=
streetAddress          = "Merdeka"            # L/street=
organizationName       = "StarganCA"        # O=
organizationalUnitName = "Departemen Keamanan"          # OU=
commonName             = "ca.stargan.local"            # CN=
emailAddress           = "webmaster@stargan.local"  # CN/emailAddress=
```

## Install root CA
untuk menjadi CA sebenernya, kita perlu mempublish roo certificate kita ke semua device di dunia

tetapi, untuk lokal development kita hanya perlu menginstall certificate kita di device lokal kita

### windows
1. Windows + R
2. ketikkan mmc
3. klik __File > Add/Remove Snap-in__
4. pilih __Certificate__ klik __Add__
5. pilih __Computer Account__ klik __Next__
6. pilih __Local Computer__ kemudian klik __Finish__
7. klik __OK__ dan kembali ke jendela __MMC__
8. dobel klik __Certificates (local computer)__
9. pilih __Trusted Root Certification Authorities__ , klik kanan __Certificates__ dikolom sebelah kanan, pilih __All Tasks__ kemudian __Import__
10. klik __Next__ kemudian __Browse__ , ubah dropdow certificate extension ke __All Files (\*.*)__ kemudian cari lokasi starganCA.pem , klik __Open__ dan __Next__
11. pilih __Place all certificates in the following store__ di ```Trusted Root Certification Authorities store``` . klik __Next__ dan __Finish__

jika semua lancar seharusnya kita sudah bs melihat certificate kita di bawah
__Trusted Root Certification Authorities > Certificates__

## Membuat Certificate untuk lokal dev yang di __sign__ oleh lokal CA

Karena kita sekarang sudah menjadi CA untuk diri sendiri, maka kita dapat mengsign certificate yang kita perlukan untuk development machine kita

### generate key
membuat key untuk dev site misalkan lokal kita adalah stargan.local untuk memudahkan mengingat kita akan buat penamaan key sesuai dengan domain site kita

  ``` shell
  openssl genrsa -out stargan.local.key -aes256
  ```
  atau dengan menggunakan password file, jangan lupa untuk menghapusnya dan jangan lupa untuk di ignore di git

  ``` shell
  openssl genrsa -passout file:config/pass.stargan.local.txt -out stargan.local.key -aes256
  ```

### remove password from private key
jika private key digunakan di sistem yang cukup aman, ada kalanya password tidak diperlukan agar key bisa digunakan secara otomatis tanpa harus memasukkan password.
contohnya adalah jika dipakai di sebuah web server, agar jika web server ini restart maka tidak perlu memasukkan passphrasenya

```
openssl rsa -in stargan.local.key -out stargan.local.decrypted.key
```

### membuat CSR

kemudian kita akan membuat CSR, untuk memudahkan kita akan membuat stargan.local.cnf

``` shell
openssl req -new -key stargan.local.key -out stargan.local.csr -config config/stargan.local.cnf
```

### buat file ```stargan.local.cnf```
``` config
# OpenSSL configuration to generate a new key with signing requst for a x509v3
# multidomain certificate
#
# openssl req -new -key stargan.local.key -out stargan.local.csr -config stargan.local.cnf

[ req ]
default_bits       = 4096
default_md         = sha512
default_keyfile    = key.pem
prompt             = no
encrypt_key        = no

# base request
distinguished_name = req_distinguished_name

# extensions
req_extensions     = v3_req

# distinguished_name
[ req_distinguished_name ]
countryName            = "ID"                     # C=
stateOrProvinceName    = "DKI Jakarta"                 # ST=
localityName           = "Jakarta"                 # L=
postalCode             = "10110"                 # L/postalcode=
streetAddress          = "Merdeka"            # L/street=
organizationName       = "Stargan"        # O=
organizationalUnitName = "Departemen Kreatif"          # OU=
commonName             = "stargan.local"            # CN=
emailAddress           = "webmaster@stargan.local"  # CN/emailAddress=

# req_extensions
[ v3_req ]
# The subject alternative name extension allows various literal values to be
# included in the configuration file
# http://www.openssl.org/docs/apps/x509v3_config.html
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName  = @alt_names
[alt_names]
DNS.1 = *.stargan.local
DNS.2 = mail.stargan.local
DNS.3 = api.stargan.local
DNS.4 = apipersuratan.stargan.local
DNS.5 = persuratan.stargan.local
DNS.6 = www.stargan.local
DNS.7 = sso.stargan.local
```

### check CSR

``` shell
openssl req -in stargan.local.csr -text -noout
```

### create and sign certificate

untuk self signed agar kita bs menggunakan SAN

maka perlu membut extension file ```stargan.local.ext```

``` config
authorityKeyIdentifier=keyid,issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName  = @alt_names
[alt_names]
DNS.1 = *.stargan.local
DNS.2 = mail.stargan.local
DNS.3 = api.stargan.local
DNS.4 = apipersuratan.stargan.local
DNS.5 = persuratan.stargan.local
DNS.6 = www.stargan.local
DNS.7 = sso.stargan.local
```

kemudian gunakan extension tersebut untuk membuat certificate

``` shell
openssl x509 -req -in stargan.local.csr -CA starganCA.pem -CAkey starganCA.key -CAcreateserial -out stargan.local.crt -days 1825 -sha512 -extfile config/stargan.local.ext
```
