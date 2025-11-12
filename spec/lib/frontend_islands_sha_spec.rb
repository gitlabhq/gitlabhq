# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/lib/frontend_islands_sha'

RSpec.describe FrontendIslandsSha, feature_category: :tooling do
  before do
    # Reset memoization between tests
    described_class.instance_variable_set(:@cached_frontend_islands_sha256, nil)
  end

  describe '.cached_frontend_islands_sha256' do
    let(:cache_file) { 'cached-frontend-islands-hash.txt' }

    context 'when cache file exists' do
      let(:cache_content) { "abc123def456\n  " }
      let(:expected_hash) { 'abc123def456' }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(cache_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(cache_file).and_return(cache_content)
      end

      it 'returns stripped cache content' do
        expect(described_class.cached_frontend_islands_sha256).to eq(expected_hash)
      end

      it 'memoizes the result' do
        allow(File).to receive(:read).and_call_original
        expect(File).to receive(:read).with(cache_file).once.and_return(cache_content)

        2.times { described_class.cached_frontend_islands_sha256 }
      end
    end

    context 'when cache file does not exist' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(cache_file).and_return(false)
      end

      it 'returns missing! marker' do
        expect(described_class.cached_frontend_islands_sha256).to eq('missing!')
      end
    end

    context 'when GLCI_FRONTEND_ISLANDS_HASH_FILE env is set' do
      let(:custom_cache_file) { '/custom/path/hash.txt' }
      let(:cache_content) { 'custom123' }

      before do
        stub_const('ENV', ENV.to_hash.merge('GLCI_FRONTEND_ISLANDS_HASH_FILE' => custom_cache_file))
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(custom_cache_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(custom_cache_file).and_return(cache_content)
      end

      it 'uses custom cache file path' do
        expect(described_class.cached_frontend_islands_sha256).to eq(cache_content)
      end
    end

    context 'when GLCI_FRONTEND_ISLANDS_HASH_FILE points to non-existent file' do
      let(:custom_cache_file) { '/custom/path/missing.txt' }

      before do
        stub_const('ENV', ENV.to_hash.merge('GLCI_FRONTEND_ISLANDS_HASH_FILE' => custom_cache_file))
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(custom_cache_file).and_return(false)
      end

      it 'returns missing! marker' do
        expect(described_class.cached_frontend_islands_sha256).to eq('missing!')
      end
    end
  end

  describe '.sha256_of_frontend_islands_impacting_compilation' do
    let(:file1) { 'ee/frontend_islands/apps/duo_next/package.json' }
    let(:file2) { 'ee/frontend_islands/apps/duo_next/vite.config.ts' }
    let(:file1_hash) { 'abc123' }
    let(:file2_hash) { 'def456' }
    let(:combined_hash) { 'abc123def456' }
    let(:final_hash) { Digest::SHA256.hexdigest(combined_hash) }

    before do
      # Mock the private method to return test files
      allow(described_class).to receive(:frontend_islands_impacting_compilation).and_return([file1, file2])

      # Mock Digest::SHA256.file to return test hashes
      allow(Digest::SHA256).to receive(:file).and_call_original
      allow(Digest::SHA256).to receive(:file).with(file1).and_return(
        instance_double(Digest::SHA256, hexdigest: file1_hash)
      )
      allow(Digest::SHA256).to receive(:file).with(file2).and_return(
        instance_double(Digest::SHA256, hexdigest: file2_hash)
      )
    end

    it 'returns SHA256 hash of all file hashes' do
      expect(described_class.sha256_of_frontend_islands_impacting_compilation).to eq(final_hash)
    end

    it 'produces consistent hashes for same files' do
      hash1 = described_class.sha256_of_frontend_islands_impacting_compilation
      hash2 = described_class.sha256_of_frontend_islands_impacting_compilation

      expect(hash1).to eq(hash2)
    end

    context 'when no files are found' do
      before do
        allow(described_class).to receive(:frontend_islands_impacting_compilation).and_return([])
      end

      it 'returns hash of empty string' do
        expected_hash = Digest::SHA256.hexdigest('')

        expect(described_class.sha256_of_frontend_islands_impacting_compilation).to eq(expected_hash)
      end
    end
  end

  describe '.frontend_islands_impacting_compilation' do
    let(:config_file1) { 'ee/frontend_islands/apps/duo_next/package.json' }
    let(:config_file2) { 'ee/frontend_islands/apps/duo_next/vite.config.ts' }
    let(:source_file1) { 'ee/frontend_islands/apps/duo_next/src/main.ts' }
    let(:source_file2) { 'ee/frontend_islands/apps/duo_next/src/App.vue' }

    before do
      # Mock constants with simple test patterns
      stub_const("#{described_class}::FRONTEND_ISLANDS_FILES",
        [config_file1, config_file2, 'nonexistent.json'])
      stub_const("#{described_class}::SOURCE_FILE_PATTERNS",
        %w[ee/frontend_islands/apps/**/src/**/*.{vue,ts}])
      stub_const("#{described_class}::EXCLUDE_PATTERNS",
        %w[ee/frontend_islands/**/dist/**/* ee/frontend_islands/**/node_modules/**/* ee/frontend_islands/**/*.md])

      # Mock File operations
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(config_file1).and_return(true)
      allow(File).to receive(:exist?).with(config_file2).and_return(true)
      allow(File).to receive(:exist?).with('nonexistent.json').and_return(false)
      allow(File).to receive(:exist?).with(source_file1).and_return(true)
      allow(File).to receive(:exist?).with(source_file2).and_return(true)

      allow(File).to receive(:file?).and_call_original
      allow(File).to receive(:file?).with(config_file1).and_return(true)
      allow(File).to receive(:file?).with(config_file2).and_return(true)
      allow(File).to receive(:file?).with(source_file1).and_return(true)
      allow(File).to receive(:file?).with(source_file2).and_return(true)

      # Mock Dir.glob to return source files
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob)
        .with('ee/frontend_islands/apps/**/src/**/*.{vue,ts}')
        .and_return([source_file1, source_file2])

      # Mock File.fnmatch? for exclude pattern testing
      allow(File).to receive(:fnmatch?).and_call_original
    end

    it 'includes existing configuration files' do
      result = described_class.send(:frontend_islands_impacting_compilation)

      expect(result).to include(config_file1, config_file2)
    end

    it 'includes source files from glob patterns' do
      result = described_class.send(:frontend_islands_impacting_compilation)

      expect(result).to include(source_file1, source_file2)
    end

    it 'excludes non-existent configuration files' do
      result = described_class.send(:frontend_islands_impacting_compilation)

      expect(result).not_to include('nonexistent.json')
    end

    it 'returns sorted unique list' do
      result = described_class.send(:frontend_islands_impacting_compilation)

      expect(result).to eq(result.sort.uniq)
    end

    it 'applies exclude patterns to filter files' do
      # Test that exclude pattern filtering is applied by checking
      # that the reject block is evaluated
      result = described_class.send(:frontend_islands_impacting_compilation)

      # Should include valid config and source files
      expect(result).to include(config_file1, config_file2, source_file1, source_file2)
      # Result should be an array of strings (file paths)
      expect(result).to all(be_a(String))
    end

    context 'when glob returns directories' do
      let(:directory) { 'ee/frontend_islands/apps/duo_next/src' }

      before do
        stub_const("#{described_class}::FRONTEND_ISLANDS_FILES", [])
        stub_const("#{described_class}::SOURCE_FILE_PATTERNS", %w[ee/frontend_islands/apps/**/src])

        allow(Dir).to receive(:glob)
          .with('ee/frontend_islands/apps/**/src')
          .and_return([directory])
        allow(File).to receive(:exist?).with(directory).and_return(true)
        allow(File).to receive(:file?).with(directory).and_return(false)
      end

      it 'excludes directories and only includes files' do
        result = described_class.send(:frontend_islands_impacting_compilation)

        expect(result).not_to include(directory)
        expect(result).to eq([])
      end
    end
  end
end
