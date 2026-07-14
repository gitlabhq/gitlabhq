# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::WriteDiffsCacheWorker, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }

  describe '#perform' do
    it 'writes the diffs cache for the merge request' do
      diffs = merge_request.diffs(include_stats: false)

      allow_next_found_instance_of(MergeRequest) do |found_mr|
        allow(found_mr).to receive(:diffs).with(include_stats: false).and_return(diffs)
      end
      expect(diffs).to receive(:write_cache)

      described_class.new.perform(merge_request.id)
    end

    context 'when the merge request does not exist' do
      it 'does nothing' do
        expect(MergeRequest).to receive(:find_by_id).with(non_existing_record_id).and_return(nil)

        expect { described_class.new.perform(non_existing_record_id) }.not_to raise_error
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [merge_request.id] }
    end
  end
end
