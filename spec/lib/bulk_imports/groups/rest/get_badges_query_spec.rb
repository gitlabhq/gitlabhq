# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Rest::GetBadgesQuery do
  describe '.to_h' do
    it 'returns query resource and page info' do
      entity = create(:bulk_import_entity)
      tracker = create(:bulk_import_tracker, entity: entity)
      context = BulkImports::Pipeline::Context.new(tracker)
      encoded_full_path = ERB::Util.url_encode(entity.source_full_path)
      expected = {
        resource: ['groups', encoded_full_path, 'badges'].join('/'),
        query: {
          page: context.tracker.next_page
        }
      }

      expect(described_class.to_h(context)).to eq(expected)
    end
  end
end
