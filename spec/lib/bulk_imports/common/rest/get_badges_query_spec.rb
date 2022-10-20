# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Rest::GetBadgesQuery do
  describe '.to_h' do
    shared_examples 'resource and page info query' do
      let(:tracker) { create(:bulk_import_tracker, entity: entity) }
      let(:context) { BulkImports::Pipeline::Context.new(tracker) }
      let(:encoded_full_path) { ERB::Util.url_encode(entity.source_full_path) }

      context 'when source id is present' do
        it 'returns correct query using source id and page info' do
          expected = {
            resource: [entity.base_resource_path, 'badges'].join('/'),
            query: {
              page: context.tracker.next_page
            }
          }

          expect(described_class.to_h(context)).to eq(expected)
        end
      end

      context 'when source id is missing' do
        it 'returns correct query using source full path' do
          entity.update!(source_xid: nil)

          expected = {
            resource: ["/#{entity.pluralized_name}", encoded_full_path, 'badges'].join('/'),
            query: {
              page: context.tracker.next_page
            }
          }

          expect(described_class.to_h(context)).to eq(expected)
        end
      end
    end

    context 'when entity is group' do
      let(:entity) { create(:bulk_import_entity) }

      include_examples 'resource and page info query'
    end

    context 'when entity is project' do
      let(:entity) { create(:bulk_import_entity, :project_entity) }

      include_examples 'resource and page info query'
    end
  end
end
