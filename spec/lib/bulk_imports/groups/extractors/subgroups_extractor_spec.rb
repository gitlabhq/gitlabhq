# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Extractors::SubgroupsExtractor do
  describe '#extract' do
    it 'returns ExtractedData response' do
      bulk_import = create(:bulk_import)
      create(:bulk_import_configuration, bulk_import: bulk_import)
      entity = create(:bulk_import_entity, bulk_import: bulk_import)
      tracker = create(:bulk_import_tracker, entity: entity)
      response = [{ 'test' => 'group' }]
      context = BulkImports::Pipeline::Context.new(tracker)

      allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
        allow(client).to receive(:each_page).and_return(response)
      end

      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data).to eq(response)
    end
  end
end
