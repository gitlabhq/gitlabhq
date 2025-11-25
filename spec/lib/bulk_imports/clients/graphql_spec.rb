# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Clients::Graphql, feature_category: :importers do
  let_it_be(:config) { create(:bulk_import_configuration) }

  subject { described_class.new(url: config.url, token: config.access_token) }

  describe '#execute' do
    describe 'network errors' do
      context 'when response cannot be parsed' do
        it 'raises network error' do
          stub_request(:post, "https://gitlab.example/api/graphql")
          .with(
            body: { "query" => "test", "operationName" => nil, variables: {} }.to_json,
            headers: { 'Authorization' => "Bearer #{config.access_token}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: 'invalid', headers: { 'Content-Type' => 'application/json' })

          expect { subject.execute(query: 'test') }.to raise_error(BulkImports::NetworkError, /unexpected character/)
        end
      end

      context 'when response is unsuccessful' do
        it 'raises network error' do
          stub_request(:post, "https://gitlab.example/api/graphql")
          .with(
            body: { "query" => "test", "operationName" => nil, variables: {} }.to_json,
            headers: { 'Authorization' => "Bearer #{config.access_token}", 'Content-Type' => 'application/json' })
          .to_return(status: 503)

          expect { subject.execute(query: 'test') }.to raise_error(BulkImports::NetworkError, 'Unsuccessful response 503 from /api/graphql')
        end
      end
    end
  end
end
