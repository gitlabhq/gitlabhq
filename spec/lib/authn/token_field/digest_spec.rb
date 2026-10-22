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
      let(:instance) { test_class.new(nil, nil, Gitlab::CryptoHelper.sha256(original_token)) }

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

  describe '#find_token_authenticatable with several db_key_base keys', :clean_gitlab_redis_shared_state do
    include DbKeyBaseHelpers

    let_it_be(:user) { create(:user) }

    let(:old_key) { Settings.db_key_base_keys.last }
    let(:new_key) { SecureRandom.hex(64) }
    let(:personal_access_token) { create(:personal_access_token, user: user) }
    let(:token) { personal_access_token.token }
    let(:current_digest) { Gitlab::CryptoHelper.sha256(token) }
    let(:lease_key) { "token_digest_rehash:personal_access_tokens:#{personal_access_token.id}" }

    subject(:strategy) { described_class.new(PersonalAccessToken, field, options) }

    def stored_digest
      personal_access_token.reload.token_digest
    end

    def update_queries(&block)
      ActiveRecord::QueryRecorder.new(&block).log.grep(/\AUPDATE/)
    end

    before do
      token
      stub_db_key_base_keys(old_key, new_key)
    end

    it 'finds a token digested with the previous key and rehashes it with the current key', :aggregate_failures do
      allow(Gitlab::AuthLogger).to receive(:info)

      expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
      expect(stored_digest).to eq(current_digest)
      expect(Gitlab::AuthLogger).to have_received(:info).with(hash_including(
        token_owner_type: 'PersonalAccessToken', token_owner_id: personal_access_token.id, token_field: 'token_digest'
      ))
    end

    it 'keeps finding the token once the previous key is removed' do
      strategy.find_token_authenticatable(token)
      stub_db_key_base_keys(new_key)

      expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
    end

    it 'does not write when the digest already uses the current key', :aggregate_failures do
      stub_db_key_base_keys(old_key)

      expect(update_queries { strategy.find_token_authenticatable(token) }).to be_empty
      expect(Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute).exists?).to be(false)
    end

    it 'does not rehash while the lease for the token is taken' do
      Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute).try_obtain

      expect { strategy.find_token_authenticatable(token) }.not_to change { stored_digest }
    end

    it 'does not overwrite a digest that changed since the lookup' do
      other_digest = Gitlab::CryptoHelper.sha256('another-token')
      allow_next_instance_of(Gitlab::ExclusiveLease) do |lease|
        allow(lease).to receive(:try_obtain).and_wrap_original do |method|
          personal_access_token.update_column(:token_digest, other_digest)
          method.call
        end
      end

      strategy.find_token_authenticatable(token)

      expect(stored_digest).to eq(other_digest)
    end

    it 'does not rehash during a uniqueness check' do
      expect { strategy.find_token_authenticatable(token, uniqueness_check: true) }
        .not_to change { stored_digest }
    end

    it 'does not rehash inside a transaction' do
      expect { PersonalAccessToken.transaction { strategy.find_token_authenticatable(token) } }
        .not_to change { stored_digest }
    end

    it 'does not rehash inside a transaction on another database' do
      expect { Ci::ApplicationRecord.transaction { strategy.find_token_authenticatable(token) } }
        .not_to change { stored_digest }
    end

    it 'does not rehash a frozen record' do
      allow_next_found_instance_of(PersonalAccessToken) do |found|
        allow(found).to receive(:frozen?).and_return(true)
      end

      expect { strategy.find_token_authenticatable(token) }.not_to change { stored_digest }
    end

    it 'still finds the token when the rehash fails, without tracking the error message', :aggregate_failures do
      allow(PersonalAccessToken).to receive(:unscoped)
        .and_raise(ActiveRecord::RecordNotUnique, "DETAIL: Key (token_digest)=(#{current_digest}) already exists.")
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(described_class::RehashError).and(having_attributes(message: 'ActiveRecord::RecordNotUnique')),
        { token_field: 'token_digest' }
      )

      expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
    end

    it 'still finds the token when the lease cannot be obtained', :aggregate_failures do
      allow_next_instance_of(Gitlab::ExclusiveLease) do |lease|
        allow(lease).to receive(:try_obtain).and_raise(Redis::CannotConnectError)
      end
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(described_class::RehashError).and(having_attributes(message: 'Redis::CannotConnectError')),
        { token_field: 'token_digest' }
      )

      expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
      expect(stored_digest).not_to eq(current_digest)
    end

    it 'does not rehash when the database is read-only', :aggregate_failures do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)

      expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
      expect(stored_digest).not_to eq(current_digest)
    end

    context 'with a revoked token' do
      let(:personal_access_token) { create(:personal_access_token, :revoked, user: user) }

      it 'rehashes it and keeps it revoked', :aggregate_failures do
        expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
        expect(personal_access_token.reload).to have_attributes(token_digest: current_digest, revoked?: true)
      end
    end

    context 'with an expired token' do
      let(:personal_access_token) { create(:personal_access_token, :expired, user: user) }

      it 'rehashes it and keeps it expired', :aggregate_failures do
        expect(strategy.find_token_authenticatable(token)).to eq(personal_access_token)
        expect(personal_access_token.reload).to have_attributes(token_digest: current_digest, expired?: true)
      end
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
