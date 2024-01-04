# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ReloadDiffsService, :use_clean_rails_memory_store_caching,
  feature_category: :code_review_workflow do
  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:subject) { described_class.new(merge_request, current_user) }

  describe '#execute' do
    it 'creates new merge request diff' do
      expect { subject.execute }.to change { merge_request.merge_request_diffs.count }.by(1)
    end

    it 'calls update_diff_discussion_positions with correct params' do
      old_diff_refs = merge_request.diff_refs
      new_diff = merge_request.create_merge_request_diff
      new_diff_refs = merge_request.diff_refs

      expect(merge_request).to receive(:create_merge_request_diff).and_return(new_diff)
      expect(merge_request).to receive(:update_diff_discussion_positions).with(
        old_diff_refs: old_diff_refs, new_diff_refs: new_diff_refs, current_user: current_user
      )

      subject.execute
    end

    it 'does not change existing merge request diff' do
      expect(merge_request.merge_request_diff).not_to receive(:save_git_content)

      subject.execute
    end

    context 'cache clearing' do
      it 'clears the cache for older diffs on the merge request' do
        expect_next_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff) do |instance|
          expect(instance).to receive(:clear_cache).and_call_original
        end

        subject.execute
      end

      it 'avoids N+1 queries', :request_store do
        current_user
        merge_request

        control = ActiveRecord::QueryRecorder.new do
          subject.execute
        end

        expect { subject.execute }.not_to exceed_query_limit(control)
      end
    end
  end
end
