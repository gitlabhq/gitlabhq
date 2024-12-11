# frozen_string_literal: true

module Auth
  module DpopTokenHelper
    VALID_ALG = 'RS512'
    VALID_TYP = 'dpop+jwt'
    VALID_KTY = 'RSA'

    DpopProof = Struct.new(:ssh_public_key, :public_key_in_jwk, :openssl_private_key, :fingerprint, :proof)

    def generate_dpop_proof_for(
      user, ssh_public_key: nil, alg: VALID_ALG, typ: VALID_TYP,
      kty: VALID_KTY, fingerprint: nil, ath: nil, public_key_in_jwk: nil)
      # NOTE: `ssh_public_key` and `ssh_private_key` are not real secrets.
      # They are a key pair generated solely for testing.
      #
      ssh_public_key ||= "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1ZgRbeixURy9/HxU5r5O3Xobnw1bmQx3dyFMkRLMFCy" \
        "8aVkBvMw6CAc+81miOv+Sg/CZA2DKBAiEz0YwgPlD32o0q/OR5JdFAMH7e5IObm/4wr8dqm4JDE6eZ6f" \
        "eO+0tFwlrPnV8oiymw4SXeJLJf0n9f7HhH7xJJdWOOQZ2Ku/KMuNdf0aWYhbywUFWN4k5JtwCdEBxZYM" \
        "NqRYv28i76j3rTm7hBMyor7B2+3lPfeUQpTJkW1UBwUDAYeKZAl6HgZPE9DmcaDSRVViLErp00/iaQSs" \
        "MxlDSvhaOWARxFgFVNX7iV6S2MNaxah2CrPOyhBA2f2QSdQIQRB/NYjZivROMKaHmaflSB7VVUWyKWPR" \
        "QfSHbCgbnLpjYyoG7W+mRZ47i9+DeQLsBcIXjTJF/XfcV0iotFxPXiQk5h42+Oi+4YdGWerNl3JY15Dj" \
        "6QG1Q5UD8J026H4/P/2mPytFTb3iA9jmWEveF6nMC9RVNmqEep51/ZsL1zfenX3vr9Nl0= example@gitlab.com"

      ssh_private_key = "-----BEGIN RSA PRIVATE KEY-----" \
        "\n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" \
        "\n-----END RSA PRIVATE KEY-----"

      key = user.keys.create!(title: "Sample key #{user.id}", key: ssh_public_key)
      fingerprint ||= create_fingerprint(key.key)
      openssl_private_key = OpenSSL::PKey::RSA.new(ssh_private_key)

      public_key_in_jwk ||= {
        kty: kty,
        n: Base64.urlsafe_encode64(openssl_private_key.n.to_s(2), padding: false),
        e: Base64.urlsafe_encode64(openssl_private_key.e.to_s(2), padding: false)
      }

      ath ||= generate_ath(personal_access_token)

      dpop_proof = create_dpop_proof(
        alg,
        typ,
        fingerprint,
        public_key_in_jwk,
        openssl_private_key,
        ath: ath
      )

      DpopProof.new(ssh_public_key, public_key_in_jwk, openssl_private_key, fingerprint, dpop_proof)
    end

    def generate_ath(pat)
      Base64.urlsafe_encode64(Digest::SHA256.digest(pat.token), padding: false)
    end

    def create_dpop_proof(alg, typ, kid, public_key, private_key, htu: '', htm: '', ath: nil, iat: Time.now.to_i, exp: Time.now.to_i + 300) # rubocop:disable Metrics/ParameterLists -- all params needed for edge cases
      headers = create_headers(alg, typ, public_key, kid)

      jti = SecureRandom.uuid

      payload = create_payload(
        htu: htu, htm: htm, ath: ath, iat: iat, jti: jti, exp: exp)

      JWT.encode(payload, private_key, alg, headers)
    end

    def create_headers(alg, typ, public_key, kid)
      if kid == ""
        {
          alg: alg,
          typ: typ,
          jwk: public_key
        }
      else
        {
          alg: alg,
          typ: typ,
          jwk: public_key,
          kid: kid
        }
      end
    end

    def create_payload(
      htu:, htm:, ath: nil, iat: Time.now.to_i, jti: SecureRandom.uuid,
      exp: Time.now.to_i + 300)
      if exp == ""
        {
          htu: htu,
          htm: htm,
          ath: ath,
          iat: iat,
          jti: jti
        }
      else
        {
          htu: htu,
          htm: htm,
          ath: ath,
          iat: iat,
          jti: jti,
          exp: exp
        }
      end
    end

    def create_fingerprint(key)
      Gitlab::SSHPublicKey.new(key).fingerprint_sha256
    end
  end
end
