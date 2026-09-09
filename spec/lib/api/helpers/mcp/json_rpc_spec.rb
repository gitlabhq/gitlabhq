# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Helpers::Mcp::JsonRpc, feature_category: :mcp_server do
  let(:instance) do
    Class.new do
      include API::Helpers::Mcp::JsonRpc

      attr_reader :params

      def initialize(params)
        @params = params
      end
    end.new({ id: id })
  end

  subject(:request_id) { instance.jsonrpc_request_id }

  context 'when the id is one the JSON-RPC spec allows' do
    where(:id) { [1, 'abc-123'] }

    with_them do
      it 'returns the id unchanged' do
        expect(request_id).to eql(id)
      end
    end
  end

  context 'when the id is any other type' do
    where(:id) { [1.5, true, nil, { 'foo' => 'bar' }, %w[a b]] }

    with_them do
      it 'returns nil so a client is never handed an id it could not have sent' do
        expect(request_id).to be_nil
      end
    end
  end
end
