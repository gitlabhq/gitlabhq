# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineUpdateWorker do
  describe '#perform' do
    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }

      it 'updates pipeline status' do
        expect_any_instance_of(Ci::Pipeline).to receive(:set_status).with('skipped')

        described_class.new.perform(pipeline.id)
      end

      include_examples 'an idempotent worker' do
        let(:job_args) { [pipeline.id] }

        it 'sets pipeline status to skipped' do
          expect { subject }.to change { pipeline.reload.status }.from('pending').to('skipped')
        end
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
