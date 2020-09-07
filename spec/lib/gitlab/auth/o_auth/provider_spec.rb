# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::Provider do
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

  describe '.config_for' do
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
          name: 'google_oauth2',
          app_id: 'asd123',
          app_secret: 'asd123'
        )
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
      end

      context 'when the provider exists' do
        subject { described_class.config_for('google_oauth2') }

        it 'returns the config' do
          expect(subject).to be_a(OpenStruct)
        end

        it 'merges defaults with the given configuration' do
          defaults = Gitlab::OmniauthInitializer.default_arguments_for('google_oauth2').deep_stringify_keys

          expect(subject['args']).to include(defaults)
        end
      end

      context 'when the provider does not exist' do
        it 'returns nil' do
          expect(described_class.config_for('foo')).to be_nil
        end
      end
    end
  end

  describe '.label_for' do
    subject { described_class.label_for(name) }

    context 'when configuration specifies a custom label' do
      let(:name) { 'google_oauth2' }
      let(:label) { 'Custom Google Provider' }
      let(:provider) { OpenStruct.new({ 'name' => name, 'label' => label }) }

      before do
        stub_omniauth_setting(providers: [provider])
      end

      it 'returns the custom label name' do
        expect(subject).to eq(label)
      end
    end

    context 'when configuration does not specify a custom label' do
      let(:provider) { OpenStruct.new({ 'name' => name } ) }

      before do
        stub_omniauth_setting(providers: [provider])
      end

      context 'when the name does not correspond to a label mapping' do
        let(:name) { 'twitter' }

        it 'returns the titleized name' do
          expect(subject).to eq(name.titleize)
        end
      end
    end

    context 'when the name corresponds to a label mapping' do
      let(:name) { 'gitlab' }

      it 'returns the mapped name' do
        expect(subject).to eq('GitLab.com')
      end
    end
  end
end
