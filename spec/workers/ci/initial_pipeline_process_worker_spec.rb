# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitialPipelineProcessWorker do
  describe '#perform' do
    let_it_be_with_reload(:pipeline) do
      create(:ci_pipeline, :with_job, status: :created)
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { pipeline.id }

      context 'when there are runners available' do
        before do
          create(:ci_runner, :online)
        end

        it 'marks the pipeline as pending' do
          expect(pipeline).to be_created

          subject

          expect(pipeline.reload).to be_pending
        end
      end

      it 'marks the pipeline as failed' do
        expect(pipeline).to be_created

        subject

        expect(pipeline.reload).to be_failed
      end
    end
  end
end
