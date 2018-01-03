require 'spec_helper'

describe MergeRequest::Metrics do
  subject { create(:merge_request) }

  describe "when recording the default set of metrics on merge request save" do
    it "records the merge time" do
      time = Time.now
      Timecop.freeze(time) { subject.mark_as_merged }
      metrics = subject.metrics

      expect(metrics).to be_present
      expect(metrics.merged_at).to be_like_time(time)
    end
  end
end
