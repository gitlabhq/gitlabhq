# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules do
  let(:project)  { create(:project) }
  let(:user)     { create(:user) }
  let(:pipeline) { build(:ci_pipeline, project: project) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    context 'when pipeline has been skipped by workflow configuration' do
      before do
        allow(step).to receive(:workflow_passed?)
          .and_return(false)

        step.perform!
      end

      it 'does not save the pipeline' do
        expect(pipeline).not_to be_persisted
      end

      it 'breaks the chain' do
        expect(step.break?).to be true
      end

      it 'attaches an error to the pipeline' do
        expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
      end
    end

    context 'when pipeline has not been skipped by workflow configuration' do
      before do
        allow(step).to receive(:workflow_passed?)
          .and_return(true)

        step.perform!
      end

      it 'continues the pipeline processing chain' do
        expect(step.break?).to be false
      end

      it 'does not skip the pipeline' do
        expect(pipeline).not_to be_persisted
        expect(pipeline).not_to be_skipped
      end

      it 'attaches no errors' do
        expect(pipeline.errors).to be_empty
      end
    end
  end
end
