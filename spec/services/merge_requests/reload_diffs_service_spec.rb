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
      before do
        allow_any_instance_of(Gitlab::Diff::File).to receive(:text?).and_return(true)
        allow_any_instance_of(Gitlab::Diff::File).to receive(:diffable?).and_return(true)
      end

      it 'retrieves the diff files to cache the highlighted result' do
        new_diff = merge_request.create_merge_request_diff
        cache_key = new_diff.diffs_collection.cache_key

        expect(merge_request).to receive(:create_merge_request_diff).and_return(new_diff)
        expect(Rails.cache).to receive(:read).with(cache_key).and_call_original
        expect(Rails.cache).to receive(:write).with(cache_key, anything, anything).and_call_original

        subject.execute
      end

      it 'clears the cache for older diffs on the merge request' do
        old_diff = merge_request.merge_request_diff
        old_cache_key = old_diff.diffs_collection.cache_key
        new_diff = merge_request.create_merge_request_diff
        new_cache_key = new_diff.diffs_collection.cache_key

        expect(merge_request).to receive(:create_merge_request_diff).and_return(new_diff)
        expect(Rails.cache).to receive(:delete).with(old_cache_key).and_call_original
        expect(Rails.cache).to receive(:read).with(new_cache_key).and_call_original
        expect(Rails.cache).to receive(:write).with(new_cache_key, anything, anything).and_call_original

        subject.execute
      end
    end
  end
end
