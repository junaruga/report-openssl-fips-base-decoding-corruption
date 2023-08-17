# frozen_string_literal: true
require_relative "utils"

class OpenSSL::TestPKeyTestCompare < OpenSSL::PKeyTestCase

  def raw_initialize
    pend "Ed25519 is not implemented" unless openssl?(1, 1, 1) # >= v1.1.1

    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_private_key("foo123", "xxx") }
    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_private_key("ED25519", "xxx") }
    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_public_key("foo123", "xxx") }
    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_public_key("ED25519", "xxx") }
  end

  def test_compare?
    # pend_on_openssl_issue_21493

    key1 = Fixtures.pkey("rsa1024")
    key2 = Fixtures.pkey("rsa1024")
    key3 = Fixtures.pkey("rsa2048")
    key4 = Fixtures.pkey("dh-1")

    assert_equal(true, key1.compare?(key2))
    assert_equal(true, key1.public_key.compare?(key2))
    assert_equal(true, key2.compare?(key1))
    assert_equal(true, key2.public_key.compare?(key1))

    assert_equal(false, key1.compare?(key3))

    assert_raise(TypeError) do
      key1.compare?(key4)
    end
  end
end
