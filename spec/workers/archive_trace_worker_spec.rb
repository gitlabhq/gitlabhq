require 'spec_helper'

describe ArchiveTraceWorker do
  describe '#perform' do
    subject { described_class.new.perform(job&.id) }

    context 'when job is found' do
      let(:job) { create(:ci_build) }

      it 'executes service' do
        expect_any_instance_of(Gitlab::Ci::Trace).to receive(:archive!)

        subject
      end
    end

    context 'when job is not found' do
      let(:job) { nil }

      it 'does not execute service' do
        expect_any_instance_of(Gitlab::Ci::Trace).not_to receive(:archive!)

        subject
      end
    end

    context 'when an unexpected exception happened during archiving' do
      let!(:job) { create(:ci_build, :success, :trace_live) }

      before do
        allow_any_instance_of(Gitlab::Ci::Trace).to receive(:archive_stream!).and_raise('Unexpected error')
      end

      it 'increments Prometheus counter, sends crash report to Sentry and ignore an error for continuing to archive' do
        expect(Gitlab::Sentry)
          .to receive(:track_exception)
          .with(RuntimeError,
                issue_url: 'https://gitlab.com/gitlab-org/gitlab-ce/issues/51502',
                extra: { job_id: job.id } ).once

        expect(Rails.logger)
          .to receive(:error)
          .with("Failed to archive trace. id: #{job.id} message: Unexpected error")
          .and_call_original

        expect(Gitlab::Metrics)
          .to receive(:counter)
          .with(:job_trace_archive_failed_total, "Counter of failed attempts of trace archiving")
          .and_call_original

        expect { subject }.not_to raise_error
      end
    end
  end
end
