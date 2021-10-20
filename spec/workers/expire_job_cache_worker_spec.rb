# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExpireJobCacheWorker do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }

  let(:project) { pipeline.project }

  describe '#perform' do
    context 'with a job in the pipeline' do
      let_it_be(:job) { create(:ci_build, pipeline: pipeline) }

      let(:job_args) { job.id }

      it_behaves_like 'an idempotent worker'

      it_behaves_like 'worker with data consistency',
        described_class,
        data_consistency: :delayed
    end

    context 'when there is no job in the pipeline' do
      it 'does not change the etag store' do
        expect(Gitlab::EtagCaching::Store).not_to receive(:new)

        perform_multiple(non_existing_record_id)
      end
    end
  end
end
