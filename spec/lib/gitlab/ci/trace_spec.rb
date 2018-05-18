require 'spec_helper'

describe Gitlab::Ci::Trace, :clean_gitlab_redis_cache do
  let(:build) { create(:ci_build) }
  let(:trace) { described_class.new(build) }

  describe "associations" do
    it { expect(trace).to respond_to(:job) }
    it { expect(trace).to delegate_method(:old_trace).to(:job) }
  end

  context 'when live trace feature is disabled' do
    before do
      stub_feature_flags(ci_enable_live_trace: false)
    end

    it_behaves_like 'trace with disabled live trace feature'
  end

  context 'when live trace feature is enabled' do
    before do
      stub_feature_flags(ci_enable_live_trace: true)
    end

    it_behaves_like 'trace with enabled live trace feature'
  end
end
