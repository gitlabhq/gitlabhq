require 'spec_helper'

describe TokenAuthenticatableStrategies::Encrypted do
  let(:model) { double(:model) }
  let(:instance) { double(:instance) }
  let(:options) { { fallback: true } }

  let(:encrypted) do
    Gitlab::CryptoHelper.aes256_gcm_encrypt('my-value')
  end

  subject do
    described_class.new(model, 'some_field', options)
  end

  describe '#find_token_authenticatable' do
    it 'finds a relevant resource by encrypted value' do
      allow(model).to receive(:find_by)
        .with('some_field_encrypted' => encrypted)
        .and_return('encrypted resource')

      expect(subject.find_token_authenticatable('my-value'))
        .to eq 'encrypted resource'
    end

    it 'uses fallback strategy when token can not be found' do
      allow_any_instance_of(TokenAuthenticatableStrategies::Insecure)
        .to receive(:find_token_authenticatable)
        .and_return('plaintext resource')

      allow(model).to receive(:find_by)
        .with('some_field_encrypted' => encrypted)
        .and_return(nil)

      expect(subject.find_token_authenticatable('my-value'))
        .to eq 'plaintext resource'
    end
  end

  describe '#get_token' do
    it 'decrypts a token when encrypted token is present' do
      allow(instance).to receive(:read_attribute)
        .with('some_field_encrypted')
        .and_return(encrypted)

      expect(subject.get_token(instance)).to eq 'my-value'
    end

    it 'reads a plaintext token when encrypted token is not present' do
      allow(instance).to receive(:read_attribute)
        .with('some_field_encrypted')
        .and_return(nil)

      allow(instance).to receive(:read_attribute)
        .with('some_field')
        .and_return('cleartext value')

      expect(subject.get_token(instance)).to eq 'cleartext value'
    end
  end

  describe '#set_token' do
    it 'writes encrypted token to a model instance' do
      expect(instance).to receive(:[]=)
        .with('some_field_encrypted', encrypted)

      subject.set_token(instance, 'my-value')
    end
  end
end
