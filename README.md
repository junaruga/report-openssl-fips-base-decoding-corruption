# report-openssl-fips-base-decoding-corruption

This is a C program to reproduce a method to read and decode a x25519 and ed25519 PEM files.

## crypto: x25519

I tested this on the latest master branch `8c34367e434c6b9555f21cc4fc77a18d6ef84a85`.

The origina PEM file is below.

```
$ cat x25519_pub.pem
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEA3p7bfXt9wbTTW2HC7OQ1Nz+DQ8hbeGdNrfx+FG+IK08=
-----END PUBLIC KEY-----
```

Compile.

```
$ gcc \
  -I /home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/include \
  -L /home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/lib \
  -o reproducer reproducer.c -lcrypto
```

### Non-FIPS

The decoded text is the same with the original PEM file.

```
$ OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/lib/ossl-modules \
  LD_LIBRARY_PATH=/home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/lib \
  ./reproducer x25519_pub.pem
[DEBUG] Loaded providers:
  default
[DEBUG] FIPS mode enabled: 0
[DEBUG] data_size: 113
[DEBUG] OSSL_DECODER_from_bio PEM 2 failed.
[DEBUG] Got a pkey! 0x5707a0
[DEBUG] It's held by the provider default
[DEBUG] ossl_membio2str buf->data:
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEA3p7bfXt9wbTTW2HC7OQ1Nz+DQ8hbeGdNrfx+FG+IK08=
-----END PUBLIC KEY-----
```

### FIPS

The decode text is different from the original PEM file.

```
$ OPENSSL_CONF=$(pwd)/openssl_fips.cnf \
  OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/lib/ossl-modules \
  LD_LIBRARY_PATH=/home/jaruga/.local/openssl-3.2.0.dev-fips-debug-8c34367e43/lib \
  ./reproducer x25519_pub.pem
[DEBUG] Loaded providers:
  fips
  base
[DEBUG] FIPS mode enabled: 1
[DEBUG] data_size: 113
[DEBUG] OSSL_DECODER_from_bio PEM 2 failed.
[DEBUG] Got a pkey! 0xd7fde0
[DEBUG] It's held by the provider fips
[DEBUG] ossl_membio2str buf->data:
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
-----END PUBLIC KEY----
```

## crypto: ed25519

The ed25519 is not allowed in OpenSSL 3.1+ in FIPS case. So, this can be reproduceed in OpenSSL 3.0 where the crypto is allowed in the "code". But it is not allowed in the security policy document.

The origina PEM file is below.

```
$ cat ed25519_pub.pem
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAPUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw=
-----END PUBLIC KEY-----
```

Compile.

```
$ gcc \
  -I /home/jaruga/.local/openssl-3.0.9-debug/include \
  -L /home/jaruga/.local/openssl-3.0.9-debug/lib \
  -o reproducer309 reproducer.c -lcrypto
```

### Non-FIPS

The decoded text is the same with the original PEM file.

```
$ OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.0.9-debug/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.0.9-debug/lib/ossl-modules \
  LD_LIBRARY_PATH=/home/jaruga/.local/openssl-3.0.9-debug/lib \
  ./reproducer_309 ed25519_pub.pem
[DEBUG] Loaded providers:
  default
[DEBUG] FIPS mode enabled: 0
[DEBUG] data_size: 113
[DEBUG] OSSL_DECODER_from_bio PEM 2 failed.
[DEBUG] Got a pkey! 0xcca9e0
[DEBUG] It's held by the provider default
[DEBUG] ossl_membio2str buf->data:
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAPUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw=
-----END PUBLIC KEY-----
```

### FIPS

The decode text is different from the original PEM file.

```
$ OPENSSL_CONF=/home/jaruga/.local/openssl-3.0.9-fips-debug/ssl/openssl_fips.cnf \
  OPENSSL_CONF_INCLUDE=/home/jaruga/.local/openssl-3.0.9-fips-debug/ssl \
  OPENSSL_MODULES=/home/jaruga/.local/openssl-3.0.9-fips-debug/lib/ossl-modules \
  LD_LIBRARY_PATH=/home/jaruga/.local/openssl-3.0.9-fips-debug/lib \
  ./reproducer_309 ed25519_pub.pem
[DEBUG] Loaded providers:
  fips
  base
[DEBUG] FIPS mode enabled: 1
[DEBUG] data_size: 113
[DEBUG] OSSL_DECODER_from_bio PEM 2 failed.
[DEBUG] Got a pkey! 0x23655e0
[DEBUG] It's held by the provider fips
[DEBUG] ossl_membio2str buf->data:
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
-----END PUBLIC KEY-----
```

