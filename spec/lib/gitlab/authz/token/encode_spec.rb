# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Authz::Token::Encode, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:key) { OpenSSL::PKey::RSA.generate(2048) }
  let_it_be(:kid) { key.public_key.to_jwk[:kid] }
  let_it_be(:body) { {} }
  let_it_be(:jwt) { ::JSONWebToken::RSAToken.encode(body, key, kid) }

  describe '#key' do
    it 'raises a NotImplementedError' do
      expect { described_class.key }.to raise_error(NotImplementedError)
    end
  end

  describe '#expected_type' do
    it 'raises a NotImplementedError' do
      expect { described_class.expected_type }.to raise_error(NotImplementedError)
    end
  end

  describe '#encode' do
    subject(:encode) { described_class.new(user).encode(expire_time: expire_time) }

    let_it_be(:expire_time) { 10.minutes.from_now.to_i }

    before do
      allow(described_class).to receive_messages(key: key, expected_type: user.class)
    end

    it 'generates a signed JWT' do
      encoded_header, encoded_body, signature = encode.split('.', 3)
      header = Gitlab::Json.parse(Base64.decode64(encoded_header))
      payload = Gitlab::Json.parse(Base64.decode64(encoded_body))

      expect(header).to match(
        'kid' => kid,
        'typ' => 'JWT',
        'alg' => 'RS256'
      )

      expect(payload).to match(a_hash_including(
        'sub' => user.to_global_id.to_s,
        'iss' => described_class::ISSUER,
        'aud' => described_class::AUDIENCE,
        'exp' => expire_time
      ))

      expect(signature).to be_present
    end

    context 'when the subject is missing' do
      subject(:encode) { described_class.new(nil).encode }

      it 'raises an error' do
        expect { encode }.to raise_error(described_class::InvalidSubjectForTokenError)
      end
    end

    context 'when the key is not set' do
      let_it_be(:key) { nil }

      it 'returns nil' do
        expect(encode).to be_nil
      end
    end

    context 'when the a global ID cannot be created for the subject' do
      subject(:encode) { described_class.new(user).encode }

      before do
        allow(GlobalID).to receive(:create).with(user).and_return(nil)
      end

      it 'raises an error' do
        expect { encode }.to raise_error(described_class::InvalidSubjectForTokenError)
      end
    end
  end
end
