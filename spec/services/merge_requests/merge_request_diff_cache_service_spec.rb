require 'spec_helper'

describe MergeRequests::MergeRequestDiffCacheService, :use_clean_rails_memory_store_caching do
  let(:subject) { described_class.new }
  let(:merge_request) { create(:merge_request) }

  describe '#execute' do
    before do
      allow_any_instance_of(Gitlab::Diff::File).to receive(:text?).and_return(true)
      allow_any_instance_of(Gitlab::Diff::File).to receive(:diffable?).and_return(true)
    end

    it 'retrieves the diff files to cache the highlighted result' do
      new_diff = merge_request.merge_request_diff
      cache_key = new_diff.diffs.cache_key

      expect(Rails.cache).to receive(:read).with(cache_key).and_call_original
      expect(Rails.cache).to receive(:write).with(cache_key, anything, anything).and_call_original

      subject.execute(merge_request, new_diff)
    end

    it 'clears the cache for older diffs on the merge request' do
      old_diff = merge_request.merge_request_diff
      old_cache_key = old_diff.diffs.cache_key

      subject.execute(merge_request, old_diff)

      new_diff = merge_request.create_merge_request_diff
      new_cache_key = new_diff.diffs.cache_key

      expect(Rails.cache).to receive(:delete).with(old_cache_key).and_call_original
      expect(Rails.cache).to receive(:read).with(new_cache_key).and_call_original
      expect(Rails.cache).to receive(:write).with(new_cache_key, anything, anything).and_call_original

      subject.execute(merge_request, new_diff)
    end
  end
end
