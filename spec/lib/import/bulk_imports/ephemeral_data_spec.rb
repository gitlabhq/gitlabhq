# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::EphemeralData, feature_category: :importers do
  let(:ephemeral_data) { described_class.new(123) }

  describe '#enable_importer_user_mapping' do
    it 'is a no-op and does not touch Redis' do
      expect(Gitlab::Cache::Import::Caching).not_to receive(:hash_add)

      ephemeral_data.enable_importer_user_mapping
    end
  end

  describe '#importer_user_mapping_enabled?' do
    it 'always returns true' do
      expect(ephemeral_data.importer_user_mapping_enabled?).to be(true)
    end

    it 'does not read from Redis' do
      expect(Gitlab::Cache::Import::Caching).not_to receive(:value_from_hash)

      ephemeral_data.importer_user_mapping_enabled?
    end
  end
end
