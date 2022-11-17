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
    let(:log_path) { Rails.root.join(described_class::LOG_FILE) }

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
        .with(File.dirname(log_path))
      expect(File).to receive(:write)
        .with(log_path, /^{"sql":"#{query}/, mode: 'a')
      expect(described_class).to receive(:analyze).with(/^#{query}/).and_call_original

      expect { ApplicationRecord.connection.execute(query) }.not_to raise_error
    end
  end
end
