require 'spec_helper'

describe Gitlab::Auth::OAuth::Provider do
  describe '#config_for' do
    context 'for an LDAP provider' do
      context 'when the provider exists' do
        it 'returns the config' do
          expect(described_class.config_for('ldapmain')).to be_a(Hash)
        end
      end

      context 'when the provider does not exist' do
        it 'returns nil' do
          expect(described_class.config_for('ldapfoo')).to be_nil
        end
      end
    end

    context 'for an OmniAuth provider' do
      before do
        provider = OpenStruct.new(
          name: 'google',
          app_id: 'asd123',
          app_secret: 'asd123'
        )
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
      end

      context 'when the provider exists' do
        it 'returns the config' do
          expect(described_class.config_for('google')).to be_a(OpenStruct)
        end
      end

      context 'when the provider does not exist' do
        it 'returns nil' do
          expect(described_class.config_for('foo')).to be_nil
        end
      end
    end
  end
end
