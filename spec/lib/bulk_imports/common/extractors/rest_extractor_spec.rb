# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Extractors::RestExtractor do
  let(:http_client) { instance_double(BulkImports::Clients::HTTP) }
  let(:options) { { query: double(to_h: { resource: nil, query: nil }) } }
  let(:response) { double(parsed_response: { 'data' => { 'foo' => 'bar' } }, headers: { 'x-next-page' => '2' }) }

  subject { described_class.new(options) }

  describe '#extract' do
    before do
      allow(subject).to receive(:http_client).and_return(http_client)
      allow(http_client).to receive(:get).and_return(response)
    end

    it 'returns instance of ExtractedData' do
      entity = create(:bulk_import_entity)
      tracker = create(:bulk_import_tracker, entity: entity)
      context = BulkImports::Pipeline::Context.new(tracker)

      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data).to contain_exactly(response.parsed_response)
      expect(extracted_data.next_page).to eq(response.headers['x-next-page'])
      expect(extracted_data.has_next_page?).to eq(true)
    end
  end
end
