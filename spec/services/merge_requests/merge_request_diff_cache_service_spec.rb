require 'spec_helper'

describe MergeRequests::MergeRequestDiffCacheService, services: true do
  let(:subject) { MergeRequests::MergeRequestDiffCacheService.new }
  let(:merge_request) { create(:merge_request) }

  describe '#execute', caching: true do
    it 'retrieves the diff files to cache the highlighted result' do
      cache_key = [merge_request.merge_request_diff, 'highlighted-diff-files', Gitlab::Diff::FileCollection::MergeRequestDiff.default_options]

      allow_any_instance_of(Gitlab::Diff::File).to receive(:blob).and_return(double("text?" => true))
      allow_any_instance_of(Repository).to receive(:diffable?).and_return(true)

      expect(Rails.cache.read(cache_key)).to be_blank

      subject.execute(merge_request)

      expect(Rails.cache.read(cache_key)).to be_present
    end
  end
end
