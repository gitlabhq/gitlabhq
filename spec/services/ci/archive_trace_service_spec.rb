# frozen_string_literal: true

require 'spec_helper'

describe Ci::ArchiveTraceService, '#execute' do
  subject { described_class.new.execute(job, worker_name: ArchiveTraceWorker.name) }

  context 'when job is finished' do
    let(:job) { create(:ci_build, :success, :trace_live) }

    it 'creates an archived trace' do
      expect { subject }.not_to raise_error

      expect(job.reload.job_artifacts_trace).to be_exist
    end

    context 'when trace is already archived' do
      let!(:job) { create(:ci_build, :success, :trace_artifact) }

      it 'ignores an exception' do
        expect { subject }.not_to raise_error
      end

      it 'does not create an archived trace' do
        expect { subject }.not_to change { Ci::JobArtifact.trace.count }
      end
    end

    context 'when job does not have trace' do
      let(:job) { create(:ci_build, :success) }

      it 'leaves a warning message in sidekiq log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: ArchiveTraceWorker.name,
          message: 'The job does not have live trace but going to be archived.',
          job_id: job.id)

        subject
      end
    end

    context 'when job failed to archive trace but did not raise an exception' do
      before do
        allow_any_instance_of(Gitlab::Ci::Trace).to receive(:archive!) {}
      end

      it 'leaves a warning message in sidekiq log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: ArchiveTraceWorker.name,
          message: 'The job does not have archived trace after archiving.',
          job_id: job.id)

        subject
      end
    end
  end

  context 'when job is running' do
    let(:job) { create(:ci_build, :running, :trace_live) }

    it 'increments Prometheus counter, sends crash report to Sentry and ignore an error for continuing to archive' do
      expect(Gitlab::Sentry)
        .to receive(:track_and_raise_for_dev_exception)
        .with(::Gitlab::Ci::Trace::ArchiveError,
              issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/51502',
              job_id: job.id).once

      expect(Sidekiq.logger).to receive(:warn).with(
        class: ArchiveTraceWorker.name,
        message: "Failed to archive trace. message: Job is not finished yet.",
        job_id: job.id).and_call_original

      expect(Gitlab::Metrics)
        .to receive(:counter)
        .with(:job_trace_archive_failed_total, "Counter of failed attempts of trace archiving")
        .and_call_original

      expect { subject }.not_to raise_error
    end
  end
end
