# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::Encrypted, feature_category: :system_access do
  let(:field) { 'token' }
  let(:encrypted_field) { 'token_encrypted' }
  let(:encrypted_option) { :required }
  let(:options) { { encrypted: encrypted_option } }
  let(:test_class) do
    Struct.new(:name, field, encrypted_field) do
      alias_method :read_attribute, :[]
    end
  end

  let(:original_token) { 'my-value' }
  let(:encrypted_token) do
    Authn::TokenField::EncryptionHelper.encrypt_token(original_token)
  end

  let(:encrypted_token_with_static_iv) do
    Gitlab::CryptoHelper.aes256_gcm_encrypt(original_token)
  end

  let(:token_owner_record) { test_class.new }

  subject(:strategy) do
    described_class.new(test_class, field, options)
  end

  describe '#find_token_authenticatable' do
    shared_examples 'finds the resource' do
      it 'finds the resource by cleartext' do
        expect(strategy.find_token_authenticatable(original_token))
          .to eq(token_owner_record)
      end
    end

    shared_examples 'does not find any resource' do
      it 'does not find any resource by cleartext' do
        expect(strategy.find_token_authenticatable(original_token))
          .to be_nil
      end
    end

    shared_examples 'finds the resource with/without setting require_prefix_for_validation' do
      let(:standard_runner_token_prefix) { 'GR1348941' }
      it_behaves_like 'finds the resource'

      context 'when a require_prefix_for_validation is provided' do
        let(:options) do
          super().merge(format_with_prefix: :format_with_prefix_method, require_prefix_for_validation: true)
        end

        before do
          allow(token_owner_record).to receive(:format_with_prefix_method).and_return(standard_runner_token_prefix)
        end

        it_behaves_like 'does not find any resource'

        context 'when token starts with prefix' do
          let(:original_token) { "#{standard_runner_token_prefix}plain_token" }

          it_behaves_like 'finds the resource'
        end
      end
    end

    context 'when encryption is required' do
      before do
        allow(test_class).to receive(:where)
          .and_return(test_class)
        allow(test_class).to receive(:find_by)
          .with(encrypted_field => [encrypted_token, encrypted_token_with_static_iv])
          .and_return(token_owner_record)
      end

      it_behaves_like 'finds the resource with/without setting require_prefix_for_validation'
    end

    context 'when encryption is optional' do
      let(:encrypted_option) { :optional }

      before do
        allow(test_class).to receive(:where)
          .and_return(test_class)
        allow(test_class).to receive(:find_by)
          .with(encrypted_field => [encrypted_token, encrypted_token_with_static_iv])
          .and_return(token_owner_record)
      end

      it_behaves_like 'finds the resource with/without setting require_prefix_for_validation'

      it 'uses insecure strategy when encrypted token cannot be found' do
        allow(strategy.send(:insecure_strategy))
          .to receive(:find_token_authenticatable)
          .and_return('plaintext resource')

        allow(test_class).to receive(:where)
          .and_return(test_class)
        allow(test_class).to receive(:find_by)
          .with(encrypted_field => [encrypted_token, encrypted_token_with_static_iv])
          .and_return(nil)

        expect(strategy.find_token_authenticatable('my-value'))
          .to eq 'plaintext resource'
      end
    end

    context 'when encryption is migrating' do
      let(:encrypted_option) { :migrating }

      before do
        allow(test_class).to receive(:where)
          .and_return(test_class)
        allow(test_class).to receive(:find_by)
          .with(field => original_token)
          .and_return(token_owner_record)
      end

      it_behaves_like 'finds the resource with/without setting require_prefix_for_validation'
    end
  end

  describe '#ensure_token' do
    context 'when encryption is required' do
      let(:encrypted_option) { :required }

      context 'when encrypted attribute exists' do
        before do
          allow(token_owner_record).to receive(:has_attribute?)
            .with(encrypted_field)
            .and_return(true)
        end

        it 'returns decrypted token when an encrypted with static iv token is present' do
          expect(token_owner_record).to receive(:read_attribute)
            .with(encrypted_field).twice
            .and_return(Gitlab::CryptoHelper.aes256_gcm_encrypt('my-test-value'))

          expect(strategy.ensure_token(token_owner_record)).to eq 'my-test-value'
        end
      end

      context 'when encrypted attribute does not exist' do
        before do
          allow(token_owner_record).to receive(:has_attribute?)
            .with(encrypted_field)
            .and_return(false)
        end

        it 'raises an ArgumentError error' do
          expect { strategy.ensure_token(token_owner_record) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'when encryption is not required' do
      let(:encrypted_option) { :optional }

      context 'when encrypted attribute exists' do
        before do
          allow(token_owner_record).to receive(:has_attribute?)
            .with(encrypted_field)
            .and_return(true)
        end

        it 'returns decrypted token when an encrypted with static iv token is present' do
          expect(token_owner_record).to receive(:read_attribute)
            .with(encrypted_field).twice
            .and_return(Gitlab::CryptoHelper.aes256_gcm_encrypt('my-test-value'))

          expect(strategy.ensure_token(token_owner_record)).to eq 'my-test-value'
        end
      end

      context 'when encrypted attribute does not exist' do
        before do
          allow(token_owner_record).to receive(:has_attribute?)
            .with(encrypted_field)
            .and_return(false)
        end

        it 'returns unencrypted token' do
          expect(token_owner_record).to receive(:read_attribute)
            .with(field).twice
            .and_return('my-test-value')

          expect(strategy.ensure_token(token_owner_record)).to eq 'my-test-value'
        end
      end
    end
  end

  describe '#get_token' do
    context 'when encryption is required' do
      it 'returns decrypted token when an encrypted with static iv token is present' do
        expect(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)
          .and_return(Gitlab::CryptoHelper.aes256_gcm_encrypt('my-test-value'))

        expect(strategy.get_token(token_owner_record)).to eq 'my-test-value'
      end

      it 'returns decrypted token when an encrypted token is present' do
        expect(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)
          .and_return(encrypted_token)

        expect(strategy.get_token(token_owner_record)).to eq 'my-value'
      end
    end

    context 'when encryption is optional' do
      let(:encrypted_option) { :optional }

      it 'returns decrypted token when an encrypted token is present' do
        allow(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)
          .and_return(encrypted_token)

        expect(strategy.get_token(token_owner_record)).to eq 'my-value'
      end

      it 'returns decrypted token when an encrypted with static iv token is present' do
        allow(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)
          .and_return(Gitlab::CryptoHelper.aes256_gcm_encrypt('my-test-value'))

        expect(strategy.get_token(token_owner_record)).to eq 'my-test-value'
      end

      it 'returns the plaintext token when encrypted token is not present' do
        allow(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)
          .and_return(nil)

        allow(token_owner_record).to receive(:read_attribute)
          .with(field)
          .and_return('cleartext value')

        expect(strategy.get_token(token_owner_record)).to eq 'cleartext value'
      end
    end

    context 'when encryption is migrating' do
      let(:encrypted_option) { :migrating }

      it 'returns cleartext token when an encrypted token is present' do
        allow(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)
          .and_return(encrypted_token)

        allow(token_owner_record).to receive(:read_attribute)
          .with(field)
          .and_return('my-cleartext-value')

        expect(strategy.get_token(token_owner_record)).to eq 'my-cleartext-value'
      end

      it 'returns the cleartext token when encrypted token is not present' do
        allow(token_owner_record).to receive(:read_attribute)
          .with(encrypted_field)

        allow(token_owner_record).to receive(:read_attribute)
          .with(field)
          .and_return('cleartext value')

        expect(strategy.get_token(token_owner_record)).to eq 'cleartext value'
      end
    end
  end

  describe '#set_token' do
    context 'when encryption is required' do
      it 'writes encrypted token and returns it' do
        expect(token_owner_record).to receive(:[]=)
          .with(encrypted_field, encrypted_token)

        expect(strategy.set_token(token_owner_record, 'my-value')).to eq 'my-value'
      end
    end

    context 'when encryption is optional' do
      let(:encrypted_option) { :optional }

      it 'writes encrypted token and removes plaintext token and returns it' do
        expect(token_owner_record).to receive(:[]=)
          .with(encrypted_field, encrypted_token)
        expect(token_owner_record).to receive(:[]=)
          .with(field, nil)

        expect(strategy.set_token(token_owner_record, 'my-value')).to eq 'my-value'
      end
    end

    context 'when encryption is migrating' do
      let(:encrypted_option) { :migrating }

      it 'writes encrypted token and writes plaintext token' do
        expect(token_owner_record).to receive(:[]=)
          .with(encrypted_field, encrypted_token)
        expect(token_owner_record).to receive(:[]=)
          .with(field, 'my-value')

        expect(strategy.set_token(token_owner_record, 'my-value')).to eq 'my-value'
      end
    end
  end
end
