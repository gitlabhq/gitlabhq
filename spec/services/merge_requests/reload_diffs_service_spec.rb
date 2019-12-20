# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::ReloadDiffsService, :use_clean_rails_memory_store_caching do
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
      expect(merge_request).to receive(:update_diff_discussion_positions)
        .with(old_diff_refs: old_diff_refs,
              new_diff_refs: new_diff_refs,
              current_user: current_user)

      subject.execute
    end

    it 'does not change existing merge request diff' do
      expect(merge_request.merge_request_diff).not_to receive(:save_git_content)

      subject.execute
    end

    context 'cache clearing' do
      context 'using Gitlab::Diff::DeprecatedHighlightCache' do
        before do
          stub_feature_flags(hset_redis_diff_caching: false)
        end

        it 'clears the cache for older diffs on the merge request' do
          old_diff = merge_request.merge_request_diff
          old_cache_key = old_diff.diffs_collection.cache_key

          expect(Rails.cache).to receive(:delete).with(old_cache_key).and_call_original

          subject.execute
        end
      end

      context 'using Gitlab::Diff::HighlightCache' do
        before do
          stub_feature_flags(hset_redis_diff_caching: true)
        end

        it 'clears the cache for older diffs on the merge request' do
          old_diff = merge_request.merge_request_diff
          old_cache_key = old_diff.diffs_collection.cache_key

          expect_any_instance_of(Redis).to receive(:del).with(old_cache_key).and_call_original

          subject.execute
        end
      end

      it 'avoids N+1 queries', :request_store do
        current_user
        merge_request

        control_count = ActiveRecord::QueryRecorder.new do
          subject.execute
        end.count

        expect { subject.execute }.not_to exceed_query_limit(control_count)
      end
    end
  end
end
