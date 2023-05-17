# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::TestFailureHistoryWorker, feature_category: :static_application_security_testing do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline_id) }

    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }
      let(:pipeline_id) { pipeline.id }

      it 'executes test failure history service' do
        expect_next_instance_of(::Ci::TestFailureHistoryService) do |service|
          expect(service).to receive(:execute)
        end

        perform
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not execute test failure history service' do
        expect(Ci::TestFailureHistoryService).not_to receive(:new)

        perform
      end
    end
  end

  include_examples 'an idempotent worker' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:job_args) { [pipeline.id] }

    it 'tracks test failures' do
      # The test report has 2 test case failures
      create(:ci_build, :failed, :test_reports, pipeline: pipeline, project: pipeline.project)

      subject

      expect(Ci::UnitTest.count).to eq(2)
      expect(Ci::UnitTestFailure.count).to eq(2)
    end
  end
end
