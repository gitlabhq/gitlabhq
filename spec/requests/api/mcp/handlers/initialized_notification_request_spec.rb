# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'Initialized notification request', feature_category: :api do
  let_it_be(:user) { create(:user) }

  describe 'POST /mcp with notifications/initialized method' do
    let(:params) do
      {
        jsonrpc: '2.0',
        method: 'notifications/initialized'
      }
    end

    before do
      post api('/mcp', user), params: params
    end

    it 'returns no content' do
      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns empty body for notification' do
      expect(response.body).to be_empty
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
