# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::SourceUsersMapper, feature_category: :importers do
  let_it_be(:portable) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration) }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      group: portable,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Group',
      destination_namespace: portable.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let_it_be(:import_source_user_1) do
    create(:import_source_user,
      namespace: portable,
      import_type: Import::SOURCE_DIRECT_TRANSFER,
      source_hostname: bulk_import.configuration.url,
      source_user_identifier: 101
    )
  end

  let_it_be(:import_source_user_2) do
    create(:import_source_user,
      :completed,
      namespace: portable,
      import_type: Import::SOURCE_DIRECT_TRANSFER,
      source_hostname: bulk_import.configuration.url,
      source_user_identifier: 102
    )
  end

  subject(:mapper) { described_class.new(context: context) }

  describe '#map' do
    it 'returns placeholder user id' do
      expect(mapper.map['101']).to eq(import_source_user_1.placeholder_user_id)
    end

    context 'when import source user have been reassigned to a real user' do
      it 'returns real user user id' do
        expect(mapper.map['102']).to eq(import_source_user_2.reassign_to_user_id)
      end
    end

    context 'when import source does not exists' do
      it 'returns nil' do
        expect(mapper.map['-1']).to eq(nil)
      end
    end
  end

  describe '#include?' do
    context 'when a source user with the source_user_identifier exists' do
      it 'returns true' do
        expect(mapper.include?(101)).to eq(true)
      end
    end

    context 'when a source user with the source_user_identifier does not exist' do
      it 'returns false' do
        expect(mapper.include?(-1)).to eq(false)
      end
    end
  end
end
