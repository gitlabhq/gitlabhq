# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleApi::Auth do
  let(:redirect_uri) { 'http://localhost:3000/google_api/authorizations/callback' }
  let(:redirect_to) { 'http://localhost:3000/namaspace/project/clusters' }

  let(:client) do
    GoogleApi::CloudPlatform::Client
      .new(nil, redirect_uri, state: redirect_to)
  end

  describe '#authorize_url' do
    subject { Addressable::URI.parse(client.authorize_url) }

    it 'returns authorize_url' do
      expect(subject.to_s).to start_with('https://accounts.google.com/o/oauth2')
      expect(subject.query_values['state']).to eq(redirect_to)
      expect(subject.query_values['redirect_uri']).to eq(redirect_uri)
    end
  end

  describe '#get_token' do
    let(:token) do
      double.tap do |dbl|
        allow(dbl).to receive(:token).and_return('token')
        allow(dbl).to receive(:expires_at).and_return('expires_at')
      end
    end

    before do
      allow_next_instance_of(OAuth2::Strategy::AuthCode) do |instance|
        allow(instance).to receive(:get_token).and_return(token)
      end
    end

    it 'returns token and expires_at' do
      token, expires_at = client.get_token('xxx')
      expect(token).to eq('token')
      expect(expires_at).to eq('expires_at')
    end

    it 'expects the client to receive default options' do
      config = Gitlab::Auth::OAuth::Provider.config_for('google_oauth2')

      expect(OAuth2::Client).to receive(:new).with(
        config.app_id,
        config.app_secret,
        hash_including(
          **config.args.client_options.deep_symbolize_keys
        )
      ).and_call_original

      client.get_token('xxx')
    end
  end
end
