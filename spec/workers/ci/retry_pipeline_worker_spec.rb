# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryPipelineWorker, feature_category: :continuous_integration do
  it 'deduplicates jobs until executed and reschedules a deduplicated job once', :aggregate_failures do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    expect(described_class.get_deduplication_options).to eq(if_deduplicated: :reschedule_once)
  end

  describe '#perform' do
    subject(:perform) { worker.perform(pipeline_id, user_id) }

    let(:worker) { described_class.new }

    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:user) { create(:user) }

    before_all do
      pipeline.project.add_maintainer(user)
    end

    context 'when pipeline exists' do
      let(:pipeline_id) { pipeline.id }

      context 'when user exists' do
        let(:user_id) { user.id }

        it 'retries the pipeline' do
          expect(::Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
          expect(pipeline).to receive(:retry_failed).with(having_attributes(id: user_id))
            .and_return(ServiceResponse.success)

          perform
        end

        it 'logs the error message and reason when the retry is rejected', :aggregate_failures do
          allow(::Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
          allow(pipeline).to receive(:retry_failed).and_return(
            ServiceResponse.error(message: 'Pipeline is already being retried', reason: :retry_in_progress)
          )

          expect(worker).to receive(:log_extra_metadata_on_done)
            .with(:error_message, 'Pipeline is already being retried')
          expect(worker).to receive(:log_extra_metadata_on_done)
            .with(:error_reason, :retry_in_progress)

          perform
        end

        it_behaves_like 'an idempotent worker' do
          # The persistent ref cannot be created for this SHA, so each retry run drops
          # the pipeline. A failed build keeps the pipeline running after the first
          # run, so the second run's drop is a legal transition instead of raising.
          let_it_be(:failed_build) { create(:ci_build, :failed, pipeline: pipeline) }

          let(:job_args) { [pipeline.id, user.id] }
        end
      end

      context 'when user does not exist' do
        let(:user_id) { non_existing_record_id }

        it 'does not retry the pipeline' do
          expect(::Ci::Pipeline).to receive(:find_by_id).with(pipeline_id).and_return(pipeline)
          expect(pipeline).not_to receive(:retry_failed).with(having_attributes(id: user_id))

          perform
        end
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }
      let(:user_id) { user.id }

      it 'returns nil' do
        expect(perform).to be_nil
      end
    end
  end
end
