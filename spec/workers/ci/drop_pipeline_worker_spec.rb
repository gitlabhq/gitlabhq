# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DropPipelineWorker, feature_category: :continuous_integration do
  include AfterNextHelpers

  let(:pipeline) { create(:ci_pipeline, :running) }
  let(:failure_reason) { :user_blocked }

  describe '#perform' do
    subject { described_class.new.perform(pipeline.id, failure_reason) }

    it 'calls delegates to the service' do
      expect_next(Ci::DropPipelineService).to receive(:execute).with(pipeline, failure_reason)

      subject
    end

    it_behaves_like 'an idempotent worker' do
      let!(:running_build) { create(:ci_build, :running, pipeline: pipeline) }
      let!(:success_build) { create(:ci_build, :success, pipeline: pipeline) }

      let(:job_args) { [pipeline.id, failure_reason] }

      it 'executes the service', :aggregate_failures do
        subject

        expect(running_build.reload).to be_failed
        expect(running_build.failure_reason).to eq(failure_reason.to_s)

        expect(success_build.reload).to be_success
      end
    end
  end
end
