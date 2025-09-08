# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MarkPackagesHelmMetadataCachesPendingDestruction, feature_category: :package_registry do
  describe '#perform' do
    let!(:helm_metadata_caches) do
      records = Array.new(10).map.with_index do |_, i|
        {
          project_id: i,
          channel: i,
          object_storage_key: "key-#{i}",
          size: 401.bytes,
          file: 'index.yaml'
        }
      end

      table(:packages_helm_metadata_caches).create!(records)
    end

    subject(:perform) do
      described_class.new(
        start_id: helm_metadata_caches[0].id,
        end_id: helm_metadata_caches[5].id,
        batch_table: :packages_helm_metadata_caches,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    it 'marks helm metadata caches batch as pending destruction' do
      expect { perform }.to change { helm_metadata_caches[0..5].each(&:reload).map(&:status) }
        .to(Array.new(6, described_class::PENDING_DESTRUCTION_STATUS))
        .and not_change { helm_metadata_caches[6..].map(&:status) }
    end
  end
end
