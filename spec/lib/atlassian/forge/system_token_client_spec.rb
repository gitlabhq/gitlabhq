# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::Forge::SystemTokenClient, feature_category: :integrations do
  let(:api_base_url) { 'https://api.atlassian.com/ex/jira/cloud-xyz' }
  let(:system_token) { 'sys-token-123' }

  subject(:client) { described_class.new(api_base_url, system_token) }

  describe '#build_uri' do
    it 'appends the bulk path, preserving the apiBaseUrl prefix' do
      expect(client.send(:build_uri, '/rest/devinfo/0.10/bulk').to_s)
        .to eq("#{api_base_url}/rest/devinfo/0.10/bulk")
    end
  end

  describe '#headers' do
    it 'uses the Forge system token as a bearer credential' do
      expect(client.send(:headers, 'https://example.test')).to include(
        'Authorization' => "Bearer #{system_token}",
        'Content-Type' => 'application/json'
      )
    end
  end

  describe 'outbound dev-info push' do
    it 'POSTs to the apiBaseUrl bulk endpoint with bearer auth and the payload' do
      stub = stub_request(:post, "#{api_base_url}/rest/devinfo/0.10/bulk")
        .with(
          headers: { 'Authorization' => "Bearer #{system_token}" },
          body: hash_including('repositories' => [])
        )
        .to_return(status: 202, body: '{}', headers: { 'Content-Type' => 'application/json' })

      client.send(:post, '/rest/devinfo/0.10/bulk', { repositories: [] })

      expect(stub).to have_been_requested
    end
  end
end
