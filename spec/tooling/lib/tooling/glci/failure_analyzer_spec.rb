# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/glci/failure_analyzer'
require_relative '../../../../../tooling/lib/tooling/glci/failure_categories/download_job_trace'
require_relative '../../../../../tooling/lib/tooling/glci/failure_categories/job_trace_to_failure_category'
require_relative '../../../../../tooling/lib/tooling/glci/failure_categories/report_job_failure'

RSpec.describe Tooling::Glci::FailureAnalyzer, feature_category: :tooling do
  let(:job_id)                { '12345' }
  let(:trace_path)            { 'path/to/trace.log' }
  let(:failure_category_hash) { { failure_category: 'test_failures', pattern: ".+a test pattern.+" } }

  let(:download_instance)    { instance_double(Tooling::Glci::FailureCategories::DownloadJobTrace) }
  let(:categorizer_instance) { instance_double(Tooling::Glci::FailureCategories::JobTraceToFailureCategory) }
  let(:reporter_instance)    { instance_double(Tooling::Glci::FailureCategories::ReportJobFailure) }

  subject(:analyzer) { described_class.new }

  before do
    stub_env('RSPEC_TEST_ALREADY_FAILED_ON_DEFAULT_BRANCH_MARKER_PATH', nil)

    # Stub File.exist? to avoid issues with nil paths
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(nil).and_return(false)

    allow(Tooling::Glci::FailureCategories::DownloadJobTrace).to receive(:new).and_return(download_instance)
    allow(Tooling::Glci::FailureCategories::JobTraceToFailureCategory).to receive(:new).and_return(categorizer_instance)
    allow(Tooling::Glci::FailureCategories::ReportJobFailure).to receive(:new).and_return(reporter_instance)

    allow(download_instance).to receive(:download).and_return(trace_path)
    allow(categorizer_instance).to receive(:process).with(trace_path).and_return(failure_category_hash)
    allow(reporter_instance).to receive(:report)
  end

  describe '#analyze_job' do
    context 'when no trace could be downloaded' do
      let(:trace_path) { nil }

      it 'displays an error message' do
        result = ""

        expect do
          result = analyzer.analyze_job(job_id)
        end.to output("[GCLI Failure Analyzer] Missing job trace. Exiting.\n").to_stderr

        expect(Tooling::Glci::FailureCategories::JobTraceToFailureCategory).not_to have_received(:new)
        expect(Tooling::Glci::FailureCategories::ReportJobFailure).not_to have_received(:new)

        expect(result).to eq({})
      end
    end

    context 'when no failure category could be found' do
      let(:failure_category_hash) { {} }

      it 'displays an error message' do
        result = ""

        expect do
          result = analyzer.analyze_job(job_id)
        end.to output("[GCLI Failure Analyzer] Missing failure category. Exiting.\n").to_stderr

        expect(Tooling::Glci::FailureCategories::ReportJobFailure).not_to have_received(:new)
        expect(result).to eq({})
      end
    end

    context 'when a known flaky test marker file exists' do
      let(:marker_path) { 'tmp/test_already_failed_marker.txt' }

      before do
        stub_env('RSPEC_TEST_ALREADY_FAILED_ON_DEFAULT_BRANCH_MARKER_PATH', marker_path)
        allow(File).to receive(:exist?).with(marker_path).and_return(true)
      end

      it 'skips downloading and analyzing the job trace' do
        result = analyzer.analyze_job(job_id)

        expect(download_instance).not_to have_received(:download)
        expect(categorizer_instance).not_to have_received(:process)

        expect(result).to eq({
          failure_category: 'test_already_failed_on_default_branch',
          pattern: 'N/A'
        })
      end

      it 'creates a ReportJobFailure instance with job_id and the flaky test failure category' do
        analyzer.analyze_job(job_id)

        expect(Tooling::Glci::FailureCategories::ReportJobFailure).to have_received(:new).with(
          job_id: job_id,
          failure_category: 'test_already_failed_on_default_branch'
        )
      end

      it 'still calls report on the ReportJobFailure instance' do
        analyzer.analyze_job(job_id)

        expect(reporter_instance).to have_received(:report)
      end
    end

    context 'when a flaky test marker path is set but the file does not exist' do
      let(:marker_path) { 'tmp/nonexistent_marker.txt' }

      before do
        stub_env('RSPEC_TEST_ALREADY_FAILED_ON_DEFAULT_BRANCH_MARKER_PATH', marker_path)
        allow(File).to receive(:exist?).with(marker_path).and_return(false)
      end

      it 'follows the normal failure analysis process' do
        analyzer.analyze_job(job_id)

        expect(download_instance).to have_received(:download)
        expect(categorizer_instance).to have_received(:process).with(trace_path)
        expect(reporter_instance).to have_received(:report)
      end
    end

    it 'creates a DownloadJobTrace instance' do
      analyzer.analyze_job(job_id)

      expect(Tooling::Glci::FailureCategories::DownloadJobTrace).to have_received(:new)
    end

    it 'calls download on the DownloadJobTrace instance' do
      analyzer.analyze_job(job_id)

      expect(download_instance).to have_received(:download)
    end

    it 'creates a JobTraceToFailureCategory instance' do
      analyzer.analyze_job(job_id)

      expect(Tooling::Glci::FailureCategories::JobTraceToFailureCategory).to have_received(:new)
    end

    it 'calls process on the JobTraceToFailureCategory instance with the trace path' do
      analyzer.analyze_job(job_id)

      expect(categorizer_instance).to have_received(:process).with(trace_path)
    end

    it 'creates a ReportJobFailure instance with job_id and failure_category' do
      analyzer.analyze_job(job_id)

      expect(Tooling::Glci::FailureCategories::ReportJobFailure).to have_received(:new).with(
        job_id: job_id,
        failure_category: failure_category_hash[:failure_category]
      )
    end

    it 'calls report on the ReportJobFailure instance' do
      analyzer.analyze_job(job_id)

      expect(reporter_instance).to have_received(:report)
    end

    it 'follows the correct sequence of operations' do
      analyzer.analyze_job(job_id)

      expect(download_instance).to have_received(:download).ordered
      expect(categorizer_instance).to have_received(:process).ordered
      expect(reporter_instance).to have_received(:report).ordered
    end

    it 'returns the failure category hash' do
      expect(analyzer.analyze_job(job_id)).to eq(failure_category_hash)
    end

    context 'when an error occurs in any component' do
      before do
        allow(download_instance).to receive(:download).and_raise(RuntimeError, 'Download failed')
      end

      it 'allows the error to propagate' do
        expect { analyzer.analyze_job(job_id) }.to raise_error(RuntimeError, 'Download failed')
      end
    end
  end
end
