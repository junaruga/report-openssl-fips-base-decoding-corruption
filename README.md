# report-openssl-fips-ed25519

```
$ gcc -o ed25519 ed25519.c -lcrypto

$ OPENSSL_CONF=/home/jaruga/.local/openssl-3.0.8-fips-debug/ssl/openssl_fips.cnf \
  OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.0.8-fips-debug/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.0.8-fips-debug/lib/ossl-modules \
  /home/jaruga/git/report-openssl-fips-ed25519/ed25519 key.pem
Loaded providers:
  fips
  base
[DEBUG] Calling ossl_pkey_read_generic from ossl_pkey_new_from_data.
Got a pkey! 0x1800430
It's held by the provider fips
```
