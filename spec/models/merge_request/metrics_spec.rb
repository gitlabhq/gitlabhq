require 'spec_helper'

describe MergeRequest::Metrics, models: true do
  let(:project) { create(:project) }

  subject { create(:merge_request, source_project: project) }

  describe "when recording the default set of metrics on merge request save" do
    it "records the merge time" do
      time = Time.now
      Timecop.freeze(time) { subject.mark_as_merged }
      metrics = subject.metrics

      expect(metrics).to be_present
      expect(metrics.merged_at).to eq(time)
    end
  end
end
