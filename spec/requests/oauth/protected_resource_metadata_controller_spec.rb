# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::ProtectedResourceMetadataController, feature_category: :system_access do
  describe 'GET /.well-known/oauth-protected-resource' do
    let(:protected_resource_path) { Gitlab::Routing.url_helpers.oauth_protected_resource_metadata_path }
    let(:expected_response) do
      {
        'resource' => [
          "#{Gitlab.config.gitlab.url}/api/v4/mcp"
        ],
        'authorization_servers' => [
          Gitlab.config.gitlab.url
        ]
      }
    end

    before do
      get protected_resource_path
    end

    it 'returns 200 status' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns correct content type' do
      expect(response.content_type).to eq('application/json; charset=utf-8')
    end

    it 'returns the expected JSON structure' do
      expect(response.parsed_body).to eq(expected_response)
    end

    it 'includes correct caching headers' do
      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('max-age=86400')
      expect(cache_control).to include('public')
      expect(cache_control).to include('must-revalidate')
      expect(cache_control).to include('no-transform')
    end

    context 'when using custom base URL' do
      let(:custom_host) { 'https://custom-gitlab.example.com' }

      before do
        stub_config_setting(url: custom_host)

        get protected_resource_path
      end

      it 'returns metadata with custom base URL' do
        expected_custom_response = {
          'resource' => [
            "#{custom_host}/api/v4/mcp"
          ],
          'authorization_servers' => [
            custom_host
          ]
        }

        expect(response.parsed_body).to eq(expected_custom_response)
      end
    end

    context 'without authentication' do
      it 'does not require authentication' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with authenticated user' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)

        get protected_resource_path
      end

      it 'returns the same response as unauthenticated request' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.parsed_body).to eq(expected_response)
      end
    end

    context 'when validating response' do
      it 'contains required fields' do
        response_body = response.parsed_body

        expect(response_body).to have_key('resource')
        expect(response_body).to have_key('authorization_servers')
      end

      it 'has correct resource format' do
        resource_urls = response.parsed_body['resource']
        expect(resource_urls.size).to eq(1)

        expect(resource_urls).to all be_a(String)
        expect(resource_urls).to all match(%r{\Ahttps?://})

        expect(resource_urls.first).to end_with('/api/v4/mcp')
      end

      it 'has correct authorization_servers format' do
        auth_servers = response.parsed_body['authorization_servers']

        expect(auth_servers).to be_a(Array)
        expect(auth_servers.length).to eq(1)
        expect(auth_servers.first).to be_a(String)
        expect(auth_servers.first).to match(%r{\Ahttps?://})
      end

      it 'authorization_servers contains the same base URL as resource' do
        response_body = response.parsed_body
        resource_base = response_body['resource'][0].gsub('/api/v4/mcp', '')
        auth_server = response_body['authorization_servers'].first

        expect(auth_server).to eq(resource_base)
      end
    end

    context 'when relative_url_root is configured' do
      let(:relative_url_root) { '/gitlab' }
      let(:base_url_with_root) { "http://localhost#{relative_url_root}" }

      before do
        stub_config_setting(relative_url_root: relative_url_root, url: base_url_with_root)
        get protected_resource_path
      end

      it 'includes relative_url_root in resource URLs' do
        resource_urls = response.parsed_body['resource']
        expect(resource_urls.first).to eq("#{base_url_with_root}/api/v4/mcp")
      end

      it 'includes relative_url_root in authorization_servers' do
        auth_servers = response.parsed_body['authorization_servers']
        expect(auth_servers.first).to eq(base_url_with_root)
      end

      it 'maintains consistency between resource and authorization_servers' do
        response_body = response.parsed_body
        resource_base = response_body['resource'][0].gsub('/api/v4/mcp', '')
        auth_server = response_body['authorization_servers'].first

        expect(auth_server).to eq(resource_base)
      end
    end
  end
end
