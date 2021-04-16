# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::Encrypted do
  let(:model) { double(:model) }
  let(:instance) { double(:instance) }

  let(:encrypted) do
    TokenAuthenticatableStrategies::EncryptionHelper.encrypt_token('my-value')
  end

  let(:encrypted_with_static_iv) do
    Gitlab::CryptoHelper.aes256_gcm_encrypt('my-value')
  end

  subject do
    described_class.new(model, 'some_field', options)
  end

  describe '#find_token_authenticatable' do
    context 'when encryption is required' do
      let(:options) { { encrypted: :required } }

      it 'finds the encrypted resource by cleartext' do
        allow(model).to receive(:find_by)
          .with('some_field_encrypted' => [encrypted, encrypted_with_static_iv])
          .and_return('encrypted resource')

        expect(subject.find_token_authenticatable('my-value'))
          .to eq 'encrypted resource'
      end
    end

    context 'when encryption is optional' do
      let(:options) { { encrypted: :optional } }

      it 'finds the encrypted resource by cleartext' do
        allow(model).to receive(:find_by)
          .with('some_field_encrypted' => [encrypted, encrypted_with_static_iv])
          .and_return('encrypted resource')

        expect(subject.find_token_authenticatable('my-value'))
          .to eq 'encrypted resource'
      end

      it 'uses insecure strategy when encrypted token cannot be found' do
        allow(subject.send(:insecure_strategy))
          .to receive(:find_token_authenticatable)
          .and_return('plaintext resource')

        allow(model).to receive(:find_by)
          .with('some_field_encrypted' => [encrypted, encrypted_with_static_iv])
          .and_return(nil)

        expect(subject.find_token_authenticatable('my-value'))
          .to eq 'plaintext resource'
      end
    end

    context 'when encryption is migrating' do
      let(:options) { { encrypted: :migrating } }

      it 'finds the cleartext resource by cleartext' do
        allow(model).to receive(:find_by)
          .with('some_field' => 'my-value')
          .and_return('cleartext resource')

        expect(subject.find_token_authenticatable('my-value'))
          .to eq 'cleartext resource'
      end

      it 'returns nil if resource cannot be found' do
        allow(model).to receive(:find_by)
          .with('some_field' => 'my-value')
          .and_return(nil)

        expect(subject.find_token_authenticatable('my-value'))
          .to be_nil
      end
    end
  end

  describe '#get_token' do
    context 'when encryption is required' do
      let(:options) { { encrypted: :required } }

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
      let(:options) { { encrypted: :optional } }

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
      let(:options) { { encrypted: :migrating } }

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
      let(:options) { { encrypted: :required } }

      it 'writes encrypted token and returns it' do
        expect(instance).to receive(:[]=)
          .with('some_field_encrypted', encrypted)

        expect(subject.set_token(instance, 'my-value')).to eq 'my-value'
      end
    end
    context 'when encryption is optional' do
      let(:options) { { encrypted: :optional } }

      it 'writes encrypted token and removes plaintext token and returns it' do
        expect(instance).to receive(:[]=)
          .with('some_field_encrypted', encrypted)
        expect(instance).to receive(:[]=)
          .with('some_field', nil)

        expect(subject.set_token(instance, 'my-value')).to eq 'my-value'
      end
    end

    context 'when encryption is migrating' do
      let(:options) { { encrypted: :migrating } }

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
