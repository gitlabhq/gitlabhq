# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Authz::Token::Decode, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:key) { OpenSSL::PKey::RSA.generate(2048) }
  let_it_be(:kid) { key.public_key.to_jwk[:kid] }
  let(:body) { {} }
  let(:jwt) { ::JSONWebToken::RSAToken.encode(body, key, kid) }

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

  describe '#jwt?' do
    subject(:result) { described_class.new(jwt).jwt? }

    it { is_expected.to be(true) }

    context 'when the token is invalid' do
      where(:jwt) do
        [nil, '', SecureRandom.uuid]
      end

      with_them do
        it { is_expected.to be(false) }
      end
    end
  end

  describe '#decode' do
    subject(:decode) { described_class.new(jwt).decode }

    before do
      allow(described_class).to receive(:key).and_return(key)
    end

    it { is_expected.to match_array([body, { 'alg' => 'RS256', 'kid' => kid, 'typ' => 'JWT' }]) }

    context 'when the key is not set' do
      before do
        allow(described_class).to receive(:key).and_return(nil)
      end

      it 'returns nil' do
        expect(decode).to be_nil
      end
    end
  end

  describe '#subject' do
    subject(:result) { token.subject }

    let(:token) { described_class.new(jwt) }
    let_it_be(:user) { create(:user) }
    let_it_be(:expected_type) { user.class }
    let_it_be(:expected_error) { ::Gitlab::Graphql::Errors::ArgumentError }

    before do
      allow(described_class).to receive_messages(key: key, expected_type: expected_type)
    end

    context 'when the token has not been decoded first' do
      it { is_expected.to be_nil }
    end

    context 'when the token has been decoded first' do
      before do
        token.decode
      end

      context 'when the `sub` claim is provided and of the expected type' do
        let_it_be(:body) { { sub: user.to_global_id.to_s } }

        it { is_expected.to eq(user) }
      end

      context 'when the `sub` claim is not present' do
        it { expect { result }.to raise_error(expected_error) }
      end

      context 'when the `sub` claim is not a Global ID' do
        let_it_be(:body) { { sub: 1 } }

        it { expect { result }.to raise_error(expected_error) }
      end

      context 'when the `sub` claim is the wrong type' do
        let_it_be(:project) { create(:project) }
        let_it_be(:body) { { sub: project.to_global_id.to_s } }

        it { expect { result }.to raise_error(expected_error) }
      end
    end
  end
end
