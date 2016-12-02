require 'spec_helper'

describe MergeRequests::MergeRequestDiffCacheService do
  let(:subject) { MergeRequests::MergeRequestDiffCacheService.new }

  describe '#execute' do
    it 'retrieves the diff files to cache the highlighted result' do
      merge_request = create(:merge_request)
      cache_key = [merge_request.merge_request_diff, 'highlighted-diff-files', Gitlab::Diff::FileCollection::MergeRequestDiff.default_options]

      expect(Rails.cache).to receive(:read).with(cache_key).and_return({})
      expect(Rails.cache).to receive(:write).with(cache_key, anything)
      allow_any_instance_of(Gitlab::Diff::File).to receive(:blob).and_return(double("text?" => true))

      subject.execute(merge_request)
    end
  end
end
