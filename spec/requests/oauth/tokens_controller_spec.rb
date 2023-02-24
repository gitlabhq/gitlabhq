# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokensController, feature_category: :system_access do
  let(:cors_request_headers) { { 'Origin' => 'http://notgitlab.com' } }
  let(:other_headers) { {} }
  let(:headers) { cors_request_headers.merge(other_headers) }
  let(:allowed_methods) { 'POST, OPTIONS' }
  let(:authorization_methods) { %w[Authorization X-CSRF-Token X-Requested-With] }

  shared_examples 'cross-origin POST request' do
    it 'allows cross-origin requests' do
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Methods']).to eq allowed_methods
      expect(response.headers['Access-Control-Allow-Headers']).to be_nil
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  shared_examples 'CORS preflight OPTIONS request' do
    it 'returns 200' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'allows cross-origin requests' do
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Methods']).to eq allowed_methods
      expect(response.headers['Access-Control-Allow-Headers']).to eq authorization_methods
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  describe 'POST /oauth/token' do
    before do
      post '/oauth/token', headers: headers
    end

    it_behaves_like 'cross-origin POST request'
  end

  describe 'OPTIONS /oauth/token' do
    let(:other_headers) { { 'Access-Control-Request-Headers' => authorization_methods, 'Access-Control-Request-Method' => 'POST' } }

    before do
      options '/oauth/token', headers: headers
    end

    it_behaves_like 'CORS preflight OPTIONS request'
  end

  describe 'POST /oauth/revoke' do
    let(:other_headers) { { 'Content-Type' => 'application/x-www-form-urlencoded' } }

    before do
      post '/oauth/revoke', headers: headers, params: { token: '12345' }
    end

    it 'returns 200' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'cross-origin POST request'
  end

  describe 'OPTIONS /oauth/revoke' do
    let(:other_headers) { { 'Access-Control-Request-Headers' => authorization_methods, 'Access-Control-Request-Method' => 'POST' } }

    before do
      options '/oauth/revoke', headers: headers
    end

    it_behaves_like 'CORS preflight OPTIONS request'
  end
end
