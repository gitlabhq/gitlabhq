# frozen_string_literal: true

require "spec_helper"

RSpec.describe Database::PartitionManagementWorker do
  describe '#perform' do
    subject { described_class.new.perform }

    let(:monitoring) { instance_double('PartitionMonitoring', report_metrics: nil) }

    before do
      allow(Gitlab::Database::Partitioning::PartitionMonitoring).to receive(:new).and_return(monitoring)
    end

    it 'delegates to Partitioning' do
      expect(Gitlab::Database::Partitioning).to receive(:sync_partitions)

      subject
    end

    it 'reports partition metrics' do
      expect(monitoring).to receive(:report_metrics)

      subject
    end
  end
end
