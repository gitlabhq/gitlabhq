# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OmniauthInitializer, feature_category: :system_access do
  include LoginHelpers

  let(:devise_config) { class_double(Devise) }

  subject(:initializer) { described_class.new(devise_config) }

  describe '.arguments_for' do
    let(:devise_config) { nil }

    let(:arguments) { initializer.send(:arguments_for, provider) }

    context 'when there are no args at all' do
      let(:provider) { { 'name' => 'unknown' } }

      it 'returns an empty array' do
        expect(arguments).to eq []
      end
    end

    context 'when there is an app_id and an app_secret' do
      let(:provider) { { 'name' => 'unknown', 'app_id' => 1, 'app_secret' => 2 } }

      it 'includes both of them, in positional order' do
        expect(arguments).to eq [1, 2]
      end
    end

    context 'when there is an app_id and an app_secret, and an array of args' do
      let(:provider) do
        {
          'name' => 'unknown',
          'app_id' => 1,
          'app_secret' => 2,
          'args' => %w[one two three]
        }
      end

      it 'concatenates the args on the end' do
        expect(arguments).to eq [1, 2, 'one', 'two', 'three']
      end
    end

    context 'when there is an app_id and an app_secret, and an array of args, and default values' do
      let(:provider) do
        {
          'name' => 'unknown',
          'app_id' => 1,
          'app_secret' => 2,
          'args' => %w[one two three]
        }
      end

      before do
        expect(described_class)
          .to receive(:default_arguments_for).with('unknown')
          .and_return({ default_arg: :some_value })
      end

      it 'concatenates the args on the end' do
        expect(arguments)
          .to eq [1, 2, 'one', 'two', 'three', { default_arg: :some_value }]
      end
    end

    context 'when there is an app_id and an app_secret, and a hash of args' do
      let(:provider) do
        {
          'name' => 'unknown',
          'app_id' => 1,
          'app_secret' => 2,
          'args' => { 'foo' => 100, 'bar' => 200, 'nested' => { 'value' => 300 } }
        }
      end

      it 'concatenates the args on the end' do
        expect(arguments)
          .to eq [1, 2, { foo: 100, bar: 200, nested: { value: 300 } }]
      end
    end

    context 'when there is an app_id and an app_secret, and a hash of args, and default arguments' do
      let(:provider) do
        {
          'name' => 'unknown',
          'app_id' => 1,
          'app_secret' => 2,
          'args' => { 'foo' => 100, 'bar' => 200, 'nested' => { 'value' => 300 } }
        }
      end

      before do
        expect(described_class)
          .to receive(:default_arguments_for).with('unknown')
          .and_return({ default_arg: :some_value })
      end

      it 'concatenates the args on the end' do
        expect(arguments)
          .to eq [1, 2, { default_arg: :some_value, foo: 100, bar: 200, nested: { value: 300 } }]
      end
    end

    context 'when there is an app_id and an app_secret, no args, and default values' do
      let(:provider) do
        {
          'name' => 'unknown',
          'app_id' => 1,
          'app_secret' => 2
        }
      end

      before do
        expect(described_class)
          .to receive(:default_arguments_for).with('unknown')
          .and_return({ default_arg: :some_value })
      end

      it 'concatenates the args on the end' do
        expect(arguments)
          .to eq [1, 2, { default_arg: :some_value }]
      end
    end

    context 'when there are args, of an unsupported type' do
      let(:provider) do
        {
          'name' => 'unknown',
          'args' => 1
        }
      end

      context 'when there are default arguments' do
        before do
          expect(described_class)
            .to receive(:default_arguments_for).with('unknown')
            .and_return({ default_arg: :some_value })
        end

        it 'tracks a configuration error' do
          expect(::Gitlab::ErrorTracking)
            .to receive(:track_and_raise_for_dev_exception)
            .with(described_class::ConfigurationError, provider_name: 'unknown', arguments_type: 'Integer')

          expect(arguments)
            .to eq [{ default_arg: :some_value }]
        end
      end

      context 'when there are no default arguments' do
        it 'tracks a configuration error' do
          expect(::Gitlab::ErrorTracking)
            .to receive(:track_and_raise_for_dev_exception)
            .with(described_class::ConfigurationError, provider_name: 'unknown', arguments_type: 'Integer')

          expect(arguments).to be_empty
        end
      end
    end
  end

  describe '#execute' do
    it 'configures providers from array' do
      generic_config = { 'name' => 'generic' }

      expect(devise_config).to receive(:omniauth).with(:generic)

      subject.execute([generic_config])
    end

    it 'allows "args" array for app_id and app_secret' do
      legacy_config = { 'name' => 'legacy', 'args' => %w[123 abc] }

      expect(devise_config).to receive(:omniauth).with(:legacy, '123', 'abc')

      subject.execute([legacy_config])
    end

    it 'passes app_id and app_secret as additional arguments' do
      twitter_config = { 'name' => 'twitter', 'app_id' => '123', 'app_secret' => 'abc' }

      expect(devise_config).to receive(:omniauth).with(:twitter, '123', 'abc')

      subject.execute([twitter_config])
    end

    it 'passes "args" hash as symbolized hash argument' do
      hash_config = { 'name' => 'hash', 'args' => { 'custom' => 'format' } }

      expect(devise_config).to receive(:omniauth).with(:hash, { custom: 'format' })

      subject.execute([hash_config])
    end

    it 'normalizes a String strategy_class' do
      hash_config = { 'name' => 'hash', 'args' => { strategy_class: 'OmniAuth::Strategies::OAuth2Generic' } }

      expect(devise_config).to receive(:omniauth).with(:hash, { strategy_class: OmniAuth::Strategies::OAuth2Generic })

      subject.execute([hash_config])
    end

    it 'allows a class to be specified in strategy_class' do
      hash_config = { 'name' => 'hash', 'args' => { strategy_class: OmniAuth::Strategies::OAuth2Generic } }

      expect(devise_config).to receive(:omniauth).with(:hash, { strategy_class: OmniAuth::Strategies::OAuth2Generic })

      subject.execute([hash_config])
    end

    it 'throws an error for an invalid strategy_class' do
      hash_config = { 'name' => 'hash', 'args' => { strategy_class: 'OmniAuth::Strategies::Bogus' } }

      expect { subject.execute([hash_config]) }.to raise_error(NameError)
    end

    it 'configures fail_with_empty_uid for shibboleth' do
      shibboleth_config = { 'name' => 'shibboleth', 'args' => {} }

      expect(devise_config).to receive(:omniauth).with(:shibboleth, { fail_with_empty_uid: true })

      subject.execute([shibboleth_config])
    end

    context 'when SAML providers are configured' do
      it 'configures default args for a single SAML provider' do
        stub_omniauth_config(providers: [{ name: 'saml', args: { idp_sso_service_url: 'https://saml.example.com' } }])

        expect(devise_config).to receive(:omniauth).with(
          :saml,
          {
            idp_sso_service_url: 'https://saml.example.com',
            attribute_statements: ::Gitlab::Auth::Saml::Config.default_attribute_statements
          }
        )

        initializer.execute(Gitlab.config.omniauth.providers)
      end

      context 'when configuration provides matching keys' do
        before do
          stub_omniauth_config(
            providers: [
              {
                name: 'saml',
                args: { idp_sso_service_url: 'https://saml.example.com', attribute_statements: { email: ['custom_attr'] } }
              }
            ]
          )
        end

        it 'merges arguments with user configuration preference' do
          expect(devise_config).to receive(:omniauth).with(
            :saml,
            {
              idp_sso_service_url: 'https://saml.example.com',
              attribute_statements: ::Gitlab::Auth::Saml::Config.default_attribute_statements
                                                                .merge({ email: ['custom_attr'] })
            }
          )

          initializer.execute(Gitlab.config.omniauth.providers)
        end

        it 'merges arguments with defaults preference when REVERT_OMNIAUTH_DEFAULT_MERGING is true' do
          stub_env('REVERT_OMNIAUTH_DEFAULT_MERGING', 'true')

          expect(devise_config).to receive(:omniauth).with(
            :saml,
            {
              idp_sso_service_url: 'https://saml.example.com',
              attribute_statements: ::Gitlab::Auth::Saml::Config.default_attribute_statements
            }
          )

          initializer.execute(Gitlab.config.omniauth.providers)
        end
      end

      it 'configures defaults args for multiple SAML providers' do
        stub_omniauth_config(
          providers: [
            { name: 'saml', args: { idp_sso_service_url: 'https://saml.example.com' } },
            {
              name: 'saml2',
              args: { strategy_class: 'OmniAuth::Strategies::SAML', idp_sso_service_url: 'https://saml2.example.com' }
            }
          ]
        )

        expect(devise_config).to receive(:omniauth).with(
          :saml,
          {
            idp_sso_service_url: 'https://saml.example.com',
            attribute_statements: ::Gitlab::Auth::Saml::Config.default_attribute_statements
          }
        )
        expect(devise_config).to receive(:omniauth).with(
          :saml2,
          {
            idp_sso_service_url: 'https://saml2.example.com',
            strategy_class: OmniAuth::Strategies::SAML,
            attribute_statements: ::Gitlab::Auth::Saml::Config.default_attribute_statements
          }
        )

        initializer.execute(Gitlab.config.omniauth.providers)
      end

      it 'merges arguments with user configuration preference for custom SAML provider' do
        stub_omniauth_config(
          providers: [
            {
              name: 'custom_saml',
              args: {
                strategy_class: 'OmniAuth::Strategies::SAML',
                idp_sso_service_url: 'https://saml2.example.com',
                attribute_statements: { email: ['custom_attr'] }
              }
            }
          ]
        )

        expect(devise_config).to receive(:omniauth).with(
          :custom_saml,
          {
            idp_sso_service_url: 'https://saml2.example.com',
            strategy_class: OmniAuth::Strategies::SAML,
            attribute_statements: ::Gitlab::Auth::Saml::Config.default_attribute_statements
                                                              .merge({ email: ['custom_attr'] })
          }
        )

        initializer.execute(Gitlab.config.omniauth.providers)
      end
    end

    it 'configures defaults for google_oauth2' do
      google_config = {
        'name' => 'google_oauth2',
        "args" => { "access_type" => "offline", "approval_prompt" => '' }
      }

      expect(devise_config).to receive(:omniauth).with(
        :google_oauth2, {
          access_type: "offline",
          approval_prompt: "",
          client_options: { connection_opts: { request: { timeout: Gitlab::OmniauthInitializer::OAUTH2_TIMEOUT_SECONDS } } }
        })

      subject.execute([google_config])
    end

    it 'configures defaults for gitlab' do
      conf = {
        'name' => 'gitlab',
        "args" => { 'client_options' => { 'site' => generate(:url) } }
      }

      expect(devise_config).to receive(:omniauth).with(
        :gitlab, {
          client_options: { site: conf.dig('args', 'client_options', 'site') },
          authorize_params: { gl_auth_type: 'login' }
        })

      subject.execute([conf])
    end

    it 'configures defaults for gitlab, when arguments are not provided' do
      conf = { 'name' => 'gitlab' }

      expect(devise_config).to receive(:omniauth).with(
        :gitlab, {
          authorize_params: { gl_auth_type: 'login' }
        })

      subject.execute([conf])
    end

    it 'configures defaults for gitlab, when array arguments are provided' do
      conf = { 'name' => 'gitlab', 'args' => ['a'] }

      expect(devise_config).to receive(:omniauth).with(
        :gitlab,
        'a',
        { authorize_params: { gl_auth_type: 'login' } }
      )

      subject.execute([conf])
    end

    it 'tracks a configuration error if the arguments are neither a hash nor an array' do
      conf = { 'name' => 'gitlab', 'args' => 17 }

      expect(::Gitlab::ErrorTracking)
        .to receive(:track_and_raise_for_dev_exception)
        .with(described_class::ConfigurationError, provider_name: 'gitlab', arguments_type: 'Integer')

      expect(devise_config).to receive(:omniauth).with(
        :gitlab,
        { authorize_params: { gl_auth_type: 'login' } }
      )

      subject.execute([conf])
    end
  end

  describe '.full_host' do
    subject { described_class.full_host.call({}) }

    let(:base_url) { 'http://localhost/test' }

    before do
      allow(Settings).to receive(:gitlab).and_return({ 'base_url' => base_url })
    end

    it { is_expected.to eq(base_url) }
  end
end
