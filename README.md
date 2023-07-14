# report-openssl-fips-ed25519

This is a C program to reproduce a method to read a ed25519 PEM file, then convert to a object and then convert to the PEM file again. It should be the same with the origina PEM file.

```
$ cat ed25519_pub.pem
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAPUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw=
-----END PUBLIC KEY-----
```

```
$ gcc \
  -I /home/jaruga/.local/openssl-3.0.8-debug/include \
  -L /home/jaruga/.local/openssl-3.0.8-debug/lib \
  -o ed25519 ed25519.c -lcrypto
```

## Non-FIPS mode

```
$ OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.0.8-debug/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.0.8-debug/lib/ossl-modules \
  ./ed25519 ed25519_pub.pem
[DEBUG] Loaded providers:
  default
[DEBUG] Got a pkey! 0x24294e0
[DEBUG] It's held by the provider default
[DEBUG] ossl_membio2str buf->data:
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAPUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw=
-----END PUBLIC KEY-----
```

## FIPS mode

```
$ OPENSSL_CONF=/home/jaruga/.local/openssl-3.0.8-fips-debug/ssl/openssl_fips.cnf \
  OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.0.8-fips-debug/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.0.8-fips-debug/lib/ossl-modules \
  ./ed25519 ed25519_pub.pem
[DEBUG] Loaded providers:
  fips
  base
[DEBUG] Got a pkey! 0x21476a0
[DEBUG] It's held by the provider fips
[DEBUG] ossl_membio2str buf->data:
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
-----END PUBLIC KEY-----
```
