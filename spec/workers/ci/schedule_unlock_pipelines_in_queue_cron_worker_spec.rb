# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleUnlockPipelinesInQueueCronWorker, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  describe '#perform' do
    context 'when there are pending unlock requests' do
      before do
        Ci::UnlockPipelineRequest.enqueue(non_existing_record_id)
      end

      it 'enqueues UnlockPipelinesWorker jobs' do
        expect(Ci::UnlockPipelinesInQueueWorker).to receive(:perform_with_capacity)

        worker.perform
      end
    end

    context 'when the queue is empty' do
      it 'does not enqueue any jobs' do
        expect(Ci::UnlockPipelineRequest.total_pending).to eq(0)
        expect(Ci::UnlockPipelinesInQueueWorker).not_to receive(:perform_with_capacity)

        worker.perform
      end
    end
  end
end
