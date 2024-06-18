# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultsWorker, feature_category: :code_testing do
  describe '#perform' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    subject { described_class.new.perform(pipeline_id) }

    context 'when pipeline is found' do
      let(:pipeline_id) { pipeline.id }

      it 'executes service' do
        expect_any_instance_of(Ci::DailyBuildGroupReportResultService)
          .to receive(:execute).with(pipeline)

        subject
      end
    end

    context 'when pipeline is not found' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not execute service' do
        expect_any_instance_of(Ci::DailyBuildGroupReportResultService)
          .not_to receive(:execute)

        expect { subject }
          .not_to raise_error
      end
    end
  end
end
