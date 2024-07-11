# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleUnlockPipelinesInQueueCronWorker, :unlock_pipelines, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'enqueues UnlockPipelinesWorker jobs' do
      expect(Ci::UnlockPipelinesInQueueWorker).to receive(:perform_with_capacity)

      worker.perform
    end
  end
end
