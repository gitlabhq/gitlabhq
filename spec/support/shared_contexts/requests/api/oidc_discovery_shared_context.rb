# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'when doing OIDC key discovery' do
  let_it_be(:rsa_key_1) { OpenSSL::PKey::RSA.new(2048) }
  let_it_be(:rsa_key_2) { OpenSSL::PKey::RSA.new(2048) }

  subject(:jwks) do
    get '/oauth/discovery/keys'

    jwks = Gitlab::Json.parse(response.body)
    jwks['keys'].map { |json| ::JWT::JWK.new(json) }
  end

  def key_match?(jwk, private_key)
    jwk.public_key.to_pem == private_key.public_key.to_pem
  end
end
