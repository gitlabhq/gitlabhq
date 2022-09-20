# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::UploadAndCleanupReports, :aggregate_failures do
  describe '#initalize' do
    context 'when settings are passed through the environment' do
      before do
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_UPLOADER_SLEEP_S', '600')
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_PATH', '/path/to/reports')
      end

      it 'initializes with these settings' do
        upload_and_cleanup = described_class.new

        expect(upload_and_cleanup.sleep_time_seconds).to eq(600)
        expect(upload_and_cleanup.reports_path).to eq('/path/to/reports')
        expect(upload_and_cleanup.alive).to be true
      end
    end

    context 'when settings are passed through the initializer' do
      it 'initializes with these settings' do
        upload_and_cleanup = described_class.new(sleep_time_seconds: 600, reports_path: '/path/to/reports')

        expect(upload_and_cleanup.sleep_time_seconds).to eq(600)
        expect(upload_and_cleanup.reports_path).to eq('/path/to/reports')
        expect(upload_and_cleanup.alive).to be true
      end
    end

    context 'when `sleep_time_seconds` is not passed' do
      it 'initialized with the default' do
        upload_and_cleanup = described_class.new(reports_path: '/path/to/reports')

        expect(upload_and_cleanup.sleep_time_seconds).to eq(described_class::DEFAULT_SLEEP_TIME_SECONDS)
        expect(upload_and_cleanup.alive).to be true
      end
    end

    shared_examples 'checks reports_path presence' do
      it 'logs error and does not set `alive`' do
        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including(
                  :pid, :worker_id,
                  message: "Diagnostic reports",
                  class: 'Gitlab::Memory::UploadAndCleanupReports',
                  perf_report_status: 'path is not configured'))

        upload_and_cleanup = described_class.new(sleep_time_seconds: 600, reports_path: path)

        expect(upload_and_cleanup.alive).to be_falsey
      end
    end

    context 'when `reports_path` is nil' do
      let(:path) { nil }

      it_behaves_like 'checks reports_path presence'
    end

    context 'when `reports_path` is blank' do
      let(:path) { '' }

      it_behaves_like 'checks reports_path presence'
    end
  end

  describe '#call' do
    let(:upload_and_cleanup) do
      described_class.new(sleep_time_seconds: 600, reports_path: dir).tap do |instance|
        allow(instance).to receive(:sleep).and_return(nil)
        allow(instance).to receive(:alive).and_return(true, false)
      end
    end

    let_it_be(:dir) { Dir.mktmpdir }

    after(:all) do
      FileUtils.remove_entry(dir)
    end

    context 'when `gitlab_diagnostic_reports_uploader` ops FF is enabled' do
      let_it_be(:reports_count) { 3 }

      let_it_be(:reports) do
        (1..reports_count).map do |i|
          Tempfile.new("report.1.worker_#{i}.#{Time.current.to_i}.json", dir)
        end
      end

      let_it_be(:unfinished_report) do
        unfinished_reports_dir = File.join(dir, 'tmp')
        FileUtils.mkdir_p(unfinished_reports_dir)
        Tempfile.new("report.10.worker_0.#{Time.current.to_i}.json", unfinished_reports_dir)
      end

      let_it_be(:failed_to_upload_report) do
        Tempfile.new("report.100.worker_0.#{Time.current.to_i}.json", dir)
      end

      it 'invokes the uploader and cleans only successfully uploaded files' do
        expect(Gitlab::AppLogger)
          .to receive(:info)
          .with(hash_including(:pid, :worker_id,
                               message: "Diagnostic reports",
                               class: 'Gitlab::Memory::UploadAndCleanupReports',
                               perf_report_status: 'started'))

        reports.each do |report|
          expect(upload_and_cleanup.uploader).to receive(:upload).with(report.path).and_return(true)
        end

        expect(upload_and_cleanup.uploader).not_to receive(:upload).with(unfinished_report.path)

        expect(upload_and_cleanup.uploader).to receive(:upload).with(failed_to_upload_report.path).and_return(false)

        expect { upload_and_cleanup.call }
          .to change { Dir.entries(dir).count { |e| e.match(/report.*/) } }
          .from(reports_count + 1).to(1)
      end

      context 'when there is an exception' do
        it 'logs it and does not crash the loop' do
          expect(upload_and_cleanup.uploader)
            .to receive(:upload)
            .at_least(:once)
            .and_raise(StandardError, 'Error Message')

          expect(Gitlab::ErrorTracking)
            .to receive(:log_exception)
            .with(an_instance_of(StandardError),
                  hash_including(:pid, :worker_id, message: "Diagnostic reports",
                                                   class: 'Gitlab::Memory::UploadAndCleanupReports'))
            .at_least(:once)

          expect { upload_and_cleanup.call }.not_to raise_error
        end
      end
    end

    context 'when `gitlab_diagnostic_reports_uploader` ops FF is disabled' do
      let(:dir) { Dir.mktmpdir }

      before do
        stub_feature_flags(gitlab_diagnostic_reports_uploader: false)
        Tempfile.new("report.1.worker_1.#{Time.current.to_i}.json", dir)
      end

      after do
        FileUtils.remove_entry(dir)
      end

      it 'does not upload and remove any files' do
        expect(upload_and_cleanup.uploader).not_to receive(:upload)

        expect { upload_and_cleanup.call }.not_to change { Dir.entries(dir).count }
      end
    end
  end
end
