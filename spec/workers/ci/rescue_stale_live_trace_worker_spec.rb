require 'spec_helper'

describe Ci::RescueStaleLiveTraceWorker do
  subject { described_class.new.perform }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  shared_examples_for 'archives trace' do
    it do
      subject

      expect(build.job_artifacts_trace).to be_exist
    end
  end

  shared_examples_for 'does not archive trace' do
    it do
      subject

      build.reload
      expect(build.job_artifacts_trace).to be_nil
    end
  end

  context 'when a job was succeeded 2 hours ago' do
    let!(:build) { create(:ci_build, :success, :trace_live) }

    before do
      build.update(finished_at: 2.hours.ago)
    end

    it_behaves_like 'archives trace'

    context 'when build has both archived trace and live trace' do
      let!(:build2) { create(:ci_build, :success, :trace_live, finished_at: 2.days.ago) }
  
      it 'archives only available targets' do
        subject

        build.reload
        expect(build.job_artifacts_trace).to be_exist
      end
    end
  end

  context 'when a job was failed 2 hours ago' do
    let!(:build) { create(:ci_build, :failed, :trace_live) }

    before do
      build.update(finished_at: 2.hours.ago)
    end

    it_behaves_like 'archives trace'
  end

  context 'when a job was cancelled 2 hours ago' do
    let!(:build) { create(:ci_build, :canceled, :trace_live) }

    before do
      build.update(finished_at: 2.hours.ago)
    end

    it_behaves_like 'archives trace'
  end

  context 'when a job has been finished 10 minutes ago' do
    let!(:build) { create(:ci_build, :success, :trace_live) }

    before do
      build.update(finished_at: 10.minutes.ago)
    end

    it_behaves_like 'does not archive trace'
  end

  context 'when a job is running' do
    let!(:build) { create(:ci_build, :running, :trace_live) }

    it_behaves_like 'does not archive trace'
  end
end
