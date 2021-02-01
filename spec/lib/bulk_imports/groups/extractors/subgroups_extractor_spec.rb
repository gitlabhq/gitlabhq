# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Extractors::SubgroupsExtractor do
  describe '#extract' do
    it 'returns ExtractedData response' do
      user = create(:user)
      bulk_import = create(:bulk_import)
      entity = create(:bulk_import_entity, bulk_import: bulk_import)
      configuration = create(:bulk_import_configuration, bulk_import: bulk_import)
      response = [{ 'test' => 'group' }]
      context = BulkImports::Pipeline::Context.new(
        current_user: user,
        entity: entity,
        configuration: configuration
      )

      allow_next_instance_of(BulkImports::Clients::Http) do |client|
        allow(client).to receive(:each_page).and_return(response)
      end

      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data).to eq(response)
    end
  end
end
