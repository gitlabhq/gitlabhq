# frozen_string_literal: true

require "spec_helper"

RSpec.describe Database::PartitionManagementWorker, feature_category: :database do
  describe '#perform' do
    subject { described_class.new.perform }

    before do
      allow(Gitlab::Database::Partitioning).to receive(:sync_partitions)
      allow(Gitlab::Database::Partitioning).to receive(:report_metrics)
    end

    it 'syncs partitions, including the ANALYZE for tables relying on the default analyze_interval' do
      expect(Gitlab::Database::Partitioning)
        .to receive(:sync_partitions).with(analyze_tables_with_default_interval: true)

      subject
    end

    it 'reports partition metrics' do
      expect(Gitlab::Database::Partitioning).to receive(:report_metrics)

      subject
    end
  end
end
