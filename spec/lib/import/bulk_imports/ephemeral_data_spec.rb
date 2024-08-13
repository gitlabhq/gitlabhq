# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::EphemeralData, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:ephemeral_data) { described_class.new(123) }

  describe '#enable_importer_user_mapping' do
    it 'enables importer_user_mapping' do
      ephemeral_data.enable_importer_user_mapping

      expect(ephemeral_data.importer_user_mapping_enabled?).to eq(true)
    end
  end

  describe '#importer_user_mapping_enabled?' do
    context 'when importer_user_mapping is enabled' do
      before do
        ephemeral_data.enable_importer_user_mapping
      end

      it 'returns true' do
        expect(ephemeral_data.importer_user_mapping_enabled?).to eq(true)
      end
    end

    context 'when importer_user_mapping is not enabled' do
      it 'returns false' do
        expect(ephemeral_data.importer_user_mapping_enabled?).to eq(false)
      end
    end

    context 'when importer_user_mapping is enabled for a different bulk_import_id' do
      before do
        ephemeral_data.enable_importer_user_mapping
      end

      it 'returns false' do
        expect(described_class.new(456).importer_user_mapping_enabled?).to eq(false)
      end
    end
  end
end
