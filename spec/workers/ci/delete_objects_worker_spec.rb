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
          .with(max_batch_count: 50)
          .once
          .and_call_original
      end
      worker.perform
    end
  end

  describe '#max_running_jobs' do
    it 'returns higher concurrency of 50' do
      expect(worker.max_running_jobs).to eq(50)
    end

    context 'when FF ci_delete_objects_high_concurrency is disabled' do
      before do
        stub_feature_flags(ci_delete_objects_high_concurrency: false)
      end

      it 'returns 20 when the feature flag is disabled' do
        expect(worker.max_running_jobs).to eq(20)
      end
    end
  end
end
