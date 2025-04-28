# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../scripts/sql_fingerprint_extractor'

RSpec.describe SQLFingerprintExtractor, feature_category: :tooling do
  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
  let(:extractor) { described_class.new(logger) }

  describe '#initialize' do
    it 'uses the provided logger' do
      expect(extractor.logger).to eq(logger)
    end

    it 'creates a default logger if none provided' do
      allow(Logger).to receive(:new).with($stdout).and_call_original
      expect(described_class.new.logger).to be_a(Logger)
    end
  end

  describe '#extract_queries_from_file' do
    context 'with a regular text file' do
      let(:file_path) { 'test_queries.ndjson' }
      let(:valid_line) { '{"fingerprint":"def123","normalized":"SELECT * FROM accounts"}' }
      let(:second_valid_line) { '{"fingerprint":"abc123","normalized":"SELECT * FROM users"}' }
      let(:invalid_line) { 'invalid json' }
      let(:no_fingerprint) { '{"normalized":"SELECT * FROM users"}' }

      before do
        allow(File).to receive(:foreach)
          .with(file_path)
          .and_yield(valid_line)
          .and_yield(invalid_line)
          .and_yield(no_fingerprint)
          .and_yield(second_valid_line)
      end

      it 'extracts valid queries with fingerprints' do
        queries = extractor.extract_queries_from_file(file_path)
        expect(queries.size).to eq(2)
        expect(queries.first['fingerprint']).to eq('def123')
        expect(queries.first['normalized']).to eq('SELECT * FROM accounts')
        expect(queries.second['fingerprint']).to eq('abc123')
        expect(queries.second['normalized']).to eq('SELECT * FROM users')
      end

      it 'logs the extraction process' do
        expect(logger).to receive(:info).with("Extracting queries from file: #{file_path}")
        expect(logger).to receive(:info).with(/Extracted \d+ queries from file:/)
        extractor.extract_queries_from_file(file_path)
      end
    end

    context 'with a gzipped file' do
      let(:gz_file_path) { 'test_queries.ndjson.gz' }
      let(:gz_reader) { instance_double(Zlib::GzipReader) }
      let(:valid_line) { '{"fingerprint":"def456","normalized":"SELECT * FROM posts"}' }

      before do
        allow(Zlib::GzipReader).to receive(:open).with(gz_file_path).and_yield(gz_reader)
        allow(gz_reader).to receive(:each_line).and_yield(valid_line)
      end

      it 'extracts queries from a gzipped file' do
        queries = extractor.extract_queries_from_file(gz_file_path)
        expect(queries.size).to eq(1)
        expect(queries.first['fingerprint']).to eq('def456')
      end
    end

    context 'when an error occurs' do
      let(:file_path) { 'nonexistent_file.ndjson' }

      before do
        allow(File).to receive(:foreach).with(file_path).and_raise(StandardError.new('File read error'))
      end

      it 'logs the error and returns an empty array' do
        expect(logger).to receive(:warn).with("Warning: Error reading file: File read error")
        queries = extractor.extract_queries_from_file(file_path)
        expect(queries).to be_empty
      end
    end
  end

  describe '#extract_fingerprints_from_file' do
    let(:file_path) { 'test_queries.ndjson' }
    let(:queries) { [{ 'fingerprint' => 'abc123' }, { 'fingerprint' => 'def456' }, {}] }

    before do
      allow(extractor).to receive(:extract_queries_from_file).with(file_path).and_return(queries)
    end

    it 'extracts only the fingerprints as a Set' do
      fingerprints = extractor.extract_fingerprints_from_file(file_path)
      expect(fingerprints).to be_a(Set)
      expect(fingerprints.size).to eq(2)
      expect(fingerprints).to include('abc123', 'def456')
    end
  end

  describe '#extract_from_tar_gz' do
    let(:tar_gz_content) { 'mock_tar_gz_content' }
    let(:string_io) { instance_double(StringIO) }
    let(:gzip_reader) { instance_double(Zlib::GzipReader) }
    let(:tar_reader) { instance_double(Gem::Package::TarReader) }
    let(:entry) { instance_double(Gem::Package::TarReader::Entry, file?: true, directory?: false) }
    let(:entry_header) { instance_double(Gem::Package::TarHeader, size: 1000) }
    let(:entry_content) { "fingerprint1\nfingerprint2\n" }

    before do
      allow(StringIO).to receive(:new).with(tar_gz_content).and_return(string_io)
      allow(Zlib::GzipReader).to receive(:new).with(string_io).and_return(gzip_reader)
      allow(Gem::Package::TarReader).to receive(:new).with(gzip_reader).and_return(tar_reader)
      allow(tar_reader).to receive(:each).and_yield(entry)
      allow(entry).to receive_messages(header: entry_header, read: entry_content)
    end

    it 'extracts fingerprints from tar.gz content' do
      fingerprints = extractor.extract_from_tar_gz(tar_gz_content)
      expect(fingerprints).to be_a(Set)
      expect(fingerprints.size).to eq(2)
      expect(fingerprints).to include('fingerprint1', 'fingerprint2')
    end

    context 'when file is too large' do
      let(:max_size_mb) { 0.001 } # 1KB max
      let(:entry_header) { instance_double(Gem::Package::TarHeader, size: 2000) } # 2KB file size

      it 'logs the error and returns empty set' do
        expect(logger).to receive(:error).with(/File too large:/)
        fingerprints = extractor.extract_from_tar_gz(tar_gz_content, max_size_mb)
        expect(fingerprints).to be_a(Set)
        expect(fingerprints).to be_empty
      end
    end

    context 'when an error occurs' do
      before do
        allow(StringIO).to receive(:new).with(tar_gz_content).and_raise(StandardError.new('Tar.gz processing error'))
      end

      it 'logs the error and returns empty set' do
        expect(logger).to receive(:error).with("Error processing tar.gz: Tar.gz processing error")
        fingerprints = extractor.extract_from_tar_gz(tar_gz_content)
        expect(fingerprints).to be_a(Set)
        expect(fingerprints).to be_empty
      end
    end
  end

  describe '#write_fingerprints_to_file' do
    let(:fingerprints) { Set.new(%w[abc123 def456]) }
    let(:output_file) { 'output_fingerprints.txt' }
    let(:file) { instance_double(File) }

    before do
      allow(File).to receive(:open).with(output_file, 'w').and_yield(file)
      allow(file).to receive(:puts)
    end

    it 'writes each fingerprint to the file' do
      expect(file).to receive(:puts).with('abc123')
      expect(file).to receive(:puts).with('def456')
      extractor.write_fingerprints_to_file(fingerprints, output_file)
    end

    it 'logs the number of fingerprints written' do
      expect(logger).to receive(:info).with("Wrote 2 fingerprints to output_fingerprints.txt")
      extractor.write_fingerprints_to_file(fingerprints, output_file)
    end
  end

  describe '#process_json_line' do
    let(:queries) { [] }

    it 'adds valid queries with fingerprints' do
      extractor.send(:process_json_line, '{"fingerprint":"abc123"}', queries)
      expect(queries.size).to eq(1)
      expect(queries.first['fingerprint']).to eq('abc123')
    end

    it 'skips lines without fingerprints' do
      extractor.send(:process_json_line, '{"other":"value"}', queries)
      expect(queries).to be_empty
    end

    it 'handles JSON parse errors' do
      extractor.send(:process_json_line, 'invalid json', queries)
      expect(queries).to be_empty
    end
  end
end
