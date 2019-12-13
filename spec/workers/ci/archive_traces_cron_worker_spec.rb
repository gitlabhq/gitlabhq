# frozen_string_literal: true

require 'spec_helper'

describe Ci::ArchiveTracesCronWorker do
  subject { described_class.new.perform }

  let(:finished_at) { 1.day.ago }

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
    let!(:build) { create(:ci_build, :success, :trace_live, finished_at: finished_at) }

    it_behaves_like 'archives trace'

    it 'executes service' do
      expect_any_instance_of(Ci::ArchiveTraceService)
        .to receive(:execute).with(build, anything)

      subject
    end

    context 'when the job finished recently' do
      let(:finished_at) { 1.hour.ago }

      it_behaves_like 'does not archive trace'
    end

    context 'when a trace had already been archived' do
      let!(:build) { create(:ci_build, :success, :trace_live, :trace_artifact) }
      let!(:build2) { create(:ci_build, :success, :trace_live, finished_at: finished_at) }

      it 'continues to archive live traces' do
        subject

        build2.reload
        expect(build2.job_artifacts_trace).to be_exist
      end
    end

    context 'when an unexpected exception happened during archiving' do
      let!(:build) { create(:ci_build, :success, :trace_live, finished_at: finished_at) }

      before do
        allow(Gitlab::Sentry).to receive(:track_and_raise_for_dev_exception)
        allow_any_instance_of(Gitlab::Ci::Trace).to receive(:archive!).and_raise('Unexpected error')
      end

      it 'puts a log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: described_class.name,
          message: "Failed to archive trace. message: Unexpected error.",
          job_id: build.id)

        subject
      end
    end
  end

  context 'when a job was cancelled' do
    let!(:build) { create(:ci_build, :canceled, :trace_live, finished_at: finished_at) }

    it_behaves_like 'archives trace'
  end

  context 'when a job is running' do
    let!(:build) { create(:ci_build, :running, :trace_live) }

    it_behaves_like 'does not archive trace'
  end
end
