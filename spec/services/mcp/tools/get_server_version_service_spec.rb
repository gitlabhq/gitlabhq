# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetServerVersionService, feature_category: :mcp_server do
  let(:service_name) { 'get_mcp_server_version' }

  describe 'version registration' do
    it 'registers version 0.1.0' do
      expect(described_class.version_exists?('0.1.0')).to be true
    end

    it 'has 0.1.0 as the latest version' do
      expect(described_class.latest_version).to eq('0.1.0')
    end

    it 'returns available versions in order' do
      expect(described_class.available_versions).to eq(['0.1.0'])
    end
  end

  describe 'version metadata' do
    describe 'version 0.1.0' do
      let(:metadata) { described_class.version_metadata('0.1.0') }

      it 'has correct description' do
        expect(metadata[:description]).to eq('Get the current version of MCP server.')
      end

      it 'has correct input schema' do
        expect(metadata[:input_schema]).to eq({
          type: 'object',
          properties: {},
          required: []
        })
      end
    end
  end

  describe 'initialization' do
    context 'when no version is specified' do
      it 'uses the latest version' do
        service = described_class.new(name: service_name)
        expect(service.version).to eq('0.1.0')
      end
    end

    context 'when version 0.1.0 is specified' do
      it 'uses version 0.1.0' do
        service = described_class.new(name: service_name, version: '0.1.0')
        expect(service.version).to eq('0.1.0')
      end
    end

    context 'when invalid version is specified' do
      it 'raises ArgumentError' do
        expect { described_class.new(name: service_name, version: '1.0.0') }
          .to raise_error(ArgumentError, 'Version 1.0.0 not found. Available: 0.1.0')
      end
    end
  end

  describe '#description' do
    it 'returns correct description' do
      service = described_class.new(name: service_name, version: '0.1.0')
      expect(service.description).to eq('Get the current version of MCP server.')
    end
  end

  describe '#input_schema' do
    it 'returns correct schema' do
      service = described_class.new(name: service_name, version: '0.1.0')
      expect(service.input_schema).to eq({
        type: 'object',
        properties: {},
        required: []
      })
    end
  end

  describe '#execute' do
    let_it_be(:user) { build(:user) }
    let_it_be(:oauth_token) { 'test_token_123' }

    let(:service) { described_class.new(name: service_name, version: '0.1.0') }

    before do
      service.set_cred(current_user: user, access_token: oauth_token)
    end

    context 'when using version 0.1.0' do
      it 'returns GitLab version information' do
        result = service.execute(params: { arguments: {} })

        expect(result).to eq({
          content: [{ type: 'text', text: Gitlab::VERSION }],
          structuredContent: {
            version: Gitlab::VERSION,
            revision: Gitlab.revision
          },
          isError: false
        })
      end

      it 'ignores arguments and returns version information' do
        result = service.execute(params: { arguments: { 'include_revision' => true } })

        expect(result).to eq({
          content: [{ type: 'text', text: Gitlab::VERSION }],
          structuredContent: {
            version: Gitlab::VERSION,
            revision: Gitlab.revision
          },
          isError: false
        })
      end
    end

    context 'when using default version behavior' do
      it 'falls back to 0.1.0 behavior for the default version' do
        result = service.execute(params: { arguments: {} })

        expect(result).to eq({
          content: [{ type: 'text', text: Gitlab::VERSION }],
          structuredContent: {
            version: Gitlab::VERSION,
            revision: Gitlab.revision
          },
          isError: false
        })
      end
    end

    context 'when current_user is not set' do
      it 'returns an error' do
        service_without_user = described_class.new(name: service_name, version: '0.1.0')
        result = service_without_user.execute(params: { arguments: {} })

        expect(result).to eq({
          content: [{ type: 'text', text: "Mcp::Tools::GetServerVersionService: current_user is not set" }],
          structuredContent: {},
          isError: true
        })
      end
    end
  end
end
