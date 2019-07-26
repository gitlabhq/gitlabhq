# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::OAuth::Provider do
  describe '.enabled?' do
    before do
      allow(described_class).to receive(:providers).and_return([:ldapmain, :google_oauth2])
    end

    context 'when OmniAuth is disabled' do
      before do
        allow(Gitlab::Auth).to receive(:omniauth_enabled?).and_return(false)
      end

      it 'allows database auth' do
        expect(described_class.enabled?('database')).to be_truthy
      end

      it 'allows LDAP auth' do
        expect(described_class.enabled?('ldapmain')).to be_truthy
      end

      it 'does not allow other OmniAuth providers' do
        expect(described_class.enabled?('google_oauth2')).to be_falsey
      end
    end

    context 'when OmniAuth is enabled' do
      before do
        allow(Gitlab::Auth).to receive(:omniauth_enabled?).and_return(true)
      end

      it 'allows database auth' do
        expect(described_class.enabled?('database')).to be_truthy
      end

      it 'allows LDAP auth' do
        expect(described_class.enabled?('ldapmain')).to be_truthy
      end

      it 'allows other OmniAuth providers' do
        expect(described_class.enabled?('google_oauth2')).to be_truthy
      end
    end
  end

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
