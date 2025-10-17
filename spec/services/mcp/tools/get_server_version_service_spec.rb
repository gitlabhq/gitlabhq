# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetServerVersionService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_mcp_server_version') }
  let(:current_user) { create(:user) }
  let_it_be(:oauth_token) { 'test_token_123' }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq("Get the current version of MCP server.")
    end
  end

  describe '#input_schema' do
    it 'returns the expected JSON schema' do
      schema = service.input_schema
      expect(schema[:type]).to eq('object')
    end
  end

  describe '#execute' do
    before do
      service.set_cred(current_user: current_user, access_token: oauth_token)
    end

    context 'with valid arguments' do
      it 'returns correct gitlab version' do
        response = service.execute(request: nil, params: {})
        expect(response[:isError]).to be false
        expect(response[:content].first[:text]).to eq(Gitlab::VERSION)
      end
    end
  end
end
