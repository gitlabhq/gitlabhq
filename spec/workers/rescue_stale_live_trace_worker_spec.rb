require 'spec_helper'

describe RescueStaleLiveTraceWorker do
  subject { described_class.new.perform }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  shared_examples_for 'schedules to archive traces' do
    it do
      expect(ArchiveTraceWorker).to receive(:bulk_perform_async).with([[build.id]])

      subject
    end
  end

  shared_examples_for 'does not schedule to archive traces' do
    it do
      expect(ArchiveTraceWorker).not_to receive(:bulk_perform_async)

      subject
    end
  end

  context 'when a job was succeeded 2 hours ago' do
    let!(:build) { create(:ci_build, :success, :trace_live) }

    before do
      build.update(finished_at: 2.hours.ago)
    end

    it_behaves_like 'schedules to archive traces'
  end

  context 'when a job was failed 2 hours ago' do
    let!(:build) { create(:ci_build, :failed, :trace_live) }

    before do
      build.update(finished_at: 2.hours.ago)
    end

    it_behaves_like 'schedules to archive traces'
  end

  context 'when a job was cancelled 2 hours ago' do
    let!(:build) { create(:ci_build, :canceled, :trace_live) }

    before do
      build.update(finished_at: 2.hours.ago)
    end

    it_behaves_like 'schedules to archive traces'
  end

  context 'when a job has been finished 10 minutes ago' do
    let!(:build) { create(:ci_build, :success, :trace_live) }

    before do
      build.update(finished_at: 10.minutes.ago)
    end

    it_behaves_like 'does not schedule to archive traces'
  end

  context 'when a job is running' do
    let!(:build) { create(:ci_build, :running, :trace_live) }

    it_behaves_like 'does not schedule to archive traces'
  end
end
