require 'spec_helper'

describe Ci::ArchiveTracesCronWorker do
  subject { described_class.new.perform }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  shared_examples_for 'archives trace' do
    it do
      subject

      build.reload
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

  context 'when a job succeeded' do
    let!(:build) { create(:ci_build, :success, :trace_live) }

    it_behaves_like 'archives trace'

    context 'when a trace had already been archived' do
      let!(:build) { create(:ci_build, :success, :trace_live, :trace_artifact) }
      let!(:build2) { create(:ci_build, :success, :trace_live) }

      it 'continues to archive live traces' do
        subject

        build2.reload
        expect(build2.job_artifacts_trace).to be_exist
      end
    end

    context 'when an unexpected exception happened during archiving' do
      let!(:build) { create(:ci_build, :success, :trace_live) }

      before do
        allow_any_instance_of(Gitlab::Ci::Trace).to receive(:archive!).and_raise('Unexpected error')
      end

      it 'puts a log' do
        expect(Rails.logger).to receive(:error).with("Failed to archive stale live trace. id: #{build.id} message: Unexpected error")

        subject
      end
    end
  end

  context 'when a job was cancelled' do
    let!(:build) { create(:ci_build, :canceled, :trace_live) }

    it_behaves_like 'archives trace'
  end

  context 'when a job is running' do
    let!(:build) { create(:ci_build, :running, :trace_live) }

    it_behaves_like 'does not archive trace'
  end
end
