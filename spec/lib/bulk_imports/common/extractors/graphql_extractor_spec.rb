# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Extractors::GraphqlExtractor do
  let(:graphql_client) { instance_double(BulkImports::Clients::Graphql) }
  let(:import_entity) { create(:bulk_import_entity) }
  let(:response) { double(original_hash: { foo: :bar }) }
  let(:query) { { query: double(to_s: 'test', variables: {}) } }
  let(:context) do
    instance_double(
      BulkImports::Pipeline::Context,
      entity: import_entity
    )
  end

  subject { described_class.new(query) }

  before do
    allow(subject).to receive(:graphql_client).and_return(graphql_client)
    allow(graphql_client).to receive(:parse)
  end

  describe '#extract' do
    before do
      allow(subject).to receive(:query_variables).and_return({})
      allow(graphql_client).to receive(:execute).and_return(response)
    end

    it 'returns an enumerator with fetched results' do
      response = subject.extract(context)

      expect(response).to be_instance_of(Enumerator)
      expect(response.first).to eq({ foo: :bar })
    end
  end

  describe 'query variables' do
    before do
      allow(graphql_client).to receive(:execute).and_return(response)
    end

    context 'when variables are present' do
      let(:variables) { { foo: :bar } }
      let(:query) { { query: double(to_s: 'test', variables: variables) } }

      it 'builds graphql query variables for import entity' do
        expect(graphql_client).to receive(:execute).with(anything, variables)

        subject.extract(context).first
      end
    end

    context 'when no variables are present' do
      let(:query) { { query: double(to_s: 'test', variables: nil) } }

      it 'returns empty hash' do
        expect(graphql_client).to receive(:execute).with(anything, nil)

        subject.extract(context).first
      end
    end

    context 'when variables are empty hash' do
      let(:query) { { query: double(to_s: 'test', variables: {}) } }

      it 'makes graphql request with empty hash' do
        expect(graphql_client).to receive(:execute).with(anything, {})

        subject.extract(context).first
      end
    end
  end
end
