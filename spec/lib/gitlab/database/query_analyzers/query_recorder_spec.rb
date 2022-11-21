# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::QueryRecorder, query_analyzers: false do
  # We keep only the QueryRecorder analyzer running
  around do |example|
    described_class.with_suppressed(false) do
      example.run
    end
  end

  context 'when analyzer is enabled for tests' do
    let(:query) { 'SELECT 1 FROM projects' }
    let(:log_path) { Rails.root.join(described_class::LOG_PATH) }
    let(:log_file) { described_class.log_file }

    before do
      stub_env('CI', 'true')

      # This is needed to be able to stub_env the CI variable
      ::Gitlab::Database::QueryAnalyzer.instance.begin!([described_class])
    end

    after do
      ::Gitlab::Database::QueryAnalyzer.instance.end!([described_class])
    end

    it 'logs queries to a file' do
      allow(FileUtils).to receive(:mkdir_p)
        .with(log_path)
      expect(File).to receive(:write)
        .with(log_file, /^{"sql":"#{query}/, mode: 'a')
      expect(described_class).to receive(:analyze).with(/^#{query}/).and_call_original

      expect { ApplicationRecord.connection.execute(query) }.not_to raise_error
    end
  end

  describe '.log_file' do
    let(:folder) { 'query_recorder' }
    let(:extension) { 'ndjson' }
    let(:default_name) { 'rspec' }
    let(:job_name) { 'test-job-1' }

    subject { described_class.log_file.to_s }

    context 'when in CI' do
      before do
        stub_env('CI_JOB_NAME_SLUG', job_name)
      end

      it { is_expected.to include("#{folder}/#{job_name}.#{extension}") }
      it { is_expected.not_to include("#{folder}/#{default_name}.#{extension}") }
    end

    context 'when not in CI' do
      before do
        stub_env('CI_JOB_NAME_SLUG', nil)
      end

      it { is_expected.to include("#{folder}/#{default_name}.#{extension}") }
      it { is_expected.not_to include("#{folder}/#{job_name}.#{extension}") }
    end
  end
end
