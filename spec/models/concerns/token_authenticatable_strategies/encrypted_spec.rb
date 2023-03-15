# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::Encrypted, feature_category: :system_access do
  let(:model) { double(:model) }
  let(:instance) { double(:instance) }
  let(:original_token) { 'my-value' }
  let(:resource) { double(:resource) }
  let(:options) { other_options.merge(encrypted: encrypted_option) }
  let(:other_options) { {} }

  let(:encrypted) do
    TokenAuthenticatableStrategies::EncryptionHelper.encrypt_token(original_token)
  end

  let(:encrypted_with_static_iv) do
    Gitlab::CryptoHelper.aes256_gcm_encrypt(original_token)
  end

  subject(:strategy) do
    described_class.new(model, 'some_field', options)
  end

  describe '#token_fields' do
    let(:encrypted_option) { :required }

    it 'includes the encrypted field' do
      expect(strategy.token_fields).to contain_exactly('some_field', 'some_field_encrypted')
    end
  end

  describe '#find_token_authenticatable' do
    shared_examples 'finds the resource' do
      it 'finds the resource by cleartext' do
        expect(subject.find_token_authenticatable(original_token))
          .to eq(resource)
      end
    end

    shared_examples 'does not find any resource' do
      it 'does not find any resource by cleartext' do
        expect(subject.find_token_authenticatable(original_token))
          .to be_nil
      end
    end

    shared_examples 'finds the resource with/without setting require_prefix_for_validation' do
      let(:standard_runner_token_prefix) { 'GR1348941' }
      it_behaves_like 'finds the resource'

      context 'when a require_prefix_for_validation is provided' do
        let(:other_options) { { format_with_prefix: :format_with_prefix_method, require_prefix_for_validation: true } }

        before do
          allow(resource).to receive(:format_with_prefix_method).and_return(standard_runner_token_prefix)
        end

        it_behaves_like 'does not find any resource'

        context 'when token starts with prefix' do
          let(:original_token) { "#{standard_runner_token_prefix}plain_token" }

          it_behaves_like 'finds the resource'
        end
      end
    end

    context 'when encryption is required' do
      let(:encrypted_option) { :required }
      let(:resource) { double(:encrypted_resource) }

      before do
        allow(model).to receive(:where)
          .and_return(model)
        allow(model).to receive(:find_by)
          .with('some_field_encrypted' => [encrypted, encrypted_with_static_iv])
          .and_return(resource)
      end

      it_behaves_like 'finds the resource with/without setting require_prefix_for_validation'
    end

    context 'when encryption is optional' do
      let(:encrypted_option) { :optional }
      let(:resource) { double(:encrypted_resource) }

      before do
        allow(model).to receive(:where)
          .and_return(model)
        allow(model).to receive(:find_by)
          .with('some_field_encrypted' => [encrypted, encrypted_with_static_iv])
          .and_return(resource)
      end

      it_behaves_like 'finds the resource with/without setting require_prefix_for_validation'

      it 'uses insecure strategy when encrypted token cannot be found' do
        allow(subject.send(:insecure_strategy))
          .to receive(:find_token_authenticatable)
          .and_return('plaintext resource')

        allow(model).to receive(:where)
          .and_return(model)
        allow(model).to receive(:find_by)
          .with('some_field_encrypted' => [encrypted, encrypted_with_static_iv])
          .and_return(nil)

        expect(subject.find_token_authenticatable('my-value'))
          .to eq 'plaintext resource'
      end
    end

    context 'when encryption is migrating' do
      let(:encrypted_option) { :migrating }
      let(:resource) { double(:cleartext_resource) }

      before do
        allow(model).to receive(:where)
          .and_return(model)
        allow(model).to receive(:find_by)
          .with('some_field' => original_token)
          .and_return(resource)
      end

      it_behaves_like 'finds the resource with/without setting require_prefix_for_validation'
    end
  end

  describe '#get_token' do
    context 'when encryption is required' do
      let(:encrypted_option) { :required }

      it 'returns decrypted token when an encrypted with static iv token is present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(Gitlab::CryptoHelper.aes256_gcm_encrypt('my-test-value'))

        expect(subject.get_token(instance)).to eq 'my-test-value'
      end

      it 'returns decrypted token when an encrypted token is present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(encrypted)

        expect(subject.get_token(instance)).to eq 'my-value'
      end
    end

    context 'when encryption is optional' do
      let(:encrypted_option) { :optional }

      it 'returns decrypted token when an encrypted token is present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(encrypted)

        expect(subject.get_token(instance)).to eq 'my-value'
      end

      it 'returns decrypted token when an encrypted with static iv token is present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(Gitlab::CryptoHelper.aes256_gcm_encrypt('my-test-value'))

        expect(subject.get_token(instance)).to eq 'my-test-value'
      end

      it 'returns the plaintext token when encrypted token is not present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(nil)

        allow(instance).to receive(:read_attribute)
          .with('some_field')
          .and_return('cleartext value')

        expect(subject.get_token(instance)).to eq 'cleartext value'
      end
    end

    context 'when encryption is migrating' do
      let(:encrypted_option) { :migrating }

      it 'returns cleartext token when an encrypted token is present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(encrypted)

        allow(instance).to receive(:read_attribute)
          .with('some_field')
          .and_return('my-cleartext-value')

        expect(subject.get_token(instance)).to eq 'my-cleartext-value'
      end

      it 'returns the cleartext token when encrypted token is not present' do
        allow(instance).to receive(:read_attribute)
          .with('some_field_encrypted')
          .and_return(nil)

        allow(instance).to receive(:read_attribute)
          .with('some_field')
          .and_return('cleartext value')

        expect(subject.get_token(instance)).to eq 'cleartext value'
      end
    end
  end

  describe '#set_token' do
    context 'when encryption is required' do
      let(:encrypted_option) { :required }

      it 'writes encrypted token and returns it' do
        expect(instance).to receive(:[]=)
          .with('some_field_encrypted', encrypted)

        expect(subject.set_token(instance, 'my-value')).to eq 'my-value'
      end
    end

    context 'when encryption is optional' do
      let(:encrypted_option) { :optional }

      it 'writes encrypted token and removes plaintext token and returns it' do
        expect(instance).to receive(:[]=)
          .with('some_field_encrypted', encrypted)
        expect(instance).to receive(:[]=)
          .with('some_field', nil)

        expect(subject.set_token(instance, 'my-value')).to eq 'my-value'
      end
    end

    context 'when encryption is migrating' do
      let(:encrypted_option) { :migrating }

      it 'writes encrypted token and writes plaintext token' do
        expect(instance).to receive(:[]=)
          .with('some_field_encrypted', encrypted)
        expect(instance).to receive(:[]=)
          .with('some_field', 'my-value')

        expect(subject.set_token(instance, 'my-value')).to eq 'my-value'
      end
    end
  end
end
