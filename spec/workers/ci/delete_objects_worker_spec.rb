# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteObjectsWorker, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  it { expect(described_class.idempotent?).to be_truthy }
  it { is_expected.to respond_to(:max_running_jobs) }
  it { is_expected.to respond_to(:remaining_work_count) }
  it { is_expected.to respond_to(:perform_work) }

  describe '#perform' do
    it 'executes a service' do
      expect_next_instance_of(Ci::DeleteObjectsService) do |instance|
        expect(instance).to receive(:execute).and_return(ServiceResponse.success)
        expect(instance).to receive(:remaining_batches_count)
          .with(max_batch_count: 20)
          .once
          .and_call_original
      end
      worker.perform
    end

    context 'when logging metadata' do
      context 'when records were deleted' do
        let(:latencies) { [10.seconds, 20.seconds, 30.seconds] }
        let(:expected_deletion_delay_metrics) do
          {
            min: latencies.min,
            max: latencies.max,
            sum: latencies.sum,
            average: latencies.sum / latencies.size,
            total_count: latencies.size
          }
        end

        it 'logs with extra metadata', :aggregate_failures do
          allow_next_instance_of(Ci::DeleteObjectsService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: { latencies: latencies }))
          end

          expect(worker).to receive(:log_extra_metadata_on_done)
            .with(:deletion_delay_metrics, expected_deletion_delay_metrics)

          worker.perform
        end
      end

      context 'when no records were deleted' do
        let(:expected_deletion_delay_metrics) do
          { min: nil, max: nil, sum: 0, average: nil, total_count: 0 }
        end

        it 'logs with extra metadata', :aggregate_failures do
          allow_next_instance_of(Ci::DeleteObjectsService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.success)
          end

          expect(worker).to receive(:log_extra_metadata_on_done)
            .with(:deletion_delay_metrics, expected_deletion_delay_metrics)

          worker.perform
        end
      end
    end
  end
end
