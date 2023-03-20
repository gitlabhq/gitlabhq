# frozen_string_literal: true

require "spec_helper"

RSpec.describe Database::DropDetachedPartitionsWorker, feature_category: :database do
  describe '#perform' do
    subject { described_class.new.perform }

    before do
      allow(Gitlab::Database::Partitioning).to receive(:drop_detached_partitions)
      allow(Gitlab::Database::Partitioning).to receive(:report_metrics)
    end

    it 'drops detached partitions' do
      expect(Gitlab::Database::Partitioning).to receive(:drop_detached_partitions)

      subject
    end

    it 'reports partition metrics' do
      expect(Gitlab::Database::Partitioning).to receive(:report_metrics)

      subject
    end
  end
end
