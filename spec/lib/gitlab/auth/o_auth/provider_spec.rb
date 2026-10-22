# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::Provider, feature_category: :system_access do
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

  describe '.sign_in_enabled?' do
    before do
      allow(described_class).to receive(:providers).and_return([:ldapmain, :google_oauth2, :saml])
      allow(Gitlab::Auth).to receive(:omniauth_enabled?).and_return(true)
    end

    it 'returns false for a provider that is not enabled' do
      expect(described_class.sign_in_enabled?(:github)).to be(false)
    end

    context 'with an OmniAuth provider' do
      it 'returns true when the provider is not disabled for sign-in' do
        expect(described_class.sign_in_enabled?(:saml)).to be(true)
      end

      it 'accepts the provider name as a string' do
        expect(described_class.sign_in_enabled?('saml')).to be(true)
      end

      context 'when the provider is disabled under sign-in restrictions' do
        before do
          stub_application_setting(disabled_oauth_sign_in_sources: ['saml'])
        end

        it 'returns false for that provider' do
          expect(described_class.sign_in_enabled?(:saml)).to be(false)
        end

        it 'returns true for other providers' do
          expect(described_class.sign_in_enabled?(:google_oauth2)).to be(true)
        end
      end
    end

    context 'with the database provider' do
      it 'returns true when password authentication for the web is enabled' do
        stub_application_setting(password_authentication_enabled_for_web: true)

        expect(described_class.sign_in_enabled?('database')).to be(true)
      end

      it 'returns false when password authentication for the web is disabled' do
        stub_application_setting(password_authentication_enabled_for_web: false)

        expect(described_class.sign_in_enabled?('database')).to be(false)
      end
    end

    context 'with an LDAP provider' do
      it 'returns true when LDAP sign-in is enabled' do
        allow(Gitlab::Auth::Ldap::Config).to receive(:sign_in_enabled?).and_return(true)

        expect(described_class.sign_in_enabled?('ldapmain')).to be(true)
      end

      it 'returns false when LDAP sign-in is prevented' do
        allow(Gitlab::Auth::Ldap::Config).to receive(:sign_in_enabled?).and_return(false)

        expect(described_class.sign_in_enabled?('ldapmain')).to be(false)
      end

      it 'returns false for an LDAP provider that is not registered' do
        allow(Gitlab::Auth::Ldap::Config).to receive(:sign_in_enabled?).and_return(true)

        expect(described_class.sign_in_enabled?('ldapsecondary')).to be(false)
      end
    end
  end

  describe '.config_for' do
    context 'for an LDAP provider' do
      context 'when the provider exists' do
        it 'returns the config' do
          expect(described_class.config_for('ldapmain')).to be_a(Gitlab::Configs::Options)
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
        provider = Gitlab::Configs.build_options(
          name: 'google_oauth2',
          app_id: 'asd123',
          app_secret: 'asd123'
        )
        openid_connect = Gitlab::Configs.build_options(name: 'openid_connect')

        stub_omniauth_setting(providers: [provider, openid_connect])
      end

      context 'when the provider exists' do
        subject(:config) { described_class.config_for('google_oauth2') }

        it 'returns the config' do
          expect(config).to be_a(Gitlab::Configs::Options)
        end

        it 'merges defaults with the given configuration' do
          defaults = Gitlab::OmniauthInitializer.default_arguments_for('google_oauth2').deep_stringify_keys

          expect(config['args']).to include(defaults)
        end
      end

      context 'when the provider does not exist' do
        it 'returns nil' do
          expect(described_class.config_for('foo')).to be_nil
        end
      end
    end

    context 'for an OpenID Connect provider' do
      context 'when the default oidc provider exists' do
        before do
          provider = ActiveSupport::InheritableOptions.new(
            name: 'openid_connect',
            args: ActiveSupport::InheritableOptions.new(name: 'custom_oidc')
          )
          allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
        end

        subject(:config) { described_class.config_for('custom_oidc') }

        it 'returns the config' do
          expect(config).to be_a(ActiveSupport::InheritableOptions)
          expect(config.name).to eq('openid_connect')
          expect(config.args.name).to eq('custom_oidc')
        end
      end

      context 'when an oidc provider with a strategy exists' do
        before do
          provider = ActiveSupport::InheritableOptions.new(
            name: 'openid_connect2',
            args: ActiveSupport::InheritableOptions.new(
              name: 'openid_connect2_inner',
              strategy_class: 'OmniAuth::Strategies::OpenIDConnect'
            )
          )
          allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
        end

        subject(:config) { described_class.config_for('openid_connect2') }

        it 'returns the config' do
          expect(config).to be_a(ActiveSupport::InheritableOptions)
          expect(config.name).to eq('openid_connect2')
          expect(config.args.name).to eq('openid_connect2_inner')
          expect(config.args.strategy_class).to eq('OmniAuth::Strategies::OpenIDConnect')
        end
      end

      context 'when the provider does not exist' do
        subject(:config) { described_class.config_for('') }

        it 'returns nil' do
          expect(config).to be_nil
        end
      end

      context 'when provider has a custom name in args' do
        let(:provider_config) do
          Gitlab::Configs.build_options({
            'name' => 'openid_connect',
            'args' => Gitlab::Configs.build_options({
              'name' => 'my_custom_provider',
              'gitlab_username_claim' => 'preferred_username'
            })
          })
        end

        before do
          allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider_config])
        end

        it 'returns the config when searching by custom name' do
          config = described_class.config_for('my_custom_provider')
          expect(config).to be_a(Gitlab::Configs::Options)
          expect(config.name).to eq('openid_connect')
          expect(config.dig('args', 'name')).to eq('my_custom_provider')
          expect(config.dig('args', 'gitlab_username_claim')).to eq('preferred_username')
        end
      end
    end
  end

  describe '.label_for' do
    subject(:label_for) { described_class.label_for(name) }

    context 'when configuration specifies a custom label' do
      let(:name) { 'google_oauth2' }
      let(:label) { 'Custom Google Provider' }
      let(:provider) { ActiveSupport::InheritableOptions.new(name: name, label: label) }

      before do
        stub_omniauth_setting(providers: [provider])
      end

      it 'returns the custom label name' do
        expect(label_for).to eq(label)
      end
    end

    context 'when configuration does not specify a custom label' do
      let(:provider) { ActiveSupport::InheritableOptions.new(name: name) }

      before do
        stub_omniauth_setting(providers: [provider])
      end

      context 'when the name does not correspond to a label mapping' do
        let(:name) { 'twitter' }

        it 'returns the titleized name' do
          expect(label_for).to eq(name.titleize)
        end
      end
    end

    context 'when the name corresponds to a label mapping' do
      let(:name) { 'gitlab' }

      it 'returns the mapped name' do
        expect(label_for).to eq('GitLab.com')
      end
    end
  end
end
