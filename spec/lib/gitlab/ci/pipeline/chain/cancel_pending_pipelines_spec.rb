# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CancelPendingPipelines, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user) }
  let_it_be(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    it 'enqueues CancelRedundantPipelinesWorker' do
      expect(Ci::CancelRedundantPipelinesWorker)
        .to receive(:perform_async)
        .with(pipeline.id, { 'partition_id' => pipeline.partition_id })

      subject
    end

    context 'with scheduled pipelines' do
      before do
        pipeline.source = :schedule
      end

      it 'enqueues LowUrgencyCancelRedundantPipelinesWorker' do
        expect(Ci::LowUrgencyCancelRedundantPipelinesWorker)
          .to receive(:perform_async)
          .with(pipeline.id, { 'partition_id' => pipeline.partition_id })

        subject
      end
    end
  end
end
