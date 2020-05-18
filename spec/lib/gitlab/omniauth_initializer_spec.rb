# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::OmniauthInitializer do
  let(:devise_config) { class_double(Devise) }

  subject { described_class.new(devise_config) }

  describe '#execute' do
    it 'configures providers from array' do
      generic_config = { 'name' => 'generic' }

      expect(devise_config).to receive(:omniauth).with(:generic)

      subject.execute([generic_config])
    end

    it 'allows "args" array for app_id and app_secret' do
      legacy_config = { 'name' => 'legacy', 'args' => %w(123 abc) }

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

      expect(devise_config).to receive(:omniauth).with(:hash, custom: 'format')

      subject.execute([hash_config])
    end

    it 'normalizes a String strategy_class' do
      hash_config = { 'name' => 'hash', 'args' => { strategy_class: 'OmniAuth::Strategies::OAuth2Generic' } }

      expect(devise_config).to receive(:omniauth).with(:hash, strategy_class: OmniAuth::Strategies::OAuth2Generic)

      subject.execute([hash_config])
    end

    it 'allows a class to be specified in strategy_class' do
      hash_config = { 'name' => 'hash', 'args' => { strategy_class: OmniAuth::Strategies::OAuth2Generic } }

      expect(devise_config).to receive(:omniauth).with(:hash, strategy_class: OmniAuth::Strategies::OAuth2Generic)

      subject.execute([hash_config])
    end

    it 'throws an error for an invalid strategy_class' do
      hash_config = { 'name' => 'hash', 'args' => { strategy_class: 'OmniAuth::Strategies::Bogus' } }

      expect { subject.execute([hash_config]) }.to raise_error(NameError)
    end

    it 'configures fail_with_empty_uid for shibboleth' do
      shibboleth_config = { 'name' => 'shibboleth', 'args' => {} }

      expect(devise_config).to receive(:omniauth).with(:shibboleth, fail_with_empty_uid: true)

      subject.execute([shibboleth_config])
    end

    it 'configures remote_sign_out_handler proc for authentiq' do
      authentiq_config = { 'name' => 'authentiq', 'args' => {} }

      expect(devise_config).to receive(:omniauth).with(:authentiq, remote_sign_out_handler: an_instance_of(Proc))

      subject.execute([authentiq_config])
    end

    it 'configures on_single_sign_out proc for cas3' do
      cas3_config = { 'name' => 'cas3', 'args' => {} }

      expect(devise_config).to receive(:omniauth).with(:cas3, on_single_sign_out: an_instance_of(Proc))

      subject.execute([cas3_config])
    end

    it 'configures defaults for google_oauth2' do
      google_config = {
        'name' => 'google_oauth2',
        "args" => { "access_type" => "offline", "approval_prompt" => '' }
      }

      expect(devise_config).to receive(:omniauth).with(
        :google_oauth2,
        access_type: "offline",
        approval_prompt: "",
        client_options: { connection_opts: { request: { timeout: Gitlab::OmniauthInitializer::OAUTH2_TIMEOUT_SECONDS } } }
      )

      subject.execute([google_config])
    end

    it 'converts client_auth_method to a Symbol for openid_connect' do
      openid_connect_config = {
        'name' => 'openid_connect',
        'args' => { name: 'openid_connect', client_auth_method: 'basic' }
      }

      expect(devise_config).to receive(:omniauth).with(
        :openid_connect,
        { name: 'openid_connect', client_auth_method: :basic }
      )

      subject.execute([openid_connect_config])
    end

    it 'converts client_auth_method to a Symbol for strategy_class OpenIDConnect' do
      openid_connect_config = {
        'name' => 'openid_connect',
        'args' => { strategy_class: OmniAuth::Strategies::OpenIDConnect, client_auth_method: 'jwt_bearer' }
      }

      expect(devise_config).to receive(:omniauth).with(
        :openid_connect,
        { strategy_class: OmniAuth::Strategies::OpenIDConnect, client_auth_method: :jwt_bearer }
      )

      subject.execute([openid_connect_config])
    end
  end
end
