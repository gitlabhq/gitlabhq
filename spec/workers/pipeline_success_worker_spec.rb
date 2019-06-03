# frozen_string_literal: true

require 'spec_helper'

describe PipelineSuccessWorker do
  describe '#perform' do
    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline, status: 'success', ref: merge_request.source_branch, project: merge_request.source_project) }
      let(:merge_request) { create(:merge_request) }

      it 'performs "merge when pipeline succeeds"' do
        expect_next_instance_of(AutoMergeService) do |auto_merge|
          expect(auto_merge).to receive(:process)
        end

        described_class.new.perform(pipeline.id)
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
