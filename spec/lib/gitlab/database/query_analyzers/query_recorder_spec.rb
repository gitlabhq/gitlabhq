# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::QueryRecorder, query_analyzers: false do
  # We keep only the QueryRecorder analyzer running
  around do |example|
    described_class.with_suppressed(false) do
      example.run
    end
  end

  context 'with query analyzer' do
    let(:query) { 'SELECT 1 FROM projects' }
    let(:log_path) { Rails.root.join(described_class::LOG_PATH) }
    let(:log_file) { described_class.log_file }

    after do
      ::Gitlab::Database::QueryAnalyzer.instance.end!([described_class])
    end

    shared_examples_for 'an enabled query recorder' do
      it 'logs queries to a file' do
        allow(FileUtils).to receive(:mkdir_p)
          .with(log_path)
        expect(File).to receive(:write)
          .with(log_file, /^{"sql":"#{query}/, mode: 'a')
        expect(described_class).to receive(:analyze).with(/^#{query}/).and_call_original

        expect { ApplicationRecord.connection.execute(query) }.not_to raise_error
      end
    end

    context 'on default branch' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        stub_env('CI_DEFAULT_BRANCH', 'default_branch_name')
        stub_env('CI_COMMIT_REF_NAME', 'default_branch_name')

        # This is needed to be able to stub_env the CI variable
        ::Gitlab::Database::QueryAnalyzer.instance.begin!([described_class])
      end

      it_behaves_like 'an enabled query recorder'
    end

    context 'on database merge requests' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'database')

        # This is needed to be able to stub_env the CI variable
        ::Gitlab::Database::QueryAnalyzer.instance.begin!([described_class])
      end

      it_behaves_like 'an enabled query recorder'
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
