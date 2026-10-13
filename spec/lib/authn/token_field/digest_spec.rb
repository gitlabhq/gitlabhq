# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::Digest, feature_category: :system_access do
  let(:field) { 'token' }
  let(:digest_field) { 'token_digest' }
  let(:options) { { digest: true } }
  let(:test_class) do
    Struct.new(:name, field, digest_field) do
      # Implicitely required by #get_token and #set_token
      attr_accessor :cleartext_tokens

      alias_method :read_attribute, :[]
    end
  end

  let(:instance) { test_class.new }

  subject(:strategy) do
    described_class.new(test_class, field, options)
  end

  describe '#token_fields' do
    it 'includes the digest field' do
      expect(strategy.token_fields).to contain_exactly(field, digest_field)
    end
  end

  describe '#find_token_authenticatable' do
    let(:original_token) { 'my-value' }

    context 'when digest is required' do
      before do
        allow(test_class).to receive(:where)
          .and_return(test_class)
        allow(test_class).to receive(:find_by)
          .with(digest_field => Gitlab::CryptoHelper.sha256_candidates(original_token))
          .and_return(instance)
      end

      it 'finds the resource by cleartext' do
        expect(strategy.find_token_authenticatable(original_token))
          .to eq(instance)
      end
    end
  end

  describe '#find_token_authenticatable with several db_key_base keys' do
    include DbKeyBaseHelpers

    let_it_be(:user) { create(:user) }

    let(:personal_access_token) { create(:personal_access_token, user: user) }
    let(:token) { personal_access_token.token }

    subject(:strategy) { described_class.new(PersonalAccessToken, field, options) }

    before do
      token
    end

    it 'finds a token digested with the previous key' do
      stub_db_key_base_keys(Settings.db_key_base_keys.last, SecureRandom.hex(64))

      expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
    end

    it 'does not find it with an unrelated key only' do
      stub_db_key_base_keys(SecureRandom.hex(64))

      expect(strategy.find_token_authenticatable(token)).to be_nil
    end
  end

  describe '#get_token' do
    let(:new_token) { 'bar' }

    context 'when token does not exist' do
      it 'returns nil' do
        expect(strategy.get_token(instance)).to be_nil
      end
    end

    context 'when token exists' do
      before do
        strategy.set_token(instance, 'foo')
      end

      it 'retrieves the token' do
        expect(strategy.get_token(instance)).to eq('foo')
      end
    end
  end

  describe '#set_token' do
    let(:new_token) { 'bar' }

    context 'when token_digest does not exist' do
      it 'sets new token' do
        strategy.set_token(instance, new_token)

        expect(instance.cleartext_tokens[field]).to eq(new_token)
        expect(instance[digest_field]).to eq(Gitlab::CryptoHelper.sha256(new_token))
      end
    end
  end
end
