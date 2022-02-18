# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Extractors::GraphqlExtractor do
  let(:graphql_client) { instance_double(BulkImports::Clients::Graphql) }
  let(:import_entity) { create(:bulk_import_entity) }
  let(:response) { double(original_hash: { 'data' => { 'foo' => 'bar' }, 'page_info' => {} }) }
  let(:options) do
    {
      query:
        double(
          new: double(
            to_s: 'test',
            variables: {},
            data_path: %w[data foo],
            page_info_path: %w[data page_info]
          )
        )
    }
  end

  let(:context) do
    instance_double(
      BulkImports::Pipeline::Context,
      entity: import_entity
    )
  end

  subject { described_class.new(options) }

  describe '#extract' do
    before do
      allow(subject).to receive(:graphql_client).and_return(graphql_client)
      allow(graphql_client).to receive(:parse)
      allow(graphql_client).to receive(:execute).and_return(response)
    end

    it 'returns ExtractedData' do
      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data).to contain_exactly('bar')
    end
  end
end
