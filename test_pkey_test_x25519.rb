# frozen_string_literal: true
require_relative "utils"

class OpenSSL::TestPKeyTestX25519 < OpenSSL::PKeyTestCase
  def test_x25519
    # pend_on_openssl_issue_21493

    # Test vector from RFC 7748 Section 6.1
    alice_pem = <<~EOF
    -----BEGIN PRIVATE KEY-----
    MC4CAQAwBQYDK2VuBCIEIHcHbQpzGKV9PBbBclGyZkXfTC+H68CZKrF3+6UduSwq
    -----END PRIVATE KEY-----
    EOF
    bob_pem = <<~EOF
    -----BEGIN PUBLIC KEY-----
    MCowBQYDK2VuAyEA3p7bfXt9wbTTW2HC7OQ1Nz+DQ8hbeGdNrfx+FG+IK08=
    -----END PUBLIC KEY-----
    EOF
    shared_secret = "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"
    begin
      alice = OpenSSL::PKey.read(alice_pem)
      bob = OpenSSL::PKey.read(bob_pem)
    rescue OpenSSL::PKey::PKeyError
      # OpenSSL < 1.1.0
      pend "X25519 is not implemented"
    end
    assert_instance_of OpenSSL::PKey::PKey, alice
    assert_equal alice_pem, alice.private_to_pem
    assert_equal bob_pem, bob.public_to_pem
    assert_equal [shared_secret].pack("H*"), alice.derive(bob)
    begin
      alice_private = OpenSSL::PKey.new_raw_private_key("X25519", alice.raw_private_key)
      bob_public = OpenSSL::PKey.new_raw_public_key("X25519", bob.raw_public_key)
      alice_private_raw = alice.raw_private_key.unpack1("H*")
      bob_public_raw = bob.raw_public_key.unpack1("H*")
    rescue NoMethodError
      # OpenSSL < 1.1.1
      pend "running OpenSSL version does not have raw public key support"
    end
    assert_equal alice_private.private_to_pem,
      alice.private_to_pem
    assert_equal bob_public.public_to_pem,
      bob.public_to_pem
    assert_equal "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a",
      alice_private_raw
    assert_equal "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f",
      bob_public_raw
  end

  def raw_initialize
    pend "Ed25519 is not implemented" unless openssl?(1, 1, 1) # >= v1.1.1

    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_private_key("foo123", "xxx") }
    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_private_key("ED25519", "xxx") }
    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_public_key("foo123", "xxx") }
    assert_raise(OpenSSL::PKey::PKeyError) { OpenSSL::PKey.new_raw_public_key("ED25519", "xxx") }
  end
end
