# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::OauthClient, feature_category: :importers do
  let(:config) do
    Gitlab::Configs::Options.build(
      'app_id' => 'app-id',
      'app_secret' => 'app-secret',
      'verify_ssl' => false,
      'args' => { 'client_options' => { 'site' => 'https://ghe.example.com', 'token_url' => '/oauth/token' } }
    )
  end

  before do
    allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(config)
  end

  describe '.build' do
    it 'builds a client from the GitHub provider config' do
      client = described_class.build

      expect(client).to have_attributes(id: 'app-id', secret: 'app-secret', site: 'https://ghe.example.com')
      expect(client.token_url).to eq('https://ghe.example.com/oauth/token')
      expect(client.options[:connection_opts]).to eq(
        request: { open_timeout: 5, timeout: 10 },
        ssl: { verify: false }
      )
    end

    context 'when the GitHub provider is not configured' do
      let(:config) { nil }

      it 'returns nil' do
        expect(described_class.build).to be_nil
      end
    end
  end

  describe '.refresh_credentials' do
    let(:client) { described_class.build }

    it 'returns the refresh token and both expiry times', :freeze_time do
      token = OAuth2::AccessToken.from_hash(
        client,
        'access_token' => 'ghu_new',
        'refresh_token' => 'ghr_new',
        'expires_in' => 28800,
        'refresh_token_expires_in' => 15897600
      )

      expect(described_class.refresh_credentials(token)).to eq(
        refresh_token: 'ghr_new',
        expires_at: Time.current.to_i + 28800,
        refresh_token_expires_at: Time.current.to_i + 15897600
      )
    end

    it 'returns an empty hash for a token that does not expire' do
      token = OAuth2::AccessToken.from_hash(client, 'access_token' => 'gho_token')

      expect(described_class.refresh_credentials(token)).to eq({})
    end
  end
end
