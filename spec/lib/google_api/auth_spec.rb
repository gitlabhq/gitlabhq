require 'spec_helper'

describe GoogleApi::Auth do
  let(:redirect_uri) { 'http://localhost:3000/google_api/authorizations/callback' }
  let(:redirect_to) { 'http://localhost:3000/namaspace/project/clusters' }

  let(:client) do
    GoogleApi::CloudPlatform::Client
      .new(nil, redirect_uri, state: redirect_to)
  end

  describe '#authorize_url' do
    subject { client.authorize_url }

    it 'returns authorize_url' do
      is_expected.to start_with('https://accounts.google.com/o/oauth2')
      is_expected.to include(URI.encode(redirect_uri, URI::PATTERN::RESERVED))
      is_expected.to include(URI.encode(redirect_to, URI::PATTERN::RESERVED))
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
      allow_any_instance_of(OAuth2::Strategy::AuthCode)
        .to receive(:get_token).and_return(token)
    end

    it 'returns token and expires_at' do
      token, expires_at = client.get_token('xxx')
      expect(token).to eq('token')
      expect(expires_at).to eq('expires_at')
    end
  end
end
