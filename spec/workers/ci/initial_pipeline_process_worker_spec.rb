# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitialPipelineProcessWorker do
  describe '#perform' do
    let_it_be_with_reload(:pipeline) do
      create(:ci_pipeline, :with_job, status: :created)
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { pipeline.id }

      it 'marks the pipeline as pending' do
        expect(pipeline).to be_created

        subject

        expect(pipeline.reload).to be_pending
      end
    end
  end
end
