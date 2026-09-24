# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::EphemeralData, :clean_gitlab_redis_shared_state, feature_category: :importers do
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

  describe '#request_channel' do
    it 'returns nil when nothing was stored' do
      expect(ephemeral_data.request_channel).to be_nil
    end

    it 'round-trips a symbol as a string' do
      ephemeral_data.request_channel = :ui

      expect(ephemeral_data.request_channel).to eq('ui')
    end

    it 'accepts a string' do
      ephemeral_data.request_channel = 'congregate'

      expect(ephemeral_data.request_channel).to eq('congregate')
    end

    it 'does not store a blank value' do
      ephemeral_data.request_channel = nil

      expect(ephemeral_data.request_channel).to be_nil
    end

    it 'is scoped per bulk_import_id' do
      ephemeral_data.request_channel = :ui

      expect(described_class.new(456).request_channel).to be_nil
    end
  end
end
