#!/bin/bash

set -euxo pipefail

STATUS=0

OPENSSL_DIR="/home/jaruga/git/openssl2"
OPENSSL_INSTALL_DIR="${OPENSSL_DIR}/dest"
RUBY_OPENSSL_DIR="/home/jaruga/git/ruby/openssl2"
REPORT_DIR="/home/jaruga/git/report-openssl-fips-base-decoding-corruption"
TEST_OPENSSL_FIPS_CONF="${REPORT_DIR}/openssl_fips.cnf"
RUBY_TEST_FILE_NAME="test_pkey_test_compare.rb"
# RUBY_TEST_FILE_NAME="test_pkey_test_x25519.rb"
RUBY_TEST_FILE="${REPORT_DIR}/${RUBY_TEST_FILE_NAME}"

cp -p "${RUBY_TEST_FILE}" "${RUBY_OPENSSL_DIR}/test/openssl/"

pushd "${OPENSSL_DIR}"
git clean -fdx
# See <https://github.com/openssl/openssl/blob/master/INSTALL.md>.
# no-docs option is available in OpenSSL 3.2+.
./Configure \
  --prefix="${OPENSSL_INSTALL_DIR}" \
  --libdir=lib \
  shared \
  enable-fips \
  enable-trace \
  no-docs \
  -O0 -g3 -ggdb3 -gdwarf-5
make "-j$(nproc)"
make install
popd

pushd "${RUBY_OPENSSL_DIR}"
# Note run `bundle install` in advance.
bundle exec rake clean
rm -rf tmp/ lib/openssl.so

MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile -- \
  --enable-debug \
  --with-openssl-dir="${OPENSSL_INSTALL_DIR}"

if ! OPENSSL_CONF="${TEST_OPENSSL_FIPS_CONF}" \
  ruby -I./lib -ropenssl "test/openssl/${RUBY_TEST_FILE_NAME}"; then
  echo "not ok."
  STATUS=1
else
  echo "ok."
fi

# Need to invert the return code when finding the fixed commit.
# https://stackoverflow.com/questions/15407075/how-could-i-use-git-bisect-to-find-the-first-good-commit/17153598
# > @DanielBöhmer: well, in that case you'll have to invert the return code, don't you?
# > Correct, that's what is described in my answer.
if [ "${STATUS}" = 1 ]; then
  STATUS=0
else
  STATUS=1
fi

exit "${STATUS}"
