# frozen_string_literal: true

require "spec_helper"

RSpec.describe Database::DropDetachedPartitionsWorker do
  describe '#perform' do
    subject { described_class.new.perform }

    let(:dropper) {  instance_double('DropDetachedPartitions', perform: nil) }
    let(:monitoring) { instance_double('PartitionMonitoring', report_metrics: nil) }

    before do
      allow(Gitlab::Database::Partitioning::DetachedPartitionDropper).to receive(:new).and_return(dropper)
      allow(Gitlab::Database::Partitioning::PartitionMonitoring).to receive(:new).and_return(monitoring)
    end

    it 'delegates to DropPartitionsPendingDrop' do
      expect(dropper).to receive(:perform)

      subject
    end

    it 'reports partition metrics' do
      expect(monitoring).to receive(:report_metrics)

      subject
    end
  end
end
