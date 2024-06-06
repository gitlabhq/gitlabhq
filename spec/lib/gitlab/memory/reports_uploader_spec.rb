# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::ReportsUploader, :aggregate_failures do
  let(:gcs_key) { 'test_gcs_key' }
  let(:gcs_project) { 'test_gcs_project' }
  let(:gcs_bucket) { 'test_gcs_bucket' }
  let(:logger) { instance_double(Gitlab::Memory::DiagnosticReportsLogger) }

  let(:uploader) do
    described_class.new(gcs_key: gcs_key, gcs_project: gcs_project, gcs_bucket: gcs_bucket, logger: logger)
  end

  # rubocop: disable RSpec/VerifiedDoubles
  # `Fog::Storage::Google` does not implement `put_object` itself, so it is tricky to pinpoint particular method
  # with instance_double without revealing `Fog::Storage::Google` internals. For simplicity, we use a simple double.
  let(:fog) { double("Fog::Storage::Google") }
  # rubocop: enable RSpec/VerifiedDoubles

  let(:report) { Tempfile.new("report.1.worker_1.#{Time.current.to_i}.json") }

  after do
    FileUtils.remove_entry(report)
  end

  describe '#upload' do
    before do
      allow(Fog::Storage::Google)
        .to receive(:new)
        .with(google_project: gcs_project, google_json_key_location: gcs_key)
        .and_return(fog)
    end

    it 'calls fog, logs upload requested and success with duration' do
      expect(logger)
        .to receive(:info)
        .with(hash_including(:pid, message: "Diagnostic reports", perf_report_status: "upload requested",
          class: 'Gitlab::Memory::ReportsUploader', perf_report_path: report.path))
        .ordered

      expect(fog).to receive(:put_object).with(gcs_bucket, File.basename(report), instance_of(File))

      expect(logger)
        .to receive(:info)
        .with(hash_including(:pid, :duration_s,
          message: "Diagnostic reports", perf_report_status: "upload success",
          class: 'Gitlab::Memory::ReportsUploader', perf_report_path: report.path))
        .ordered

      uploader.upload(report.path)
    end

    context 'when Google API responds with an error' do
      let(:invalid_bucket) { 'WRONG BUCKET' }

      let(:uploader) do
        described_class.new(gcs_key: gcs_key, gcs_project: gcs_project, gcs_bucket: invalid_bucket, logger: logger)
      end

      it 'logs error raised by Fog and do not re-raise' do
        expect(logger)
          .to receive(:info)
          .with(hash_including(:pid, message: "Diagnostic reports", perf_report_status: "upload requested",
            class: 'Gitlab::Memory::ReportsUploader', perf_report_path: report.path))

        expect(fog).to receive(:put_object).with(invalid_bucket, File.basename(report), instance_of(File))
                   .and_raise(Google::Apis::ClientError.new("invalid: Invalid bucket name: #{invalid_bucket}"))

        expect(logger)
          .to receive(:error)
          .with(hash_including(:pid,
            message: "Diagnostic reports", class: 'Gitlab::Memory::ReportsUploader',
            perf_report_status: 'error', error: "invalid: Invalid bucket name: #{invalid_bucket}"))

        expect { uploader.upload(report.path) }.not_to raise_error
      end
    end
  end
end
