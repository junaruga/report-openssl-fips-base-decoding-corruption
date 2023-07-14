#!/bin/bash

set -euxo pipefail

STATUS=0

OPENSSL_DIR="/home/jaruga/git/openssl2"
OPENSSL_INSTALL_DIR="${OPENSSL_DIR}/dest"
PROGRAM_DIR="/home/jaruga/git/report-openssl-fips-ed25519"

pushd "${OPENSSL_DIR}"
git clean -fdx
# See <https://github.com/openssl/openssl/blob/master/INSTALL.md>.
./Configure \
  --prefix="${OPENSSL_INSTALL_DIR}" \
  --libdir=lib \
  shared \
  enable-fips \
  enable-trace \
  -O0 -g3
  # -O0 -g3 -ggdb3 -gdwarf-5
make "-j$(nproc)"
make install
popd

pushd "${PROGRAM_DIR}"
rm -f ed25519
gcc \
  -I "${OPENSSL_DIR}/dest/include/" \
  -L "${OPENSSL_DIR}/dest/lib/" \
  -O0 -g3 -ggdb3 -gdwarf-5 \
  -o ed25519 ed25519.c -lcrypto
if ! OPENSSL_CONF="${PROGRAM_DIR}/openssl_fips.cnf" \
  OPENSSL_CONF_INCLUDE="${OPENSSL_INSTALL_DIR}/ssl" \
  OPENSSL_MODULES="${OPENSSL_INSTALL_DIR}/lib/ossl-modules" \
  LD_LIBRARY_PATH="${OPENSSL_INSTALL_DIR}/lib" \
  ./ed25519 ed25519_pub.pem; then
  echo "not ok."
  STATUS=1
else
  echo "ok."
fi
popd

exit "${STATUS}"
