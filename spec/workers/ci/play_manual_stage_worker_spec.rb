# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayManualStageWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:stage) { create(:ci_stage, pipeline: pipeline) }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [stage.id, user.id] }
  end

  describe '#perform' do
    it 'calls PlayManualStageService' do
      expect_next_instance_of(Ci::PlayManualStageService, project, user, pipeline: pipeline) do |service|
        expect(service).to receive(:execute).with(stage)
      end

      worker.perform(stage.id, user.id)
    end

    context 'when stage does not exist' do
      it 'does not call the service or raise an error' do
        expect(Ci::PlayManualStageService).not_to receive(:new)

        expect { worker.perform(non_existing_record_id, user.id) }.not_to raise_error
      end
    end

    context 'when user does not exist' do
      it 'does not call the service or raise an error' do
        expect(Ci::PlayManualStageService).not_to receive(:new)

        expect { worker.perform(stage.id, non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
