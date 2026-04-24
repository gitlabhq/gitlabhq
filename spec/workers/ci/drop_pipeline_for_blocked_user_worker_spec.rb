# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DropPipelineForBlockedUserWorker, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, :running, user: user) }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [pipeline.id, :user_blocked] }
  end

  describe '#perform' do
    it 'calls Ci::DropPipelineService with the pipeline and failure reason' do
      service = instance_double(Ci::DropPipelineService)
      expect(Ci::DropPipelineService).to receive(:new).and_return(service)
      expect(service).to receive(:execute).with(pipeline, :user_blocked)

      worker.perform(pipeline.id, :user_blocked)
    end

    it 'does nothing when the pipeline does not exist' do
      expect(Ci::DropPipelineService).not_to receive(:new)

      worker.perform(non_existing_record_id, :user_blocked)
    end
  end
end
