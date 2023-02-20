# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CancelPendingPipelines, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user) }
  let_it_be(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    it 'enqueues CancelRedundantPipelinesWorker' do
      expect(Ci::CancelRedundantPipelinesWorker).to receive(:perform_async).with(pipeline.id)

      subject
    end
  end
end
