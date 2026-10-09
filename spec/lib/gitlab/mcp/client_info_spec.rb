# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Mcp::ClientInfo, feature_category: :mcp_server do
  describe '.from_request' do
    subject(:client_info) { described_class.from_request(rpc_params, user_agent: user_agent) }

    let(:rpc_params) { {} }
    let(:user_agent) { nil }

    context 'with clientInfo from the initialize handshake' do
      let(:rpc_params) { { protocolVersion: '2025-06-18', clientInfo: { name: 'claude-code', version: '2.1.280' } } }
      let(:user_agent) { 'GitLab-Workhorse-Mcp-Client' }

      it 'ignores it and uses the User-Agent, as later tools/call requests do' do
        expect(client_info.to_h).to eq(mcp_client_name: 'GitLab-Workhorse-Mcp-Client')
      end
    end

    context 'with clientInfo in _meta (stateless revision)' do
      let(:rpc_params) do
        {
          'name' => 'get_issue',
          '_meta' => { described_class::META_KEY => { 'name' => 'Cursor', 'version' => '1.0.0' } },
          'clientInfo' => { 'name' => 'ignored' }
        }
      end

      it 'prefers the _meta clientInfo' do
        expect(client_info.to_h).to eq(mcp_client_name: 'Cursor', mcp_client_version: '1.0.0')
      end
    end

    context 'when _meta has no clientInfo' do
      let(:rpc_params) { { _meta: { progressToken: 1 } } }
      let(:user_agent) { 'Cursor/1.0.0 (darwin arm64)' }

      it 'falls back to the User-Agent' do
        expect(client_info.to_h).to eq(mcp_client_name: 'Cursor', mcp_client_version: '1.0.0')
      end
    end

    context 'when the _meta clientInfo has no usable name' do
      let(:rpc_params) { { _meta: { described_class::META_KEY => { name: { nested: 'object' }, version: '1.0' } } } }
      let(:user_agent) { 'python-httpx/0.27.0' }

      it 'falls back to the User-Agent' do
        expect(client_info.to_h).to eq(mcp_client_name: 'python-httpx', mcp_client_version: '0.27.0')
      end
    end

    context 'when params is an array' do
      let(:rpc_params) { [1, 2] }
      let(:user_agent) { 'undici' }

      it 'falls back to the User-Agent' do
        expect(client_info.to_h).to eq(mcp_client_name: 'undici')
      end
    end

    context 'when no source identifies the client' do
      let(:rpc_params) { nil }
      let(:user_agent) { '   ' }

      it { is_expected.to be_nil }
    end

    context 'when the User-Agent starts with a version separator' do
      let(:user_agent) { '/1.0' }

      it { is_expected.to be_nil }
    end

    context 'with a binary-encoded User-Agent containing non-ASCII bytes' do
      let(:user_agent) { "Cl\xC3\xA9/1.0".b }

      it 'keeps only the leading ASCII product token' do
        expect(client_info.to_h).to eq(mcp_client_name: 'Cl')
      end
    end

    context 'with a UTF-8 User-Agent containing invalid bytes' do
      let(:user_agent) { (+"Cursor\xFF/1.0").force_encoding(Encoding::UTF_8) }

      it 'removes the invalid bytes before parsing' do
        expect(client_info.to_h).to eq(mcp_client_name: 'Cursor', mcp_client_version: '1.0')
      end
    end
  end

  describe '.declared' do
    subject(:client_info) { described_class.declared(rpc_params) }

    context 'with clientInfo from the initialize handshake' do
      let(:rpc_params) do
        { 'protocolVersion' => '2025-06-18', 'clientInfo' => { 'name' => 'mcp-client', 'version' => 'v1.0.0' } }
      end

      it 'uses the declared name and version' do
        expect(client_info.to_h).to eq(mcp_client_name: 'mcp-client', mcp_client_version: 'v1.0.0')
      end
    end

    context 'when clientInfo has no usable name' do
      let(:rpc_params) { { clientInfo: { name: { nested: 'object' }, version: '1.0' } } }

      it { is_expected.to be_nil }
    end

    context 'when params is not a hash' do
      let(:rpc_params) { [1, 2] }

      it { is_expected.to be_nil }
    end

    context 'with oversized client-supplied values' do
      let(:rpc_params) { { clientInfo: { name: 'n' * 500, version: 'v' * 500 } } }

      it 'truncates both' do
        expect(client_info.name.length).to eq(described_class::MAX_LENGTH)
        expect(client_info.version.length).to eq(described_class::MAX_LENGTH)
      end
    end

    context 'with control characters and invalid UTF-8' do
      let(:rpc_params) { { clientInfo: { name: "evil\nclient\e[31m\xFF", version: "1.0\r\n" } } }

      it 'strips them' do
        expect(client_info.to_h).to eq(mcp_client_name: 'evilclient[31m', mcp_client_version: '1.0')
      end
    end

    context 'when the version is blank' do
      let(:rpc_params) { { clientInfo: { name: 'my-client', version: ' ' } } }

      it 'omits the version' do
        expect(client_info.to_h).to eq(mcp_client_name: 'my-client')
      end
    end
  end
end
